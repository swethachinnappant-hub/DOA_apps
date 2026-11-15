using NpgsqlTypes;

namespace Ordering.Data.Entities;

public enum OrderStatus
{
    [PgName("placed")] Placed,
    [PgName("confirmed")] Confirmed,
    [PgName("packed")] Packed,
    [PgName("shipped")] Shipped,
    [PgName("out_for_delivery")] OutForDelivery,
    [PgName("delivered")] Delivered,
    [PgName("cancelled")] Cancelled,
    [PgName("returned")] Returned
}

/// <summary>Payment status as text + CHECK (design §5.3) — not a native enum.</summary>
public static class PaymentStatuses
{
    public const string Pending = "pending";
    public const string Paid = "paid";
    public const string Failed = "failed";
    public const string Refunded = "refunded";
    public const string PartiallyRefunded = "partially_refunded";
    public const string OnCredit = "on_credit";

    public const string Check = "payment_status in ('pending','paid','failed','refunded','partially_refunded','on_credit')";
}

public class TaxRule
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string HsnCode { get; set; } = null!; // '*' = tenant fallback
    public string SupplyKind { get; set; } = "goods"; // goods | job_work
    public int RateBps { get; set; }
    public DateOnly EffectiveFrom { get; set; }
    public DateOnly? EffectiveTo { get; set; }
}

public class Cart
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid UserId { get; set; }
    public string? CouponCode { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public List<CartItem> Items { get; set; } = [];
}

public class CartItem
{
    public Guid Id { get; set; }
    public Guid CartId { get; set; }
    public Cart? Cart { get; set; }
    public Guid ProductId { get; set; }
    public int Quantity { get; set; }
    public string? SelectedSize { get; set; }
    public string? SelectedShade { get; set; }
    /// <summary>Lets the cart say "price changed since you added this" (design §5.3).</summary>
    public long? AddedUnitPriceMinor { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>One customer checkout = one payment = N seller orders (design §5.3, §6.3).</summary>
public class Checkout
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid CustomerId { get; set; }
    public string Currency { get; set; } = "INR";
    public string ShippingAddress { get; set; } = "{}"; // jsonb snapshot (incl. state_code, pincode)
    public string BillingAddress { get; set; } = "{}";
    public string? BuyerGstin { get; set; }
    public string? CouponCode { get; set; }
    public long CouponDiscountMinor { get; set; }
    public long GrandTotalMinor { get; set; }
    public string DeliveryOption { get; set; } = "standard"; // standard | express | priority (ETA only)
    public bool GiftWrap { get; set; }
    public string? GiftNote { get; set; }
    public string PaymentMethod { get; set; } = "UPI"; // UPI | CARD | NETBANKING | RTGS | CREDIT | COD
    public string PaymentStatus { get; set; } = PaymentStatuses.Pending;
    /// <summary>Prepaid only — never set for COD/on_credit; Worker cancels and releases stock.</summary>
    public DateTime? ExpiresAt { get; set; }
    public DateTime PlacedAt { get; set; } = DateTime.UtcNow;
    public List<Order> Orders { get; set; } = [];
}

public class Order
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = null!; // 'ORD-2026-' || lpad(seq, 6, '0')
    public Guid TenantId { get; set; }
    public Guid CheckoutId { get; set; }
    public Checkout? Checkout { get; set; }
    public Guid CustomerId { get; set; }
    public Guid SellerId { get; set; }
    public string CustomerName { get; set; } = null!; // snapshots
    public string SellerName { get; set; } = null!;
    public OrderStatus Status { get; set; } = OrderStatus.Placed;
    public string PaymentStatus { get; set; } = PaymentStatuses.Pending;
    public string PaymentMethod { get; set; } = "UPI";
    public string DeliveryOption { get; set; } = "standard";
    public string Currency { get; set; } = "INR";
    public long SubtotalMinor { get; set; }
    public long CouponDiscountMinor { get; set; }
    public long TaxableMinor { get; set; }
    public long CgstMinor { get; set; }
    public long SgstMinor { get; set; }
    public long IgstMinor { get; set; }
    public long TaxMinor { get; set; }
    public long ShippingMinor { get; set; }
    public long RoundOffMinor { get; set; }
    public long TotalMinor { get; set; }
    public string? CancelledReason { get; set; }
    public DateTime PlacedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public uint Xmin { get; set; }

    public List<OrderItem> Items { get; set; } = [];
    public List<OrderStatusHistory> History { get; set; } = [];
    public List<Shipment> Shipments { get; set; } = [];
}

public class OrderItem
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public Guid ProductId { get; set; }
    public string Sku { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Brand { get; set; } = null!;
    public string HsnCode { get; set; } = null!;
    public string? ImageKey { get; set; } // primary image storage key only
    public string? SelectedSize { get; set; }
    public string? SelectedShade { get; set; }
    public int Quantity { get; set; }
    public long UnitPriceMinor { get; set; }
    public long LineNetMinor { get; set; }
    public long DiscountMinor { get; set; } // allocated share of the coupon
    public int TaxRateBps { get; set; }
    public long TaxMinor { get; set; }
    /// <summary>weight_based: {rate, karat, netWeightMg, making, stones, rateAt} (design §5.3).</summary>
    public string? PricingSnapshot { get; set; }
}

public class OrderStatusHistory
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public OrderStatus? FromStatus { get; set; }
    public OrderStatus ToStatus { get; set; }
    public Guid? ChangedBy { get; set; }
    public string? ActorRole { get; set; } // customer | seller | admin | system
    public DateTime ChangedAt { get; set; } = DateTime.UtcNow;
    public string? Note { get; set; }
}

public class Shipment
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public string Carrier { get; set; } = null!;
    public string? Awb { get; set; }
    public string? TrackingUrl { get; set; }
    public long InsuredValueMinor { get; set; } // high-value jewellery ships insured
    public DateTime? ShippedAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>Gap-free per (seller, FY) via platform.number_sequences (design §5.3).</summary>
public class Invoice
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public Guid SellerId { get; set; }
    public string FinancialYear { get; set; } = null!; // '2026-27'
    public string InvoiceNo { get; set; } = null!;
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
    public string? SellerGstin { get; set; }
    public string? BuyerGstin { get; set; }
    public string PlaceOfSupply { get; set; } = null!;
    public long TaxableMinor { get; set; }
    public long CgstMinor { get; set; }
    public long SgstMinor { get; set; }
    public long IgstMinor { get; set; }
    public long RoundOffMinor { get; set; }
    public long TotalMinor { get; set; }
    public Guid? PdfMediaId { get; set; }
    public string? Irn { get; set; }
}

public class OrderReturn
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public Guid OrderItemId { get; set; }
    public OrderItem? OrderItem { get; set; }
    public int Quantity { get; set; }
    public string Reason { get; set; } = null!;
    public string Status { get; set; } = "requested"; // requested|approved|rejected|received|refunded
    public long RefundMinor { get; set; }
    public DateTime RequestedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ResolvedAt { get; set; }
}
