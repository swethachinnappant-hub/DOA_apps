namespace Promotions.Data.Entities;

/// <summary>
/// Coupon definition (design §5.5): PK (tenant_id, code) — citext, unique per
/// tenant; flat amount off (money model §2.2), min-subtotal guard, windows and
/// usage caps. seller_id null ⇒ platform-funded.
/// </summary>
public class Coupon
{
    public Guid TenantId { get; set; }
    public string Code { get; set; } = null!;
    public Guid? SellerId { get; set; }
    public long FlatOffMinor { get; set; }
    public long MinSubtotalMinor { get; set; }
    public string Description { get; set; } = "";
    public DateTime? StartsAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public int UsageLimit { get; set; } // 0 ⇒ unlimited
    public int PerUserLimit { get; set; } // 0 ⇒ unlimited
    public int UsedCount { get; set; }
    public bool IsActive { get; set; } = true;
}

/// <summary>Applied/reversed coupon per checkout (design §5.5).</summary>
public class CouponRedemption
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string CouponCode { get; set; } = null!;
    public Guid CheckoutId { get; set; }
    public Guid UserId { get; set; }
    public long DiscountMinor { get; set; }
    public string Status { get; set; } = "applied"; // applied | reversed
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ReversedAt { get; set; }
}

/// <summary>Loyalty balance lives here, off identity.users (design §5.5).</summary>
public class LoyaltyAccount
{
    public Guid UserId { get; set; }
    public int Points { get; set; }
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>Awarded on DELIVERED, reversed on return (design §5.5).</summary>
public class LoyaltyLedger
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public int Delta { get; set; }
    public int BalanceAfter { get; set; }
    public string Reason { get; set; } = null!;
    public Guid? OrderId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
