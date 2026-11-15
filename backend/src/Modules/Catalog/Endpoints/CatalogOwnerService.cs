using System.Text.Json;
using BuildingBlocks.Audit;
using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Errors;
using BuildingBlocks.Outbox;
using BuildingBlocks.Security;
using Catalog.Contracts;
using Catalog.Data;
using Catalog.Data.Entities;
using Identity.Contracts;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Endpoints;

public sealed record OwnerProductUpsertRequest(
    Guid BrandId,
    Guid CategoryId,
    string Name,
    string Sku,
    string Description,
    long Price,
    long Mrp,
    int MinimumOrderQuantity,
    int InitialStock,
    int DeliveryDays,
    string Family,
    string Style,
    string Metal,
    string Purity,
    string Audience,
    string[] Occasions,
    string[] Highlights,
    Guid[] ImageMediaIds,
    OwnerVariantRequest[] Sizes,
    OwnerVariantRequest[] Shades,
    OwnerTierRequest[] WholesalePriceTiers,
    Dictionary<string, string> Specs,
    uint? Version);

public sealed record OwnerVariantRequest(string Name, string? SwatchHex);
public sealed record OwnerTierRequest(int MinimumQuantity, long UnitPrice);
public sealed record StockDeltaRequest(int Delta, string Reason);
public sealed record StockAdjustmentRequest(Guid ProductId, int Delta, string Reason);
public sealed record OwnerProductMutationDto(Guid Id, string Slug, string Status, uint Version);

