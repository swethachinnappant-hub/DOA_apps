using System.Text.Json;
using BuildingBlocks.Data;
using BuildingBlocks.Security;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Errors;
using BuildingBlocks.Security;
using BuildingBlocks.Storage;
using Catalog.Contracts;
using Catalog.Data;
using Catalog.Data.Entities;
using Identity.Contracts;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Endpoints;

public sealed class ProductListRequest
{
    public string? Category { get; init; }
    public string? Metal { get; init; }
    public string? Occasion { get; init; }
    public string? Family { get; init; }
    public string? Style { get; init; }
    public string? Audience { get; init; }
    public string? Purity { get; init; }
    public string? Collection { get; init; }
    public bool? Verified { get; init; }
    public bool? InStock { get; init; }
    public long? MinPrice { get; init; }
    public long? MaxPrice { get; init; }
    public string? Badges { get; init; }
    public string? Q { get; init; }
    public string Sort { get; init; } = "featured";
    public string? Cursor { get; init; }
    public int Limit { get; init; } = 24;
}

/// <summary>Public catalogue read API: tenant-scoped filtering, stable keyset pages and batched media/seller lookups.</summary>
public sealed class CatalogReadService(
    CatalogDbContext catalog,
    PlatformDbContext platform,
    ITenantContext tenant,
    ISellerDirectory sellers,
    IObjectStorage storage,
    TimeProvider clock)
{
    private sealed record CursorData(string Sort, long Primary, int Secondary, DateTime? CreatedAt, Guid Id);

    public async Task<ProductPageDto> ListAsync(ProductListRequest request, CancellationToken ct)
    {
        var sort = NormalizeSort(request.Sort);
        var limit = Math.Clamp(request.Limit, 1, 60);
        var cursor = DecodeCursor(request.Cursor, sort);
        var query = catalog.Products.AsNoTracking()
            .Where(p => p.Status == "active" && p.DeletedAt == null)
            .Include(p => p.Brand)
            .Include(p => p.Category)
            .Include(p => p.Stock)
            .Include(p => p.Images)
            .Include(p => p.Variants)
            .Include(p => p.WholesalePriceTiers)
            .Include(p => p.Specs)
            .AsSplitQuery()
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            var category = request.Category.Trim();
            query = Guid.TryParse(category, out var categoryId)
                ? query.Where(p => p.CategoryId == categoryId)
                : query.Where(p => p.Category!.Slug == category || p.Category.Name.ToLower() == category.ToLower());
        }
        if (!string.IsNullOrWhiteSpace(request.Metal)) query = query.Where(p => p.Metal == request.Metal);
        if (!string.IsNullOrWhiteSpace(request.Occasion)) query = query.Where(p => p.Occasions.Contains(request.Occasion));
        if (!string.IsNullOrWhiteSpace(request.Family)) query = query.Where(p => p.Family == request.Family);
        if (!string.IsNullOrWhiteSpace(request.Style)) query = query.Where(p => p.Style == request.Style);
        if (!string.IsNullOrWhiteSpace(request.Audience)) query = query.Where(p => p.Audience == request.Audience);
        if (!string.IsNullOrWhiteSpace(request.Purity)) query = query.Where(p => p.Purity == request.Purity);
        if (!string.IsNullOrWhiteSpace(request.Collection))
        {
            var slug = request.Collection.Trim();
            query = query.Where(p => catalog.CollectionProducts.Any(cp =>
                cp.ProductId == p.Id && cp.Collection != null && cp.Collection.Visible && cp.Collection.Slug == slug));
        }
        if (request.MinPrice is < 0 || request.MaxPrice is < 0)
            throw DomainException.Validation("price", "Price filters cannot be negative.");
        if (request.MinPrice is { } minPrice)
        {
            if (minPrice > long.MaxValue / 100) throw DomainException.Validation("minPrice", "Minimum price is too large.");
            query = query.Where(p => p.PriceMinor >= minPrice * 100);
        }
        if (request.MaxPrice is { } maxPrice)
        {
            if (maxPrice > long.MaxValue / 100) throw DomainException.Validation("maxPrice", "Maximum price is too large.");
            query = query.Where(p => p.PriceMinor <= maxPrice * 100);
        }
        if (request.MinPrice is { } lower && request.MaxPrice is { } upper && lower > upper)
            throw DomainException.Validation("price", "minPrice must not exceed maxPrice.");
        if (request.InStock == true)
            query = query.Where(p => p.Stock != null && (!p.Stock.TrackInventory || p.Stock.OnHand - p.Stock.Reserved >= p.MinimumOrderQuantity));
        else if (request.InStock == false)
            query = query.Where(p => p.Stock == null || (p.Stock.TrackInventory && p.Stock.OnHand - p.Stock.Reserved < p.MinimumOrderQuantity));
        if (!string.IsNullOrWhiteSpace(request.Q))
        {
            var term = request.Q.Trim();
            if (term.Length > 120) throw DomainException.Validation("q", "Search text must be at most 120 characters.");
            var pattern = $"%{term}%";
            query = query.Where(p => EF.Functions.ILike(p.Name, pattern) ||
                                     EF.Functions.ILike(p.Sku, pattern) ||
                                     EF.Functions.ILike(p.SearchText, pattern) ||
                                     EF.Functions.ILike(p.Brand!.Name, pattern));
        }

        var requestedBadges = (request.Badges ?? "").Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => x.ToLowerInvariant()).Distinct().ToArray();
        var validBadges = new HashSet<string>(["new", "deal", "verified"], StringComparer.Ordinal);
        var invalidBadge = requestedBadges.FirstOrDefault(x => !validBadges.Contains(x));
        if (invalidBadge is not null) throw DomainException.Validation("badges", $"Unsupported badge '{invalidBadge}'.");
        if (requestedBadges.Contains("new")) query = query.Where(p => p.CreatedAt >= clock.GetUtcNow().UtcDateTime.AddDays(-14));
        if (requestedBadges.Contains("deal")) query = query.Where(p => p.MrpMinor > p.PriceMinor);
        if (request.Verified == true || requestedBadges.Contains("verified"))
        {
            var verifiedIds = await sellers.GetVerifiedSellerIdsAsync(ct);
            query = query.Where(p => verifiedIds.Contains(p.SellerId));
        }

        List<Product> products;
        CursorData? next;
        if (sort is "featured" or "bestsellers")
        {
            var cutoff = DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime).AddDays(-30);
            var sales = catalog.ProductDailyStats.AsNoTracking()
                .Where(s => s.Day >= cutoff)
                .GroupBy(s => s.ProductId)
                .Select(g => new { ProductId = g.Key, Units = g.Sum(s => s.UnitsSold) });
            var ranked = from product in query
                         join stat in sales on product.Id equals stat.ProductId into statGroup
                         from stat in statGroup.DefaultIfEmpty()
                         select new { Product = product, Units = stat == null ? 0 : stat.Units };
            if (cursor is not null)
            {
                var time = cursor.CreatedAt!.Value;
                ranked = ranked.Where(x => x.Units < cursor.Primary ||
                    (x.Units == cursor.Primary && x.Product.CreatedAt < time) ||
                    (x.Units == cursor.Primary && x.Product.CreatedAt == time && x.Product.Id.CompareTo(cursor.Id) < 0));
            }
            var rows = await ranked.OrderByDescending(x => x.Units)
                .ThenByDescending(x => x.Product.CreatedAt).ThenByDescending(x => x.Product.Id)
                .Take(limit + 1).ToListAsync(ct);
            products = rows.Take(limit).Select(x => x.Product).ToList();
            next = rows.Count > limit
                ? new CursorData(sort, rows[limit - 1].Units, 0, rows[limit - 1].Product.CreatedAt, rows[limit - 1].Product.Id)
                : null;
        }
        else
        {
            if (cursor is not null)
                query = ApplyCursor(query, sort, cursor);
            query = sort switch
            {
                "newest" => query.OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id),
                "price-asc" => query.OrderBy(p => p.PriceMinor).ThenBy(p => p.Id),
                "price-desc" => query.OrderByDescending(p => p.PriceMinor).ThenByDescending(p => p.Id),
                "discount" => query.OrderByDescending(p => p.DiscountBps).ThenByDescending(p => p.Id),
                "rating" => query.OrderByDescending(p => p.RatingSum).ThenByDescending(p => p.ReviewCount).ThenByDescending(p => p.Id),
                _ => throw DomainException.Validation("sort", "Unsupported product sort."),
            };
            var rows = await query.Take(limit + 1).ToListAsync(ct);
            products = rows.Take(limit).ToList();
            next = rows.Count > limit ? MakeCursor(sort, rows[limit - 1]) : null;
        }

        var dto = await MapProductsAsync(products, ct);
        return new ProductPageDto(dto, next is null ? null : EncodeCursor(next));
    }

    public async Task<ProductDto> GetByIdAsync(Guid id, CancellationToken ct)
    {
        var product = await ProductDetailsQuery().FirstOrDefaultAsync(p => p.Id == id, ct)
            ?? throw DomainException.NotFound("Product", id);
        return (await MapProductsAsync([product], ct))[0];
    }

    public async Task<ProductDto> GetBySlugAsync(string slug, CancellationToken ct)
    {
        var product = await ProductDetailsQuery().FirstOrDefaultAsync(p => p.Slug == slug, ct)
            ?? throw DomainException.NotFound("Product", slug);
        return (await MapProductsAsync([product], ct))[0];
    }

    public async Task<IReadOnlyList<CategoryDto>> CategoriesAsync(CancellationToken ct)
    {
        var categories = await catalog.Categories.AsNoTracking().Where(c => c.IsVisible)
            .OrderBy(c => c.DisplayOrder).ThenBy(c => c.Name)
            .Select(c => new { c.Id, c.Name, c.Slug, c.IconEmoji, c.DisplayOrder })
            .ToListAsync(ct);
        var leadImages = await catalog.Products.AsNoTracking()
            .Where(p => p.Status == "active" && p.DeletedAt == null)
            .SelectMany(p => p.Images.OrderBy(i => i.Position).Take(1)
                .Select(i => new { p.CategoryId, i.MediaId }))
            .ToListAsync(ct);
        var imageIds = leadImages.Select(x => x.MediaId).Distinct().ToArray();
        var urls = await GetMediaUrlsAsync(imageIds, ct);
        return categories.Select(c =>
        {
            var mediaId = leadImages.FirstOrDefault(x => x.CategoryId == c.Id)?.MediaId;
            return new CategoryDto(c.Id, c.Name, c.Slug, c.IconEmoji, c.DisplayOrder,
                mediaId is { } id && urls.TryGetValue(id, out var url) ? url : null);
        }).ToArray();
    }

    public async Task<IReadOnlyList<CollectionDto>> CollectionsAsync(CancellationToken ct)
    {
        var collections = await catalog.Collections.AsNoTracking().Where(c => c.Visible)
            .OrderBy(c => c.Position).ThenBy(c => c.Name)
            .Select(c => new { c.Id, c.Name, c.Slug, c.Route, c.Position, c.ImageMediaId })
            .ToListAsync(ct);
        var urls = await GetMediaUrlsAsync(collections.Where(c => c.ImageMediaId.HasValue)
            .Select(c => c.ImageMediaId!.Value).Distinct().ToArray(), ct);
        return collections.Select(c => new CollectionDto(c.Id, c.Name, c.Slug, c.Route, c.Position,
            c.ImageMediaId is { } id && urls.TryGetValue(id, out var url) ? url : null)).ToArray();
    }

    public async Task<IReadOnlyList<ProductDto>> TrendingAsync(int limit, CancellationToken ct)
    {
        var cutoff = DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime).AddDays(-30);
        var ids = await catalog.ProductDailyStats.AsNoTracking().Where(s => s.Day >= cutoff)
            .GroupBy(s => s.ProductId).Select(g => new { Id = g.Key, Units = g.Sum(s => s.UnitsSold) })
            .OrderByDescending(x => x.Units).ThenBy(x => x.Id).Take(Math.Clamp(limit, 1, 60))
            .Select(x => x.Id).ToListAsync(ct);
        if (ids.Count == 0) return [];
        var products = await ProductDetailsQuery().Where(p => ids.Contains(p.Id)).ToListAsync(ct);
        var byId = products.ToDictionary(p => p.Id);
        return await MapProductsAsync(ids.Where(byId.ContainsKey).Select(id => byId[id]).ToList(), ct);
    }

    public async Task<IReadOnlyList<object>> GoldRatesAsync(CancellationToken ct)
    {
        var rates = await catalog.GoldRates.AsNoTracking()
            .GroupBy(r => new { r.Metal, r.Karat })
            .Select(g => g.OrderByDescending(r => r.EffectiveAt).First())
            .OrderBy(r => r.Metal).ThenBy(r => r.Karat)
            .Select(r => new { r.Metal, r.Karat, RatePerGram = WholeRupees(r.RatePerGramMinor), r.EffectiveAt })
            .ToListAsync(ct);
        return rates.Cast<object>().ToArray();
    }

    private IQueryable<Product> ProductDetailsQuery() => catalog.Products.AsNoTracking()
        .Where(p => p.Status == "active" && p.DeletedAt == null)
        .Include(p => p.Brand).Include(p => p.Category).Include(p => p.Stock)
        .Include(p => p.Images).Include(p => p.Variants)
        .Include(p => p.WholesalePriceTiers).Include(p => p.Specs).AsSplitQuery();

    private async Task<IReadOnlyList<ProductDto>> MapProductsAsync(IReadOnlyList<Product> products, CancellationToken ct)
    {
        if (products.Count == 0) return [];
        var mediaIds = products.SelectMany(p => p.Images).Select(i => i.MediaId).Distinct().ToArray();
        var mediaUrls = await GetMediaUrlsAsync(mediaIds, ct);
        var sellerRows = await sellers.GetSellersByIdsAsync(products.Select(p => p.SellerId).Distinct().ToArray(), ct);
        var verified = sellerRows.Where(s => s.IsVerified && s.Status == "active").Select(s => s.Id).ToHashSet();
        var productIds = products.Select(p => p.Id).ToArray();
        var collectionLinks = await catalog.CollectionProducts.AsNoTracking()
            .Where(cp => productIds.Contains(cp.ProductId))
            .Select(cp => new { cp.ProductId, cp.CollectionId })
            .ToListAsync(ct);
        var collectionsByProduct = collectionLinks.GroupBy(x => x.ProductId)
            .ToDictionary(g => g.Key, g => (IReadOnlyList<string>)g.Select(x => x.CollectionId.ToString()).ToArray());
        var now = clock.GetUtcNow().UtcDateTime;
        return products.Select(p =>
        {
            var stock = p.Stock;
            var available = stock is { TrackInventory: true } ? stock.Available : 0;
            var inStock = stock is null || !stock.TrackInventory || available >= p.MinimumOrderQuantity;
            var badges = new List<string>();
            if (p.CreatedAt >= now.AddDays(-14)) badges.Add("new");
            if (p.MrpMinor > p.PriceMinor) badges.Add("deal");
            if (verified.Contains(p.SellerId)) badges.Add("verified");
            return new ProductDto(
                p.Id, p.Name, p.Brand?.Name ?? "", p.Category?.Name ?? "", p.Sku,
                WholeRupees(p.PriceMinor), WholeRupees(p.MrpMinor),
                p.ReviewCount == 0 ? 0 : (double)p.RatingSum / p.ReviewCount,
                p.ReviewCount,
                p.Images.OrderBy(i => i.Position)
                    .Where(i => mediaUrls.ContainsKey(i.MediaId))
                    .Select(i => mediaUrls[i.MediaId]).ToArray(),
                p.Variants.Where(v => v.Kind == "size").OrderBy(v => v.Position)
                    .Select(v => new ProductVariantDto(v.Kind, v.Name, v.SwatchHex)).ToArray(),
                p.Variants.Where(v => v.Kind == "shade").OrderBy(v => v.Position)
                    .Select(v => new ProductVariantDto(v.Kind, v.Name, v.SwatchHex)).ToArray(),
                p.WholesalePriceTiers.OrderBy(t => t.MinimumQuantity)
                    .Select(t => new WholesaleTierDto(t.MinimumQuantity, WholeRupees(t.UnitPriceMinor))).ToArray(),
                p.Specs.OrderBy(s => s.Position).ToDictionary(s => s.FieldKey, s => s.FieldValue),
                p.Description, p.MinimumOrderQuantity, p.DeliveryDays,
                p.SellerId.ToString(), available, inStock, (int)WholeRupees(p.PriceUsdMinor),
                p.Family, p.Style, p.Metal, p.Purity, p.Audience,
                p.Occasions, p.Highlights, badges,
                p.MrpMinor <= p.PriceMinor || p.MrpMinor == 0 ? 0 : (int)Math.Round((double)p.DiscountBps / 100, MidpointRounding.AwayFromZero),
                p.Slug, p.SeoTitle,
                collectionsByProduct.TryGetValue(p.Id, out var productCollections) ? productCollections : [],
                verified.Contains(p.SellerId), p.Xmin, p.CreatedAt);
        }).ToArray();
    }

    private async Task<Dictionary<Guid, string>> GetMediaUrlsAsync(IReadOnlyCollection<Guid> ids, CancellationToken ct)
    {
        if (ids.Count == 0) return [];
        var rows = await platform.MediaAssets.AsNoTracking()
            .Where(m => m.TenantId == tenant.TenantId && ids.Contains(m.Id) && !m.IsPrivate && m.Status == "ready")
            .Select(m => new { m.Id, m.StorageKey, m.Variants })
            .ToListAsync(ct);
        var result = new Dictionary<Guid, string>(rows.Count);
        foreach (var row in rows)
        {
            try
            {
                using var json = JsonDocument.Parse(row.Variants);
                if (json.RootElement.TryGetProperty("medium", out var medium) && medium.ValueKind == JsonValueKind.String)
                    result[row.Id] = medium.GetString()!;
                else
                    result[row.Id] = storage.GetPublicUrl(row.StorageKey);
            }
            catch (JsonException)
            {
                result[row.Id] = storage.GetPublicUrl(row.StorageKey);
            }
        }
        return result;
    }

    private static IQueryable<Product> ApplyCursor(IQueryable<Product> query, string sort, CursorData cursor) => sort switch
    {
        "newest" => query.Where(p => p.CreatedAt < cursor.CreatedAt || (p.CreatedAt == cursor.CreatedAt && p.Id.CompareTo(cursor.Id) < 0)),
        "price-asc" => query.Where(p => p.PriceMinor > cursor.Primary || (p.PriceMinor == cursor.Primary && p.Id.CompareTo(cursor.Id) > 0)),
        "price-desc" => query.Where(p => p.PriceMinor < cursor.Primary || (p.PriceMinor == cursor.Primary && p.Id.CompareTo(cursor.Id) < 0)),
        "discount" => query.Where(p => p.DiscountBps < cursor.Primary || (p.DiscountBps == cursor.Primary && p.Id.CompareTo(cursor.Id) < 0)),
        "rating" => query.Where(p => p.RatingSum < cursor.Primary ||
            (p.RatingSum == cursor.Primary && p.ReviewCount < cursor.Secondary) ||
            (p.RatingSum == cursor.Primary && p.ReviewCount == cursor.Secondary && p.Id.CompareTo(cursor.Id) < 0)),
        _ => throw DomainException.Validation("cursor", "This cursor cannot be used with the selected sort."),
    };

    private static CursorData MakeCursor(string sort, Product product) => sort switch
    {
        "newest" => new(sort, 0, 0, product.CreatedAt, product.Id),
        "price-asc" or "price-desc" => new(sort, product.PriceMinor, 0, null, product.Id),
        "discount" => new(sort, product.DiscountBps, 0, null, product.Id),
        "rating" => new(sort, product.RatingSum, product.ReviewCount, null, product.Id),
        _ => throw new InvalidOperationException("Ranked sorts create their cursor from the sales projection."),
    };

    private static string NormalizeSort(string? sort)
    {
        var value = string.IsNullOrWhiteSpace(sort) ? "featured" : sort.Trim().ToLowerInvariant();
        return value is "featured" or "newest" or "price-asc" or "price-desc" or "discount" or "rating" or "bestsellers"
            ? value
            : throw DomainException.Validation("sort", "Sort must be featured, newest, price-asc, price-desc, discount, rating, or bestsellers.");
    }

    private static CursorData? DecodeCursor(string? token, string sort)
    {
        if (string.IsNullOrWhiteSpace(token)) return null;
        try
        {
            var base64 = token.Replace('-', '+').Replace('_', '/');
            base64 = base64.PadRight(base64.Length + ((4 - base64.Length % 4) % 4), '=');
            var cursor = JsonSerializer.Deserialize<CursorData>(Convert.FromBase64String(base64));
            if (cursor is null || cursor.Sort != sort || cursor.Id == Guid.Empty ||
                ((sort is "newest" or "featured" or "bestsellers") && cursor.CreatedAt is null))
                throw new FormatException();
            return cursor;
        }
        catch (Exception ex) when (ex is FormatException or JsonException)
        {
            throw DomainException.Validation("cursor", "Cursor is invalid or does not match the selected sort.");
        }
    }

    private static string EncodeCursor(CursorData cursor)
    {
        var token = Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(cursor));
        return token.TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }

    private static long WholeRupees(long minor) => checked((long)Math.Round(minor / 100m, MidpointRounding.AwayFromZero));
}

