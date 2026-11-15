using System.Security.Claims;
using BuildingBlocks.Security;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;

namespace BuildingBlocks.Security;

/// <summary>JWT-derived caller identity (claims set by the Identity module: sub, role, tenant, seller_id).</summary>
public sealed class ClaimsCurrentUser(IHttpContextAccessor http) : ICurrentUser
{
    private ClaimsPrincipal? User => http.HttpContext?.User;

    public bool IsAuthenticated => User?.Identity?.IsAuthenticated ?? false;

    public Guid UserId
    {
        get
        {
            var value = User?.FindFirst("sub")?.Value
                        ?? User?.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            return Guid.TryParse(value, out var id) ? id : Guid.Empty;
        }
    }

    // "role" when MapInboundClaims = false (Api), ClaimTypes.Role when mapped.
    public string Role => User?.FindFirst("role")?.Value
                          ?? User?.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value
                          ?? "";

    public Guid TenantId
    {
        get
        {
            var value = User?.FindFirst(ClaimTypes.Tenant)?.Value;
            return Guid.TryParse(value, out var id) ? id : Guid.Empty;
        }
    }

    public Guid? SellerId
    {
        get
        {
            var value = User?.FindFirst(ClaimTypes.SellerId)?.Value;
            return Guid.TryParse(value, out var id) ? id : null;
        }
    }

    public bool IsInRole(params string[] roles) =>
        IsAuthenticated && roles.Any(r => string.Equals(r, Role, StringComparison.OrdinalIgnoreCase));

    public bool IsSeller => IsInRole(Roles.SellerOwner, Roles.SellerStaff);
    public bool IsAdmin => IsInRole(Roles.Admin);
}

/// <summary>
/// Tenant scope for HTTP requests: the JWT claim when present, otherwise the
/// configured default tenant (design §2.6 — anonymous browse/login run before
/// any token exists; reference seeding creates the default tenant row).
/// </summary>
public sealed class ClaimsTenantContext(ICurrentUser currentUser, IConfiguration configuration) : ITenantContext
{
    private static Guid? _configured;

    public Guid TenantId
    {
        get
        {
            if (currentUser.IsAuthenticated && currentUser.TenantId != Guid.Empty)
                return currentUser.TenantId;
            if (_configured is { } configured) return configured;
            var raw = configuration["Tenants:DefaultId"]
                ?? throw new InvalidOperationException("Tenants:DefaultId is required (default tenant for pre-auth requests).");
            if (!Guid.TryParse(raw, out var id) || id == Guid.Empty)
                throw new InvalidOperationException("Tenants:DefaultId must be a non-empty GUID.");
            _configured = id;
            return id;
        }
    }

    public bool HasTenant => TenantId != Guid.Empty;
}

/// <summary>Fixed tenant for Worker jobs and seeding — configured via Tenants:DefaultId.</summary>
public sealed class FixedTenantContext(IConfiguration configuration) : ITenantContext
{
    private Guid? _cached;

    public Guid TenantId
    {
        get
        {
            if (_cached is { } cached) return cached;
            var raw = configuration["Tenants:DefaultId"];
            _cached = Guid.TryParse(raw, out var id) ? id : Guid.Empty;
            return _cached.Value;
        }
    }

    public bool HasTenant => TenantId != Guid.Empty;
}

/// <summary>Background jobs run as the system user (no HTTP principal).</summary>
public sealed class SystemCurrentUser : ICurrentUser
{
    public bool IsAuthenticated => true;
    public Guid UserId => Guid.Empty;
    public string Role => "system";
    public Guid TenantId => Guid.Empty;
    public Guid? SellerId => null;
    public bool IsInRole(params string[] roles) => false;
    public bool IsSeller => false;
    public bool IsAdmin => true;
}
