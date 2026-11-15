namespace Identity.Data.Entities;

/// <summary>A shop; the platform's own stock is the single row with IsPlatform = true (design §5.1).</summary>
public class Seller
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string? GstIn { get; set; }
    public string StateCode { get; set; } = null!;
    public bool IsPlatform { get; set; }
    public bool IsVerified { get; set; }
    public string Status { get; set; } = "pending"; // pending | active | suspended
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class User
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid? SellerId { get; set; }
    public string Name { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Phone { get; set; } = null!;
    public DateTime? PhoneVerifiedAt { get; set; }
    public string? PasswordHash { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>B2B buyer: who is buying and are they approved (design §5.1, §8 buyer gating).</summary>
public class BuyerProfile
{
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string BusinessName { get; set; } = null!;
    public string? GstIn { get; set; }
    public string? Pan { get; set; }
    public string KycStatus { get; set; } = "pending"; // pending | approved | rejected | suspended
    public Guid? KycReviewedBy { get; set; }
    public DateTime? KycReviewedAt { get; set; }
    public Guid[] KycMediaIds { get; set; } = [];
    public long CreditLimitMinor { get; set; }
    public int PaymentTermsDays { get; set; }
}

/// <summary>Opaque refresh token, stored hashed, rotating, per-family (design §8).</summary>
public class RefreshToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public Guid FamilyId { get; set; }
    public string TokenHash { get; set; } = null!;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    public Guid? ReplacedBy { get; set; }
    public string? DeviceId { get; set; }
    public string? UserAgent { get; set; }
    public string? CreatedIp { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsActive => RevokedAt is null && ExpiresAt > DateTime.UtcNow;
}

public class Address
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string? Label { get; set; }
    public string ContactName { get; set; } = null!;
    public string Phone { get; set; } = null!;
    public string Line1 { get; set; } = null!;
    public string? Line2 { get; set; }
    public string City { get; set; } = null!;
    public string State { get; set; } = null!;
    public string StateCode { get; set; } = null!;
    public string Pincode { get; set; } = null!;
    public string? GstIn { get; set; }
    public bool IsDefault { get; set; }
}

public class DeviceToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string Platform { get; set; } = null!; // android | ios | web
    public string Token { get; set; } = null!;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;
    public DateTime? RevokedAt { get; set; }
}

/// <summary>identity.roles — customer, seller_owner, seller_staff, admin, support (design §5.1).</summary>
public class Role
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
}

/// <summary>identity.user_roles — role membership (design §5.1, one active role per user in practice).</summary>
public class UserRole
{
    public Guid UserId { get; set; }
    public Guid RoleId { get; set; }
    public User? User { get; set; }
    public Role? Role { get; set; }
}