public static class CatalogEndpoints
{
    public static IEndpointRouteBuilder MapCatalogEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var api = endpoints.MapGroup("/api/v1");
        api.MapGet("/products", ([AsParameters] ProductListRequest request, CatalogReadService service, CancellationToken ct) =>
            service.ListAsync(request, ct));
        api.MapGet("/products/{id:guid}", (Guid id, CatalogReadService service, CancellationToken ct) =>
            service.GetByIdAsync(id, ct));
        api.MapGet("/products/by-slug/{slug}", (string slug, CatalogReadService service, CancellationToken ct) =>
            service.GetBySlugAsync(slug, ct));
        api.MapGet("/products/{id:guid}/related", async (Guid id, CatalogDbContext db, CatalogReadService service, CancellationToken ct) =>
        {
            var category = await db.Products.AsNoTracking().Where(p => p.Id == id && p.Status == "active" && p.DeletedAt == null)
                .Select(p => p.Category!.Slug).FirstOrDefaultAsync(ct)
                ?? throw DomainException.NotFound("Product", id);
            var page = await service.ListAsync(new ProductListRequest { Category = category, Sort = "featured", Limit = 12 }, ct);
            return page.Products.Where(p => p.Id != id).Take(8).ToArray();
        });
        api.MapGet("/categories", (CatalogReadService service, CancellationToken ct) => service.CategoriesAsync(ct));
        api.MapGet("/collections", (CatalogReadService service, CancellationToken ct) => service.CollectionsAsync(ct));
        api.MapGet("/trending", (int? limit, CatalogReadService service, CancellationToken ct) =>
            service.TrendingAsync(limit ?? 20, ct));
        api.MapGet("/meta/gold-rates", (CatalogReadService service, CancellationToken ct) => service.GoldRatesAsync(ct));
        api.MapGet("/search", SearchAsync);
        api.MapGet("/search/suggest", SearchAsync);