/// <summary>Seller-scoped catalogue mutations; stock changes are atomic and ledgered.</summary>
public sealed class CatalogOwnerService(
    CatalogDbContext catalog,
    PlatformDbContext platform,
    ITenantContext tenant,
    ICurrentUser current,
    ISellerDirectory sellerDirectory,
    IUnitOfWork unitOfWork,
    IAuditLog audit,
    IOutbox outbox,
    TimeProvider clock)
{
    private sealed record OwnerCursor(DateTime UpdatedAt, Guid Id);

    public async Task<OwnerProductPageDto> ListAsync(int requestedLimit, string? token, CancellationToken ct)
    {
        var sellerId = await ActiveSellerIdAsync(ct);
        var limit = Math.Clamp(requestedLimit, 1, 100);
        OwnerCursor? cursor = null;
        if (!string.IsNullOrWhiteSpace(token))
        {
            try
            {
                var value = token.Replace('-', '+').Replace('_', '/');
                value = value.PadRight(value.Length + ((4 - value.Length % 4) % 4), '=');
                cursor = JsonSerializer.Deserialize<OwnerCursor>(Convert.FromBase64String(value));
                if (cursor is null || cursor.Id == Guid.Empty) throw new FormatException();
            }
            catch (Exception ex) when (ex is FormatException or JsonException)
            {
                throw DomainException.Validation("cursor", "Cursor is invalid.");
            }
        }

        var query = catalog.Products.AsNoTracking().Where(p => p.SellerId == sellerId);
        if (cursor is not null)
            query = query.Where(p => p.UpdatedAt < cursor.UpdatedAt ||
                (p.UpdatedAt == cursor.UpdatedAt && p.Id.CompareTo(cursor.Id) < 0));
        var rows = await query.OrderByDescending(p => p.UpdatedAt).ThenByDescending(p => p.Id)
            .Select(p => new
            {
                p.Id, p.Name, p.Sku, p.PriceMinor, p.MrpMinor, p.Status,
                Stock = p.Stock == null ? 0 : p.Stock.OnHand,
                Reserved = p.Stock == null ? 0 : p.Stock.Reserved,
                p.MinimumOrderQuantity, p.Xmin, p.UpdatedAt
            })
            .Take(limit + 1).ToListAsync(ct);
        var page = rows.Take(limit).ToArray();
        var next = rows.Count > limit
            ? new OwnerCursor(page[^1].UpdatedAt, page[^1].Id)
            : null;
        var nextToken = next is null ? null : Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(next))
            .TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return new OwnerProductPageDto(page.Select(p => new OwnerProductSummaryDto(
            p.Id, p.Name, p.Sku, WholeRupees(p.PriceMinor), WholeRupees(p.MrpMinor), p.Status,
            p.Stock, p.Reserved, p.MinimumOrderQuantity, p.Xmin, p.UpdatedAt)).ToArray(), nextToken);
    }

    public async Task<OwnerProductMutationDto> CreateAsync(OwnerProductUpsertRequest request, CancellationToken ct)
    {
        var sellerId = await ActiveSellerIdAsync(ct);
        Validate(request, requireVersion: false);
        await EnsureSkuAvailableAsync(request.Sku, null, ct);
        await EnsureReferencesAsync(request, sellerId, ct);
        var productId = Guid.CreateVersion7();
        var slug = await UniqueSlugAsync(Slug(request.Name), null, ct);
        var now = clock.GetUtcNow().UtcDateTime;

        var product = MakeProduct(request, productId, sellerId, slug, now);
        product.TenantId = tenant.TenantId;
        product.Status = "active";
        product.Stock = new StockLevel
        {
            ProductId = productId,
            TrackInventory = true,
            OnHand = request.InitialStock,
            Reserved = 0,
            UpdatedAt = now
        };
        if (request.InitialStock > 0)
            catalog.StockMovements.Add(new StockMovement
            {
                Id = Guid.CreateVersion7(), ProductId = productId,
                OnHandDelta = request.InitialStock, Reason = "import", ActorId = current.UserId,
                CreatedAt = now
            });
        catalog.Products.Add(product);

        await unitOfWork.ExecuteAsync(async token =>
        {
            await catalog.SaveChangesAsync(token);
            await audit.WriteAsync("catalog.product.created", "product", productId, null,
                new { product.Name, product.Sku, product.Status }, token);
            outbox.Enqueue("Catalog.ProductChanged", "Product", productId,
                new { productId, tenantId = tenant.TenantId, change = "created" }, tenant.TenantId);
        }, ct);
        return new OwnerProductMutationDto(product.Id, product.Slug, product.Status, product.Xmin);
    }

    public async Task<OwnerProductMutationDto> UpdateAsync(Guid id, OwnerProductUpsertRequest request, CancellationToken ct)
    {
        var sellerId = await ActiveSellerIdAsync(ct);
        Validate(request, requireVersion: true);
        await EnsureSkuAvailableAsync(request.Sku, id, ct);
        await EnsureReferencesAsync(request, sellerId, ct);
        var product = await catalog.Products
            .Include(p => p.Images).Include(p => p.Variants)
            .Include(p => p.WholesalePriceTiers).Include(p => p.Specs)
            .FirstOrDefaultAsync(p => p.Id == id && p.SellerId == sellerId && p.DeletedAt == null, ct)
            ?? throw DomainException.NotFound("Product", id);
        if (product.Xmin != request.Version)
            throw DomainException.Conflict("This product changed since it was opened. Reload it before saving.", "stale_product");

        var before = new { product.Name, product.Sku, product.PriceMinor, product.MrpMinor, product.Status };
        var slug = await UniqueSlugAsync(Slug(request.Name), product.Id, ct);
        var now = clock.GetUtcNow().UtcDateTime;
        ApplyProduct(product, request, slug, now);
        catalog.ProductImages.RemoveRange(product.Images);
        product.Images = request.ImageMediaIds.Select((mediaId, position) => new ProductImage
        {
            Id = Guid.CreateVersion7(), ProductId = product.Id, MediaId = mediaId, Position = position
        }).ToList();
        catalog.ProductVariants.RemoveRange(product.Variants);
        product.Variants = MakeVariants(product.Id, request);
        catalog.WholesalePriceTiers.RemoveRange(product.WholesalePriceTiers);
        product.WholesalePriceTiers = request.WholesalePriceTiers.Select(t => new WholesalePriceTier
        {
            Id = Guid.CreateVersion7(), ProductId = product.Id,
            MinimumQuantity = t.MinimumQuantity, UnitPriceMinor = ToMinor(t.UnitPrice)
        }).ToList();
        catalog.ProductSpecs.RemoveRange(product.Specs);
        product.Specs = request.Specs.Select((s, index) => new ProductSpec
        {
            Id = Guid.CreateVersion7(), ProductId = product.Id,
            FieldKey = s.Key.Trim(), FieldValue = s.Value.Trim(), Position = index
        }).ToList();
        product.UpdatedAt = now;
        catalog.Entry(product).Property(p => p.Xmin).OriginalValue = request.Version!.Value;

        await unitOfWork.ExecuteAsync(async token =>
        {
            try
            {
                await catalog.SaveChangesAsync(token);
            }
            catch (DbUpdateConcurrencyException)
            {
                throw DomainException.Conflict("This product changed while you were saving it. Reload and try again.", "stale_product");
            }
            await audit.WriteAsync("catalog.product.updated", "product", product.Id, before,
                new { product.Name, product.Sku, product.PriceMinor, product.MrpMinor, product.Status }, token);
            outbox.Enqueue("Catalog.ProductChanged", "Product", product.Id,
                new { productId = product.Id, tenantId = tenant.TenantId, change = "updated" }, tenant.TenantId);
        }, ct);
        return new OwnerProductMutationDto(product.Id, product.Slug, product.Status, product.Xmin);
    }

    public async Task ArchiveAsync(Guid id, CancellationToken ct)
    {
        var sellerId = await ActiveSellerIdAsync(ct);
        var product = await catalog.Products.FirstOrDefaultAsync(
            p => p.Id == id && p.SellerId == sellerId && p.DeletedAt == null, ct)
            ?? throw DomainException.NotFound("Product", id);
        var now = clock.GetUtcNow().UtcDateTime;
        var before = new { product.Status, product.DeletedAt };
        product.Status = "archived";
        product.DeletedAt = now;
        product.UpdatedAt = now;
        await unitOfWork.ExecuteAsync(async token =>
        {
            await catalog.SaveChangesAsync(token);
            await audit.WriteAsync("catalog.product.archived", "product", product.Id, before,
                new { product.Status, product.DeletedAt }, token);
            outbox.Enqueue("Catalog.ProductChanged", "Product", product.Id,
                new { productId = product.Id, tenantId = tenant.TenantId, change = "archived" }, tenant.TenantId);
        }, ct);
    }

    public async Task AdjustStockAsync(StockAdjustmentRequest request, CancellationToken ct)
    {
        var sellerId = await ActiveSellerIdAsync(ct);
        if (request.Delta == 0 || request.Delta == int.MinValue || Math.Abs(request.Delta) > 1_000_000)
            throw DomainException.Validation("delta", "Stock adjustment must be non-zero and no larger than 1,000,000 units.");
        var reason = request.Reason?.Trim().ToLowerInvariant();
        if (reason is not ("restock" or "adjust" or "return" or "import"))
            throw DomainException.Validation("reason", "Reason must be restock, adjust, return, or import.");
        var ownsProduct = await catalog.Products.AsNoTracking().AnyAsync(
            p => p.Id == request.ProductId && p.SellerId == sellerId && p.DeletedAt == null, ct);
        if (!ownsProduct) throw DomainException.NotFound("Product", request.ProductId);
        var now = clock.GetUtcNow().UtcDateTime;
        await unitOfWork.ExecuteAsync(async token =>
        {
            var changed = await catalog.StockLevels
                .Where(s => s.ProductId == request.ProductId && s.OnHand + request.Delta >= s.Reserved && s.OnHand + request.Delta >= 0)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(s => s.OnHand, s => s.OnHand + request.Delta)
                    .SetProperty(s => s.UpdatedAt, now), token);
            if (changed == 0)
                throw DomainException.Conflict("Stock cannot be reduced below reserved units.", "stock_reserved");
            catalog.StockMovements.Add(new StockMovement
            {
                Id = Guid.CreateVersion7(), ProductId = request.ProductId,
                OnHandDelta = request.Delta, Reason = reason, ActorId = current.UserId, CreatedAt = now
            });
            await catalog.SaveChangesAsync(token);
            await audit.WriteAsync("catalog.stock.adjusted", "product", request.ProductId, null,
                new { delta = request.Delta, reason }, token);
            outbox.Enqueue("Catalog.StockChanged", "Product", request.ProductId,
                new { productId = request.ProductId, tenantId = tenant.TenantId }, tenant.TenantId);
        }, ct);
    }

    private async Task EnsureReferencesAsync(OwnerProductUpsertRequest request, Guid sellerId, CancellationToken ct)
    {
        if (!await catalog.Brands.AnyAsync(b => b.Id == request.BrandId, ct))
            throw DomainException.Validation("brandId", "Brand does not exist for this store.");
        if (!await catalog.Categories.AnyAsync(c => c.Id == request.CategoryId, ct))
            throw DomainException.Validation("categoryId", "Category does not exist for this store.");
        if (request.ImageMediaIds.Length == 0) return;
        var ids = request.ImageMediaIds.Distinct().ToArray();
        if (ids.Length != request.ImageMediaIds.Length)
            throw DomainException.Validation("imageMediaIds", "An image may only be listed once.");
        var count = await platform.MediaAssets.CountAsync(m => ids.Contains(m.Id) &&
            m.TenantId == tenant.TenantId && m.SellerId == sellerId && m.Purpose == "product" &&
            m.Status == "ready" && !m.IsPrivate, ct);
        if (count != ids.Length)
            throw DomainException.Validation("imageMediaIds", "Every image must be a ready product image uploaded by this seller.");
    }

    private async Task<string> UniqueSlugAsync(string value, Guid? exceptId, CancellationToken ct)
    {
        if (value.Length == 0) throw DomainException.Validation("name", "Name must include letters or numbers.");
        var slug = value;
        for (var suffix = 2; await catalog.Products.AnyAsync(p => p.DeletedAt == null && p.Slug == slug && p.Id != exceptId, ct); suffix++)
            slug = $"{value}-{suffix}";
        return slug;
    }

    private async Task EnsureSkuAvailableAsync(string sku, Guid? exceptId, CancellationToken ct)
    {
        var normalized = sku.Trim().ToUpperInvariant();
        var exists = await catalog.Products.AnyAsync(p => p.DeletedAt == null && p.Sku == normalized && p.Id != exceptId, ct);
        if (exists) throw DomainException.Conflict("SKU is already used by another active product.", "duplicate_sku");
    }

    private static Product MakeProduct(OwnerProductUpsertRequest request, Guid id, Guid sellerId, string slug, DateTime now)
    {
        var product = new Product
        {
            Id = id, TenantId = Guid.Empty, SellerId = sellerId, CreatedAt = now, UpdatedAt = now,
            Status = "draft"
        };
        ApplyProduct(product, request, slug, now);
        product.Images = request.ImageMediaIds.Select((mediaId, position) => new ProductImage
        {
            Id = Guid.CreateVersion7(), ProductId = id, MediaId = mediaId, Position = position
        }).ToList();
        product.Variants = MakeVariants(id, request);
        product.WholesalePriceTiers = request.WholesalePriceTiers.Select(t => new WholesalePriceTier
        {
            Id = Guid.CreateVersion7(), ProductId = id,
            MinimumQuantity = t.MinimumQuantity, UnitPriceMinor = ToMinor(t.UnitPrice)
        }).ToList();
        product.Specs = request.Specs.Select((s, index) => new ProductSpec
        {
            Id = Guid.CreateVersion7(), ProductId = id,
            FieldKey = s.Key.Trim(), FieldValue = s.Value.Trim(), Position = index
        }).ToList();
        return product;
    }

    private static void ApplyProduct(Product product, OwnerProductUpsertRequest request, string slug, DateTime now)
    {
        product.BrandId = request.BrandId;
        product.CategoryId = request.CategoryId;
        product.Name = request.Name.Trim();
        product.Sku = request.Sku.Trim().ToUpperInvariant();
        product.Slug = slug;
        product.SeoTitle = request.Name.Trim();
        product.Description = request.Description.Trim();
        product.PriceMinor = ToMinor(request.Price);
        product.MrpMinor = ToMinor(request.Mrp);
        product.MinimumOrderQuantity = request.MinimumOrderQuantity;
        product.DeliveryDays = request.DeliveryDays;
        product.Family = request.Family.Trim();
        product.Style = request.Style.Trim();
        product.Metal = request.Metal.Trim();
        product.Purity = request.Purity.Trim();
        product.Audience = request.Audience.Trim();
        product.Occasions = request.Occasions.Select(x => x.Trim()).Where(x => x.Length > 0).Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        product.Highlights = request.Highlights.Select(x => x.Trim()).Where(x => x.Length > 0).ToArray();
        product.SearchText = string.Join(' ', new[] { product.Name, product.Sku, product.Family, product.Style,
            product.Metal, product.Purity, product.Audience, string.Join(' ', product.Occasions) });
        product.UpdatedAt = now;
    }

    private static List<ProductVariant> MakeVariants(Guid productId, OwnerProductUpsertRequest request) =>
        request.Sizes.Select((v, i) => new ProductVariant
        {
            Id = Guid.CreateVersion7(), ProductId = productId, Kind = "size", Name = v.Name.Trim(), Position = i
        }).Concat(request.Shades.Select((v, i) => new ProductVariant
        {
            Id = Guid.CreateVersion7(), ProductId = productId, Kind = "shade", Name = v.Name.Trim(),
            SwatchHex = v.SwatchHex, Position = i
        })).ToList();

    private static void Validate(OwnerProductUpsertRequest request, bool requireVersion)
    {
        if (string.IsNullOrWhiteSpace(request.Name) || request.Name.Trim().Length > 300)
            throw DomainException.Validation("name", "Name is required and must be at most 300 characters.");
        if (string.IsNullOrWhiteSpace(request.Sku) || request.Sku.Trim().Length > 100)
            throw DomainException.Validation("sku", "SKU is required and must be at most 100 characters.");
        if (request.Description is null || request.Description.Length > 20_000)
            throw DomainException.Validation("description", "Description must be at most 20,000 characters.");
        if (request.Price <= 0 || request.Price > long.MaxValue / 100 ||
            request.Mrp < request.Price || request.Mrp > long.MaxValue / 100)
            throw DomainException.Validation("price", "Price must be positive and MRP must be at least the price.");
        if (request.MinimumOrderQuantity < 1) throw DomainException.Validation("minimumOrderQuantity", "MOQ must be at least one.");
        if (request.InitialStock < 0) throw DomainException.Validation("initialStock", "Stock cannot be negative.");
        if (request.DeliveryDays is < 0 or > 365) throw DomainException.Validation("deliveryDays", "Delivery days must be between 0 and 365.");
        if (request.Occasions is null || request.Highlights is null || request.ImageMediaIds is null ||
            request.Sizes is null || request.Shades is null || request.WholesalePriceTiers is null || request.Specs is null)
            throw DomainException.Validation("product", "Product lists and specs cannot be null.");
        if (request.Occasions.Length > 20 || request.Highlights.Length > 20 || request.ImageMediaIds.Length > 20 ||
            request.Sizes.Length > 50 || request.Shades.Length > 50)
            throw DomainException.Validation("product", "A product may have at most 20 occasions, highlights, and images.");
        if (request.Specs.Count > 50 || request.Specs.Any(x => string.IsNullOrWhiteSpace(x.Key) || x.Key.Length > 100 || x.Value is null || x.Value.Length > 500) ||
            request.Specs.Keys.Distinct(StringComparer.OrdinalIgnoreCase).Count() != request.Specs.Count)
            throw DomainException.Validation("specs", "Product specs exceed the allowed key or value limits.");
        if (request.Occasions.Any(x => string.IsNullOrWhiteSpace(x) || x.Length > 100) ||
            request.Highlights.Any(x => string.IsNullOrWhiteSpace(x) || x.Length > 500))
            throw DomainException.Validation("product", "Occasions or highlights contain an empty or oversized value.");
        if (request.Sizes.Any(v => v is null || string.IsNullOrWhiteSpace(v.Name) || v.Name.Length > 200) ||
            request.Shades.Any(v => v is null || string.IsNullOrWhiteSpace(v.Name) || v.Name.Length > 200 ||
                (v.SwatchHex is not null && (v.SwatchHex.Length != 7 || v.SwatchHex[0] != '#' ||
                    !v.SwatchHex.AsSpan(1).ToString().All(Uri.IsHexDigit)))) ||
            request.Sizes.Select(v => v.Name).Distinct(StringComparer.OrdinalIgnoreCase).Count() != request.Sizes.Length ||
            request.Shades.Select(v => v.Name).Distinct(StringComparer.OrdinalIgnoreCase).Count() != request.Shades.Length)
            throw DomainException.Validation("variants", "Variant names and colour swatches are invalid.");
        if (request.WholesalePriceTiers.Any(t => t is null))
            throw DomainException.Validation("wholesalePriceTiers", "Price tiers cannot contain null values.");
        if (requireVersion && request.Version is null) throw DomainException.Validation("version", "Version is required to update a product.");
        var lastQuantity = 0;
        var previousPrice = ToMinor(request.Price);
        foreach (var tier in request.WholesalePriceTiers.OrderBy(t => t.MinimumQuantity))
        {
            if (tier.MinimumQuantity <= lastQuantity || tier.MinimumQuantity < Math.Max(2, request.MinimumOrderQuantity) ||
                tier.UnitPrice <= 0 || tier.UnitPrice > long.MaxValue / 100 || ToMinor(tier.UnitPrice) >= previousPrice)
                throw DomainException.Validation("wholesalePriceTiers", "Tier quantities must increase from MOQ and each tier price must be lower than the preceding price.");
            lastQuantity = tier.MinimumQuantity;
            previousPrice = ToMinor(tier.UnitPrice);
        }
    }

    private async Task<Guid> ActiveSellerIdAsync(CancellationToken ct)
    {
        if (!current.IsSeller || current.SellerId is not { } sellerId)
            throw DomainException.Forbidden("An active seller account is required.");
        var seller = await sellerDirectory.GetSellerAsync(sellerId, ct);
        if (seller is null || seller.Status != "active")
            throw DomainException.Forbidden("This seller account is not active.");
        return sellerId;
    }

    private static long ToMinor(long rupees) => checked(rupees * 100);
    private static long WholeRupees(long minor) => checked((long)Math.Round(minor / 100m, MidpointRounding.AwayFromZero));

    private static string Slug(string value)
    {
        var chars = value.Trim().ToLowerInvariant().Select(c => char.IsLetterOrDigit(c) ? c : '-').ToArray();
        var slug = new string(chars);
        while (slug.Contains("--", StringComparison.Ordinal)) slug = slug.Replace("--", "-", StringComparison.Ordinal);
        return slug.Trim('-');
    }
}
