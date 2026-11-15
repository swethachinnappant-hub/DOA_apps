using Identity.Data;
using Identity.Data.Entities;
using Microsoft.EntityFrameworkCore;

namespace Identity.Contracts;

public sealed class SellerDirectory(IdentityDbContext db) : ISellerDirectory
{
    public async Task<SellerSnapshot?> GetSellerAsync(Guid id, CancellationToken ct = default) =>
        await db.Sellers.AsNoTracking()
            .Where(s => s.Id == id)
            .Select(s => new SellerSnapshot(s.Id, s.TenantId, s.Name, s.GstIn, s.StateCode, s.IsPlatform, s.IsVerified, s.Status))
            .FirstOrDefaultAsync(ct);

    public async Task<SellerSnapshot?> GetPlatformSellerAsync(CancellationToken ct = default) =>
        await db.Sellers.AsNoTracking()
            .Where(s => s.IsPlatform)
            .Select(s => new SellerSnapshot(s.Id, s.TenantId, s.Name, s.GstIn, s.StateCode, s.IsPlatform, s.IsVerified, s.Status))
            .FirstOrDefaultAsync(ct);

    public async Task<IReadOnlyList<SellerSnapshot>> GetSellersByIdsAsync(
        IReadOnlyCollection<Guid> ids, CancellationToken ct = default)
    {
        if (ids.Count == 0) return [];
        return await db.Sellers.AsNoTracking()
            .Where(s => ids.Contains(s.Id))
            .Select(s => new SellerSnapshot(s.Id, s.TenantId, s.Name, s.GstIn, s.StateCode, s.IsPlatform, s.IsVerified, s.Status))
            .ToListAsync(ct);
    }

    public async Task<IReadOnlyList<Guid>> GetVerifiedSellerIdsAsync(CancellationToken ct = default) =>
        await db.Sellers.AsNoTracking()
            .Where(s => s.IsVerified && s.Status == "active")
            .Select(s => s.Id)
            .ToListAsync(ct);

    public async Task<IReadOnlyList<SellerSnapshot>> GetSellersAsync(CancellationToken ct = default) =>
        await db.Sellers.AsNoTracking()
            .Select(s => new SellerSnapshot(s.Id, s.TenantId, s.Name, s.GstIn, s.StateCode, s.IsPlatform, s.IsVerified, s.Status))
            .ToListAsync(ct);
}

public sealed class UserDirectory(IdentityDbContext db) : IUserDirectory
{
    public async Task<UserSnapshot?> GetUserAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id, ct);
        return user is null ? null : await ToSnapshotAsync(user, ct);
    }

    public async Task<UserSnapshot?> GetActiveUserAsync(Guid id, CancellationToken ct = default)
    {
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id && u.IsActive, ct);
        return user is null ? null : await ToSnapshotAsync(user, ct);
    }

    public async Task<IReadOnlyList<UserSnapshot>> GetUsersForSellerAsync(Guid sellerId, CancellationToken ct = default)
    {
        var users = await db.Users.AsNoTracking()
            .Where(u => u.SellerId == sellerId && u.IsActive)
            .ToListAsync(ct);
        var result = new List<UserSnapshot>(users.Count);
        foreach (var user in users)
            result.Add(await ToSnapshotAsync(user, ct));
        return result;
    }

    private async Task<UserSnapshot> ToSnapshotAsync(User user, CancellationToken ct)
    {
        var role = await db.UserRoles.AsNoTracking()
            .Where(ur => ur.UserId == user.Id)
            .Select(ur => ur.Role!.Name)
            .FirstOrDefaultAsync(ct) ?? "customer";
        var kyc = await db.BuyerProfiles.AsNoTracking()
            .Where(p => p.UserId == user.Id)
            .Select(p => p.KycStatus)
            .FirstOrDefaultAsync(ct);
        return new UserSnapshot(user.Id, user.TenantId, user.SellerId, user.Name, user.Email, user.Phone, role, user.IsActive, kyc);
    }
}
