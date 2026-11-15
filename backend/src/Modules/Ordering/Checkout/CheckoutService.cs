using System.Text.Json;
using System.Text.Json.Serialization;
using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Errors;
using BuildingBlocks.Outbox;
using BuildingBlocks.Security;
using Catalog.Contracts;
using Catalog.Data;
using Catalog.Data.Entities;
using Identity.Contracts;
using Identity.Data;
using Microsoft.EntityFrameworkCore;
using Ordering.Contracts;
using Ordering.Data;
using Ordering.Data.Entities;

namespace Ordering.Checkout;

/// <summary>
/// Commits a buyer's multi-seller checkout, tax and inventory reservations in the
/// shared unit of work. Payment provider calls happen in the Payments module.
/// </summary>
public sealed class CheckoutService(
    OrderingDbContext ordering,
    CatalogDbContext catalog,
    IdentityDbContext identity,
    PlatformDbContext platform,
    ICatalogPricing pricing,
    ISellerDirectory sellers,
    IUserDirectory users,
    ICurrentUser current,
    ITenantContext tenant,
    IUnitOfWork unitOfWork,
    IOutbox outbox,
    TimeProvider clock)
{
    private sealed record AddressSnapshot(
        [property: JsonPropertyName("contact_name")] string ContactName,
        [property: JsonPropertyName("phone")] string Phone,
        [property: JsonPropertyName("line1")] string Line1,
        [property: JsonPropertyName("line2")] string? Line2,
        [property: JsonPropertyName("city")] string City,
        [property: JsonPropertyName("state")] string State,
        [property: JsonPropertyName("state_code")] string StateCode,
        [property: JsonPropertyName("pincode")] string Pincode,
        [property: JsonPropertyName("gstin")] string? GstIn);

    private sealed record PricedLine(CartItem CartItem, ProductQuote Product, long UnitPriceMinor,
        long LineMinor, int TaxRateBps);

    public async Task<PlaceOrderResponseDto> PlaceAsync(PlaceOrderRequest request, CancellationToken ct)
    {
        EnsureBuyer();
        ValidateRequest(request);
        request = request with { PaymentMethod = request.PaymentMethod.Trim().ToUpperInvariant() };
        var buyer = await identity.BuyerProfiles.AsNoTracking()
            .FirstOrDefaultAsync(x => x.UserId == current.UserId, ct);
        if (buyer is null || buyer.KycStatus != "approved")
            throw DomainException.Forbidden("An approved business buyer account is required to place orders.");

        var shipping = await GetAddressAsync(request.ShippingAddressId, ct);
        var billing = request.BillingAddressId is { } billingId
            ? await GetAddressAsync(billingId, ct)
            : shipping;
        var buyerSnapshot = await users.GetActiveUserAsync(current.UserId, ct)
            ?? throw DomainException.Forbidden("The buyer account is inactive.");

        PlaceOrderResponseDto? response = null;
        await unitOfWork.ExecuteAsync(async token =>
        {
            await LockBuyerAsync(token);
            var cart = await ordering.Carts.Include(x => x.Items)
                .FirstOrDefaultAsync(x => x.UserId == current.UserId, token)
                ?? throw DomainException.RuleViolation("empty_cart", "Add products to your cart before placing an order.");
            if (cart.Items.Count == 0)
                throw DomainException.RuleViolation("empty_cart", "Add products to your cart before placing an order.");
            if (!string.IsNullOrWhiteSpace(cart.CouponCode))
                throw DomainException.RuleViolation("coupon_unavailable", "Remove the coupon and retry; coupon checkout is not enabled yet.");

            var quotes = await pricing.GetQuotesAsync(cart.Items.Select(x => x.ProductId).Distinct().ToArray(), token);
            var missing = cart.Items.Where(x => !quotes.ContainsKey(x.ProductId)).Select(x => x.ProductId).Distinct().ToArray();
            if (missing.Length > 0) throw DomainException.StockConflict(missing);

            var priced = new List<PricedLine>(cart.Items.Count);
            foreach (var item in cart.Items.OrderBy(x => x.ProductId).ThenBy(x => x.SelectedSize).ThenBy(x => x.SelectedShade))
            {
                var product = quotes[item.ProductId];
                if (product.PricingMode == "weight_based")
                    throw DomainException.RuleViolation("live_rate_required", "Weight-based jewellery needs a live-rate quote before checkout.");
                if (item.Quantity < product.MinimumOrderQuantity)
                    throw DomainException.RuleViolation("minimum_order_quantity", $"{product.Name} requires at least {product.MinimumOrderQuantity} units.");
                if (!HasVariant(product.Sizes, item.SelectedSize) || !HasVariant(product.Shades, item.SelectedShade))
                    throw DomainException.RuleViolation("variant_unavailable", $"A selected option for {product.Name} is no longer available.");
                if (product.TrackInventory && product.AvailableStock < item.Quantity)
                    throw DomainException.StockConflict([product.Id]);
                var unit = product.Tiers.Where(x => x.MinimumQuantity <= item.Quantity)
                    .OrderByDescending(x => x.MinimumQuantity).Select(x => x.UnitPriceMinor)
                    .FirstOrDefault(product.PriceMinor);
                var line = checked(unit * item.Quantity);
                priced.Add(new PricedLine(item, product, unit, line, 0));
            }

            var sellerIds = priced.Select(x => x.Product.SellerId).Distinct().ToArray();
            var sellerRows = await sellers.GetSellersByIdsAsync(sellerIds, token);
            var sellerById = sellerRows.Where(x => x.Status == "active").ToDictionary(x => x.Id);
            if (sellerIds.Any(id => !sellerById.ContainsKey(id)))
                throw DomainException.RuleViolation("seller_unavailable", "A seller in your cart is not currently accepting orders.");

            var today = DateOnly.FromDateTime(clock.GetUtcNow().UtcDateTime);
            var taxRules = await ordering.TaxRules.AsNoTracking()
                .Where(x => x.EffectiveFrom <= today && (x.EffectiveTo == null || x.EffectiveTo >= today))
                .OrderByDescending(x => x.EffectiveFrom)
                .ToListAsync(token);
            var taxByHsn = taxRules.GroupBy(x => x.HsnCode)
                .ToDictionary(g => g.Key, g => g.First().RateBps, StringComparer.OrdinalIgnoreCase);
            priced = priced.Select(line => line with
            {
                TaxRateBps = taxByHsn.GetValueOrDefault(line.Product.HsnCode,
                    taxByHsn.GetValueOrDefault("*", 1800))
            }).ToList();

            // Reserve in stable product order. Conditional updates ensure two buyers
            // cannot both consume the final available units.
            foreach (var group in priced.GroupBy(x => x.Product.Id).OrderBy(x => x.Key))
            {
                if (!group.First().Product.TrackInventory) continue;
                var quantity = group.Sum(x => x.CartItem.Quantity);
                var changed = await catalog.StockLevels.Where(x => x.ProductId == group.Key &&
                        (!x.TrackInventory || x.OnHand - x.Reserved >= quantity))
                    .ExecuteUpdateAsync(s => s.SetProperty(x => x.Reserved, x => x.Reserved + quantity)
                        .SetProperty(x => x.UpdatedAt, clock.GetUtcNow().UtcDateTime), token);
                if (changed == 0) throw DomainException.StockConflict([group.Key]);
            }

            var checkoutId = Guid.CreateVersion7();
            var now = clock.GetUtcNow().UtcDateTime;
            var paymentStatus = PaymentStatuses.Pending;
            var expiresAt = request.PaymentMethod == "COD" ? null as DateTime? : now.AddMinutes(15);
            var checkout = new Ordering.Data.Entities.Checkout
            {
                Id = checkoutId, TenantId = tenant.TenantId, CustomerId = current.UserId,
                ShippingAddress = JsonSerializer.Serialize(shipping), BillingAddress = JsonSerializer.Serialize(billing),
                BuyerGstin = request.BuyerGstin?.Trim().ToUpperInvariant() ?? buyer.GstIn,
                GrandTotalMinor = 0, DeliveryOption = request.DeliveryOption,
                GiftWrap = request.GiftWrap, GiftNote = request.GiftNote?.Trim(),
                PaymentMethod = request.PaymentMethod, PaymentStatus = paymentStatus,
                ExpiresAt = expiresAt, PlacedAt = now
            };

            var responseOrders = new List<PlacedOrderDto>();
            long grandTotal = 0;
            foreach (var group in priced.GroupBy(x => x.Product.SellerId).OrderBy(x => x.Key))
            {
                var seller = sellerById[group.Key];
                var orderId = Guid.CreateVersion7();
                var subtotal = group.Sum(x => x.LineMinor);
                long cgst = 0, sgst = 0, igst = 0;
                var lines = new List<OrderItem>();
                foreach (var line in group)
                {
                    var tax = checked((long)Math.Round(line.LineMinor * line.TaxRateBps / 10_000m,
                        MidpointRounding.AwayFromZero));
                    if (seller.StateCode == shipping.StateCode)
                    {
                        var half = tax / 2;
                        cgst = checked(cgst + half);
                        sgst = checked(sgst + tax - half);
                    }
                    else igst = checked(igst + tax);
                    lines.Add(new OrderItem
                    {
                        Id = Guid.CreateVersion7(), OrderId = orderId, ProductId = line.Product.Id,
                        Sku = line.Product.Sku, Name = line.Product.Name, Brand = line.Product.Brand,
                        HsnCode = line.Product.HsnCode, SelectedSize = line.CartItem.SelectedSize,
                        SelectedShade = line.CartItem.SelectedShade, Quantity = line.CartItem.Quantity,
                        UnitPriceMinor = line.UnitPriceMinor, LineNetMinor = line.LineMinor,
                        TaxRateBps = line.TaxRateBps, TaxMinor = tax
                    });
                }
                var taxTotal = checked(cgst + sgst + igst);
                var sequence = await platform.NextSequenceAsync($"order:{now:yyyy}", token);
                var order = new Order
                {
                    Id = orderId, OrderNumber = $"ORD-{now:yyyy}-{sequence:000000}",
                    TenantId = tenant.TenantId, CheckoutId = checkoutId, CustomerId = current.UserId,
                    SellerId = seller.Id, CustomerName = buyerSnapshot.Name, SellerName = seller.Name,
                    Status = OrderStatus.Placed, PaymentStatus = paymentStatus,
                    PaymentMethod = request.PaymentMethod, DeliveryOption = request.DeliveryOption,
                    SubtotalMinor = subtotal, TaxableMinor = subtotal, CgstMinor = cgst, SgstMinor = sgst,
                    IgstMinor = igst, TaxMinor = taxTotal, TotalMinor = checked(subtotal + taxTotal),
                    PlacedAt = now, UpdatedAt = now,
                    Items = lines,
                    History = [new OrderStatusHistory
                    {
                        Id = Guid.CreateVersion7(), FromStatus = null, ToStatus = OrderStatus.Placed,
                        ChangedBy = current.UserId, ActorRole = "customer", ChangedAt = now, Note = "Order placed"
                    }]
                };
                ordering.Orders.Add(order);
                checkout.Orders.Add(order);
                foreach (var line in group)
                    if (line.Product.TrackInventory)
                        catalog.StockMovements.Add(new StockMovement
                        {
                            Id = Guid.CreateVersion7(), ProductId = line.Product.Id, OnHandDelta = 0, ReservedDelta = line.CartItem.Quantity,
                            Reason = "reserve", OrderId = orderId, ActorId = current.UserId, CreatedAt = now
                        });
                grandTotal = checked(grandTotal + order.TotalMinor);
                responseOrders.Add(new PlacedOrderDto(order.Id, order.OrderNumber, "placed",
                    WholeRupees(order.TotalMinor), order.PaymentStatus));
                outbox.Enqueue("Order.Placed", "Order", order.Id,
                    new { orderId = order.Id, checkoutId, customerId = current.UserId, sellerId = seller.Id, tenantId = tenant.TenantId }, tenant.TenantId);
            }

            checkout.GrandTotalMinor = grandTotal;
            ordering.Checkouts.Add(checkout);
            ordering.CartItems.RemoveRange(cart.Items);
            cart.CouponCode = null;
            cart.UpdatedAt = now;
            await ordering.SaveChangesAsync(token);
            await catalog.SaveChangesAsync(token);
            outbox.Enqueue("Checkout.Placed", "Checkout", checkoutId,
                new { checkoutId, tenantId = tenant.TenantId, customerId = current.UserId, grandTotalMinor = grandTotal }, tenant.TenantId);

            response = new PlaceOrderResponseDto(checkoutId, responseOrders, WholeRupees(grandTotal),
                request.PaymentMethod != "COD", request.PaymentMethod, expiresAt);
        }, ct);
        return response!;
    }

    private async Task<AddressSnapshot> GetAddressAsync(Guid id, CancellationToken ct)
    {
        var address = await identity.Addresses.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == current.UserId, ct)
            ?? throw DomainException.Validation("addressId", "Choose an address saved to your buyer account.");
        return new AddressSnapshot(address.ContactName, address.Phone, address.Line1, address.Line2,
            address.City, address.State, address.StateCode, address.Pincode, address.GstIn);
    }

    private async Task LockBuyerAsync(CancellationToken ct)
    {
        var buyerId = current.UserId.ToString("D");
        await ordering.Database.ExecuteSqlInterpolatedAsync($"select pg_advisory_xact_lock(hashtext({buyerId}))", ct);
    }

    private void EnsureBuyer()
    {
        if (!current.IsAuthenticated || !current.IsInRole(Roles.Customer) || current.UserId == Guid.Empty)
            throw DomainException.Forbidden("Sign in with an approved buyer account to place an order.");
    }

    private static bool HasVariant(IReadOnlyList<string> values, string? selected) =>
        values.Count == 0 ? selected is null : selected is not null && values.Contains(selected, StringComparer.OrdinalIgnoreCase);

    private static void ValidateRequest(PlaceOrderRequest request)
    {
        var method = request.PaymentMethod?.Trim().ToUpperInvariant();
        if (method is not ("UPI" or "CARD" or "NETBANKING" or "RTGS" or "COD"))
            throw DomainException.Validation("paymentMethod", "Choose UPI, CARD, NETBANKING, RTGS, or COD.");
        if (request.DeliveryOption is not ("standard" or "express" or "priority"))
            throw DomainException.Validation("deliveryOption", "Choose standard, express, or priority delivery.");
        if (request.GiftNote?.Length > 500)
            throw DomainException.Validation("giftNote", "Gift note must be 500 characters or fewer.");
        if (request.BuyerGstin is not null && request.BuyerGstin.Trim().Length > 20)
            throw DomainException.Validation("buyerGstin", "Buyer GSTIN must be 20 characters or fewer.");
    }

    private static long WholeRupees(long minor) => checked((long)Math.Round(minor / 100m, MidpointRounding.AwayFromZero));
}
