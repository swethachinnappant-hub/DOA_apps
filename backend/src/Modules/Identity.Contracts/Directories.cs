namespace Identity.Contracts;

/// <summary>Cross-module read models + events of the Identity module (design §2.3 — Contracts only).</summary>
public sealed record SellerSnapshot(
    Guid Id,
    Guid TenantId,
    string Name,
    string? GstIn,
    string StateCode,
    bool IsPlatform,
    bool IsVerified,
    string Status);

public sealed record UserSnapshot(
    Guid Id,
    Guid TenantId,
    Guid? SellerId,
    string Name,
    string Email,
    string Phone,
    string Role,
    bool IsActive,
    string? KycStatus);

public interface ISellerDirectory
{
    Task<SellerSnapshot?> GetSellerAsync(Guid id, CancellationToken ct = default);
    Task<SellerSnapshot?> GetPlatformSellerAsync(CancellationToken ct = default);
    Task<IReadOnlyList<SellerSnapshot>> GetSellersByIdsAsync(IReadOnlyCollection<Guid> ids, CancellationToken ct = default);
    Task<IReadOnlyList<Guid>> GetVerifiedSellerIdsAsync(CancellationToken ct = default);
    Task<IReadOnlyList<SellerSnapshot>> GetSellersAsync(CancellationToken ct = default);
}

public interface IUserDirectory
{
    Task<UserSnapshot?> GetUserAsync(Guid id, CancellationToken ct = default);
    Task<UserSnapshot?> GetActiveUserAsync(Guid id, CancellationToken ct = default);
    Task<IReadOnlyList<UserSnapshot>> GetUsersForSellerAsync(Guid sellerId, CancellationToken ct = default);
}

/// <summary>Outbox integration event — Engagement sends the welcome notification.</summary>
public sealed record UserRegisteredEvent(Guid UserId, Guid TenantId, string Role, string Name);