        var owner = endpoints.MapGroup("/api/v1/owner").RequireAuthorization();
        owner.MapGet("/products", (int? limit, string? cursor, CatalogOwnerService service, CancellationToken ct) =>
            service.ListAsync(limit ?? 50, cursor, ct));
        owner.MapPost("/products", (OwnerProductUpsertRequest request, CatalogOwnerService service, CancellationToken ct) =>
            service.CreateAsync(request, ct));
        owner.MapPut("/products/{id:guid}", (Guid id, OwnerProductUpsertRequest request, CatalogOwnerService service, CancellationToken ct) =>
            service.UpdateAsync(id, request, ct));
        owner.MapDelete("/products/{id:guid}", async (Guid id, CatalogOwnerService service, CancellationToken ct) =>
        {
            await service.ArchiveAsync(id, ct);
            return Results.NoContent();
        });
        owner.MapPatch("/products/{id:guid}/stock", async (Guid id, StockDeltaRequest request, CatalogOwnerService service, CancellationToken ct) =>
        {
            await service.AdjustStockAsync(new StockAdjustmentRequest(id, request.Delta, request.Reason), ct);
            return Results.Ok(new { status = "adjusted" });
        });
        owner.MapPost("/inventory/adjust", async (StockAdjustmentRequest request, CatalogOwnerService service, CancellationToken ct) =>
        {
            await service.AdjustStockAsync(request, ct);
            return Results.Ok(new { status = "adjusted" });
        });
        return endpoints;
    }

    private static async Task<IResult> SearchAsync(
        string? q, CatalogReadService service, CatalogDbContext db, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(q))
            return Results.Ok(new SearchResponseDto([], [], []));
        var term = q.Trim();
        if (term.Length > 120) throw DomainException.Validation("q", "Search text must be at most 120 characters.");
        var products = await service.ListAsync(new ProductListRequest { Q = term, Sort = "featured", Limit = 8 }, ct);
        var pattern = $"%{term}%";
        var categories = await db.Categories.AsNoTracking().Where(c => c.IsVisible && EF.Functions.ILike(c.Name, pattern))
            .OrderBy(c => c.DisplayOrder).Take(6)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Slug, c.IconEmoji, c.DisplayOrder, null)).ToListAsync(ct);
        var suggestions = products.Products.Select(p => p.Name).Distinct(StringComparer.OrdinalIgnoreCase).Take(6).ToArray();
        return Results.Ok(new SearchResponseDto(products.Products, categories, suggestions));
    }
}
