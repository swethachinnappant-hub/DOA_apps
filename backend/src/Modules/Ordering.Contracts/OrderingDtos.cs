namespace Ordering.Contracts;

public sealed record AddCartItemRequest(Guid ProductId, int Quantity, string? Size, string? Shade);
public sealed record UpdateCartItemRequest(int Quantity, string? Size, string? Shade);
public sealed record CartLineDto(
    Guid LineId, Guid ProductId, string Name, string Brand, string Sku,
    string? ImageUrl, int Quantity, int MinimumOrderQuantity,
    long UnitPrice, long LineTotal, bool PriceChanged, bool InStock,
    string? SelectedSize, string? SelectedShade, int DeliveryDays);
public sealed record CartDto(
    Guid? Id, IReadOnlyList<CartLineDto> Items, long Subtotal, int TotalQuantity,
    string? CouponCode, DateTime UpdatedAt);

public sealed record PlaceOrderRequest(
    Guid ShippingAddressId,
    Guid? BillingAddressId,
    string PaymentMethod,
    string DeliveryOption = "standard",
    bool GiftWrap = false,
    string? GiftNote = null,
    string? BuyerGstin = null);
public sealed record PlacedOrderDto(Guid Id, string OrderNumber, string Status, long Total, string PaymentStatus);
public sealed record PlaceOrderResponseDto(
    Guid CheckoutId, IReadOnlyList<PlacedOrderDto> Orders, long GrandTotal,
    bool PaymentRequired, string PaymentMethod, DateTime? PaymentExpiresAt);
