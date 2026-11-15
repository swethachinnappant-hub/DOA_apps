namespace BuildingBlocks.Security;

/// <summary>Role names (design §5.1: identity.roles rows, §8 policies).</summary>
public static class Roles
{
    public const string Customer = "customer";
    public const string SellerOwner = "SellerOwner";
    public const string SellerStaff = "SellerStaff";
    public const string Admin = "admin";
    public const string Support = "support";

    public static readonly string[] All = [Customer, SellerOwner, SellerStaff, Admin, Support];
    public static readonly string[] SellerRoles = [SellerOwner, SellerStaff];
}

public static class AuthPolicies
{
    public const string Customer = "Customer";
    public const string SellerOwner = "SellerOwner";
    public const string SellerStaff = "SellerStaff";
    public const string Admin = "Admin";
    public const string Support = "Support";

    public static readonly string[] All = [Customer, SellerOwner, SellerStaff, Admin, Support];
}

public static class ClaimTypes
{
    public const string Tenant = "tenant";
    public const string SellerId = "seller_id";
    // "sub" and the standard role claim are used as-is.
}

/// <summary>Caller identity resolved from the JWT (design §8 — minimal claims, mutable state looked up).</summary>
public interface ICurrentUser
{
    bool IsAuthenticated { get; }
    Guid UserId { get; }
    string Role { get; }
    Guid TenantId { get; }
    Guid? SellerId { get; }

    bool IsInRole(params string[] roles);
    bool IsSeller { get; }
    bool IsAdmin { get; }
}

/// <summary>Tenant scope from the JWT — drives every module's EF global query filter (§2.6).</summary>
public interface ITenantContext
{
    Guid TenantId { get; }
    bool HasTenant { get; }
}
