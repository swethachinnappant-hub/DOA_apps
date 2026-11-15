using BuildingBlocks.Data;
using BuildingBlocks.Errors;
using BuildingBlocks.Security;
using Catalog.Contracts;
using Microsoft.EntityFrameworkCore;
using Ordering.Contracts;
using Ordering.Data;
using Ordering.Data.Entities;
using CartEntity = Ordering.Data.Entities.Cart;

namespace Ordering.Cart;

/// <summary>Persistent customer cart with server-side MOQ, stock, variant and tier-price checks.</summary>
public sealed class CartService(
    OrderingDbContext ordering,
    ICatalogPricing catalogPricing,
    ICurrentUser current,
    ITenantContext tenant,
    IUnitOfWork unitOfWork,
    TimeProvider clock)
{
    public async Task<CartDto> GetAsync(CancellationToken ct)
    {
        EnsureCustomer();
        var cart = await ordering.Carts.AsNoTracking().Include(c => c.Items)
            .FirstOrDefaultAsync(c => c.UserId == current.UserId, ct);
        if (cart is null) return new CartDto(null, [], 0, 0, null, clock.GetUtcNow().UtcDateTime);
        return await ToDtoAsync(cart, ct);
    }

    public async Task<CartDto> AddAsync(AddCartItemRequest request, CancellationToken ct)
    {
        EnsureCustomer();
        if (request.Quantity < 1 || request.Quantity > 100_000)
            throw DomainException.Validation("quantity", "Quantity must be between 1 and 100,000.");
        var quote = await GetAvailableQuoteAsync(request.ProductId, ct);
        EnsureFixedPrice(quote);
        var size = NormalizeVariant(request.Size);
        var shade = NormalizeVariant(request.Shade);
        EnsureVariants(quote, size, shade);
        var quantity = Math.Max(request.Quantity, quote.MinimumOrderQuantity);
        await unitOfWork.ExecuteAsync(async token =>
        {
            await LockCartAsync(token);
            var cart = await GetOrCreateCartAsync(token);
            var line = await ordering.CartItems.FirstOrDefaultAsync(x => x.CartId == cart.Id &&
                x.ProductId == quote.Id && x.SelectedSize == size && x.SelectedShade == shade, token);
            if (line is null)
            {
                line = new CartItem
                {
                    Id = Guid.CreateVersion7(), CartId = cart.Id, ProductId = quote.Id,
                    Quantity = quantity, SelectedSize = size, SelectedShade = shade,
                    AddedUnitPriceMinor = UnitPrice(quote, quantity), CreatedAt = clock.GetUtcNow().UtcDateTime
                };
                EnsureStock(quote, line.Quantity);
                ordering.CartItems.Add(line);
            }
            else
            {
                var combined = (long)line.Quantity + quantity;
                if (combined > 100_000) throw DomainException.Validation("quantity", "A cart line cannot exceed 100,000 units.");
                line.Quantity = (int)Math.Max(combined, quote.MinimumOrderQuantity);
                EnsureStock(quote, line.Quantity);
            }
            cart.UpdatedAt = clock.GetUtcNow().UtcDateTime;
            await ordering.SaveChangesAsync(token);
        }, ct);
        return await GetAsync(ct);
    }

    public async Task<CartDto> UpdateAsync(Guid lineId, UpdateCartItemRequest request, CancellationToken ct)
    {
        EnsureCustomer();
        if (request.Quantity < 1 || request.Quantity > 100_000)
            throw DomainException.Validation("quantity", "Quantity must be between 1 and 100,000.");
        var productId = await ordering.CartItems.AsNoTracking()
            .Where(x => x.Id == lineId && x.Cart!.UserId == current.UserId)
            .Select(x => new { x.ProductId, x.SelectedSize, x.SelectedShade }).FirstOrDefaultAsync(ct)
            ?? throw DomainException.NotFound("Cart item", lineId);
        var quote = await GetAvailableQuoteAsync(productId.ProductId, ct);
        EnsureFixedPrice(quote);
        var size = request.Size is null ? productId.SelectedSize : NormalizeVariant(request.Size);
        var shade = request.Shade is null ? productId.SelectedShade : NormalizeVariant(request.Shade);
        EnsureVariants(quote, size, shade);
        var quantity = Math.Max(request.Quantity, quote.MinimumOrderQuantity);
        EnsureStock(quote, quantity);

        await unitOfWork.ExecuteAsync(async token =>
        {
            await LockCartAsync(token);
            var cart = await ordering.Carts.FirstOrDefaultAsync(c => c.UserId == current.UserId, token)
                ?? throw DomainException.NotFound("Cart");
            var line = await ordering.CartItems.FirstOrDefaultAsync(x => x.Id == lineId && x.CartId == cart.Id, token)
                ?? throw DomainException.NotFound("Cart item", lineId);
            var duplicate = await ordering.CartItems.AnyAsync(x => x.CartId == cart.Id && x.Id != line.Id &&
                x.ProductId == line.ProductId && x.SelectedSize == size && x.SelectedShade == shade, token);
            if (duplicate) throw DomainException.Conflict("A cart line already exists for this product and variant.", "duplicate_cart_line");
            line.Quantity = quantity;
            line.SelectedSize = size;
            line.SelectedShade = shade;
            cart.UpdatedAt = clock.GetUtcNow().UtcDateTime;
            await ordering.SaveChangesAsync(token);
        }, ct);
        return await GetAsync(ct);
    }

    public async Task<CartDto> RemoveAsync(Guid lineId, CancellationToken ct)
    {
        EnsureCustomer();
        await unitOfWork.ExecuteAsync(async token =>
        {
            await LockCartAsync(token);
            var cart = await ordering.Carts.FirstOrDefaultAsync(c => c.UserId == current.UserId, token)
                ?? throw DomainException.NotFound("Cart");
            var line = await ordering.CartItems.FirstOrDefaultAsync(x => x.Id == lineId && x.CartId == cart.Id, token)
                ?? throw DomainException.NotFound("Cart item", lineId);
            ordering.CartItems.Remove(line);
            cart.UpdatedAt = clock.GetUtcNow().UtcDateTime;
            await ordering.SaveChangesAsync(token);
        }, ct);
        return await GetAsync(ct);
    }

    public async Task ClearAsync(CancellationToken ct)
    {
        EnsureCustomer();
        await unitOfWork.ExecuteAsync(async token =>
        {
            await LockCartAsync(token);
            var cart = await ordering.Carts.Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UserId == current.UserId, token);
            if (cart is null) return;
            ordering.CartItems.RemoveRange(cart.Items);
            cart.CouponCode = null;
            cart.UpdatedAt = clock.GetUtcNow().UtcDateTime;
            await ordering.SaveChangesAsync(token);
        }, ct);
    }

    private async Task<CartDto> ToDtoAsync(CartEntity cart, CancellationToken ct)
    {
        var quotes = await catalogPricing.GetQuotesAsync(cart.Items.Select(i => i.ProductId).Distinct().ToArray(), ct);
        var lines = new List<CartLineDto>(cart.Items.Count);
        long subtotalMinor = 0;
        var totalQuantity = 0;
        foreach (var item in cart.Items.OrderBy(i => i.CreatedAt))
        {
            if (!quotes.TryGetValue(item.ProductId, out var product))
            {
                lines.Add(new CartLineDto(item.Id, item.ProductId, "Unavailable product", "", "", null,
                    item.Quantity, 1, 0, 0, true, false, item.SelectedSize, item.SelectedShade, 0));
                totalQuantity += item.Quantity;
                continue;
            }
            var unit = UnitPrice(product, item.Quantity);
            var lineTotal = checked(unit * item.Quantity);
            subtotalMinor = checked(subtotalMinor + lineTotal);
            totalQuantity += item.Quantity;
            var inStock = !product.TrackInventory || product.AvailableStock >= item.Quantity;
            lines.Add(new CartLineDto(item.Id, product.Id, product.Name, product.Brand, product.Sku,
                product.ImageUrl, item.Quantity, product.MinimumOrderQuantity,
                WholeRupees(unit), WholeRupees(lineTotal), item.AddedUnitPriceMinor != unit,
                inStock, item.SelectedSize, item.SelectedShade, product.DeliveryDays));
        }
        return new CartDto(cart.Id, lines, WholeRupees(subtotalMinor), totalQuantity, cart.CouponCode, cart.UpdatedAt);
    }

    private async Task<ProductQuote> GetAvailableQuoteAsync(Guid productId, CancellationToken ct)
    {
        var quotes = await catalogPricing.GetQuotesAsync([productId], ct);
        return quotes.TryGetValue(productId, out var quote)
            ? quote
            : throw DomainException.NotFound("Product", productId);
    }

    private async Task<CartEntity> GetOrCreateCartAsync(CancellationToken ct)
    {
        var cart = await ordering.Carts.Include(c => c.Items)
            .FirstOrDefaultAsync(c => c.UserId == current.UserId, ct);
        if (cart is not null) return cart;
        var id = Guid.CreateVersion7();
        await ordering.Database.ExecuteSqlInterpolatedAsync(
            $"insert into ordering.carts (id, tenant_id, user_id, updated_at) values ({id}, {tenant.TenantId}, {current.UserId}, {clock.GetUtcNow().UtcDateTime}) on conflict (user_id) do nothing", ct);
        return await ordering.Carts.Include(c => c.Items)
            .SingleAsync(c => c.UserId == current.UserId, ct);
    }

    private async Task LockCartAsync(CancellationToken ct)
    {
        var user = current.UserId.ToString("D");
        await ordering.Database.ExecuteSqlInterpolatedAsync($"select pg_advisory_xact_lock(hashtext({user}))", ct);
    }

    private void EnsureCustomer()
    {
        if (!current.IsAuthenticated || !current.IsInRole(Roles.Customer) || current.UserId == Guid.Empty)
            throw DomainException.Forbidden("Sign in with a buyer account to use the cart.");
    }

    private static void EnsureFixedPrice(ProductQuote quote)
    {
        if (quote.PricingMode == "weight_based")
            throw DomainException.RuleViolation("live_rate_required", "Weight-based products require a current gold-rate quote before they can be added.");
    }

    private static void EnsureVariants(ProductQuote quote, string? size, string? shade)
    {
        if (quote.Sizes.Count > 0 && (size is null || !quote.Sizes.Contains(size, StringComparer.OrdinalIgnoreCase)))
            throw DomainException.Validation("size", "Select a valid size for this product.");
        if (quote.Sizes.Count == 0 && size is not null)
            throw DomainException.Validation("size", "This product does not have size variants.");
        if (quote.Shades.Count > 0 && (shade is null || !quote.Shades.Contains(shade, StringComparer.OrdinalIgnoreCase)))
            throw DomainException.Validation("shade", "Select a valid shade for this product.");
        if (quote.Shades.Count == 0 && shade is not null)
            throw DomainException.Validation("shade", "This product does not have shade variants.");
    }

    private static void EnsureStock(ProductQuote quote, int quantity)
    {
        if (quote.TrackInventory && quote.AvailableStock < quantity)
            throw DomainException.StockConflict([quote.Id]);
    }

    private static string? NormalizeVariant(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static long UnitPrice(ProductQuote product, int quantity) => product.Tiers
        .Where(t => t.MinimumQuantity <= quantity)
        .OrderByDescending(t => t.MinimumQuantity)
        .Select(t => t.UnitPriceMinor)
        .FirstOrDefault(product.PriceMinor);

    private static long WholeRupees(long minor) => checked((long)Math.Round(minor / 100m, MidpointRounding.AwayFromZero));
}
