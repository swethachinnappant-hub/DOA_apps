using BuildingBlocks.Audit;
using BuildingBlocks.Errors;
using BuildingBlocks.Security;
using Identity.Auth;
using Identity.Data;
using Identity.Data.Entities;
using Microsoft.EntityFrameworkCore;

namespace Identity.Accounts;

/// <summary>Design §7.1 — /me profile, addresses, FCM devices and the B2B buyer profile.</summary>
public sealed class AccountService(
    IdentityDbContext db,
    IAuditLog audit,
    ICurrentUser current,
    ITenantContext tenant)
{
    // ── Profile ────────────────────────────────────────────────────────────────

    public async Task<User> GetMeAsync(CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == current.UserId, ct)
            ?? throw DomainException.NotFound("User", current.UserId);
        return user;
    }

    public async Task<MeDto> GetMeDtoAsync(CancellationToken ct)
    {
        var user = await GetMeAsync(ct);
        return ToMeDto(user, await GetRoleAsync(user.Id, ct));
    }

    public async Task<MeDto> PatchMeAsync(UpdateProfileRequest request, CancellationToken ct)
    {
        var user = await GetMeAsync(ct);
        var before = new { user.Name, user.Phone };

        if (request.Name is { } name && !string.IsNullOrWhiteSpace(name))
            user.Name = name.Trim();

        if (request.Phone is { } phone)
        {
            var normalized = AuthService.NormalizePhone(phone);
            if (await db.Users.AnyAsync(u => u.Id != user.Id && u.Phone == normalized, ct))
                throw DomainException.Conflict("An account with this phone already exists.", "phone_exists");
            if (user.Phone != normalized)
            {
                user.Phone = normalized;
                user.PhoneVerifiedAt = null; // must re-verify after a change
            }
        }

        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await audit.WriteAsync("account.profile_updated", "user", user.Id,
            before, new { user.Name, user.Phone }, ct);
        return ToMeDto(user, await GetRoleAsync(user.Id, ct));
    }

    // ── Addresses ──────────────────────────────────────────────────────────────

    public async Task<IReadOnlyList<AddressDto>> ListAddressesAsync(CancellationToken ct) =>
        await db.Addresses.AsNoTracking()
            .Where(a => a.UserId == current.UserId)
            .OrderByDescending(a => a.IsDefault).ThenBy(a => a.ContactName)
            .Select(a => ToDto(a))
            .ToListAsync(ct);

    public async Task<AddressDto> UpsertAddressAsync(AddressRequest request, CancellationToken ct)
    {
        var userId = current.UserId;
        var address = request.Id is { } id
            ? await db.Addresses.FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId, ct)
                ?? throw DomainException.NotFound("Address", id)
            : new Address { Id = Guid.CreateVersion7(), UserId = userId };

        address.Label = request.Label;
        address.ContactName = request.ContactName;
        address.Phone = request.Phone;
        address.Line1 = request.Line1;
        address.Line2 = request.Line2;
        address.City = request.City;
        address.State = request.State;
        address.StateCode = request.StateCode.Trim().ToUpperInvariant();
        address.Pincode = request.Pincode;
        address.GstIn = request.GstIn?.Trim().ToUpperInvariant();
        address.IsDefault = request.IsDefault;

        if (address.IsDefault)
        {
            // Keep the partial unique index (ux_addresses_default) satisfied.
            await db.Addresses
                .Where(a => a.UserId == userId && a.IsDefault && a.Id != address.Id)
                .ExecuteUpdateAsync(s => s.SetProperty(a => a.IsDefault, false), ct);
        }

        if (request.Id is null) db.Addresses.Add(address);
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException)
        {
            throw DomainException.Conflict("This address is already the default for another entry.", "default_conflict");
        }
        return ToDto(address);
    }

    public async Task DeleteAddressAsync(Guid id, CancellationToken ct)
    {
        var userId = current.UserId;
        var rows = await db.Addresses
            .Where(a => a.Id == id && a.UserId == userId)
            .ExecuteDeleteAsync(ct);
        if (rows == 0) throw DomainException.NotFound("Address", id);
    }

    // ── FCM device tokens (design §7.1, §9) ────────────────────────────────────

    public async Task RegisterDeviceAsync(DeviceRequest request, CancellationToken ct)
    {
        if (request.Platform is not ("android" or "ios" or "web"))
            throw DomainException.Validation("platform", "Platform must be 'android', 'ios' or 'web'.");

        var userId = current.UserId;
        var existing = await db.DeviceTokens.FirstOrDefaultAsync(d => d.Token == request.Token, ct);
        if (existing is null)
        {
            db.DeviceTokens.Add(new DeviceToken
            {
                Id = Guid.CreateVersion7(),
                UserId = userId,
                Platform = request.Platform,
                Token = request.Token
            });
        }
        else
        {
            existing.UserId = userId; // re-registered to this account
            existing.Platform = request.Platform;
            existing.RevokedAt = null;
            existing.LastSeenAt = DateTime.UtcNow;
        }
        await db.SaveChangesAsync(ct);
    }

    public async Task RemoveDeviceAsync(string token, CancellationToken ct)
    {
        var userId = current.UserId;
        var rows = await db.DeviceTokens
            .Where(d => d.Token == token && d.UserId == userId)
            .ExecuteUpdateAsync(s => s.SetProperty(d => d.RevokedAt, DateTime.UtcNow), ct);
        if (rows == 0) throw DomainException.NotFound("Device token", token);
    }

    // ── Buyer (B2B) profile ────────────────────────────────────────────────────

    public async Task<BuyerProfileDto> GetBuyerProfileAsync(CancellationToken ct)
    {
        var profile = await db.BuyerProfiles.AsNoTracking()
            .FirstOrDefaultAsync(p => p.UserId == current.UserId, ct);
        if (profile is null)
        {
            profile = new BuyerProfile
            {
                UserId = current.UserId,
                BusinessName = (await GetMeAsync(ct)).Name,
                KycStatus = "pending"
            };
            db.BuyerProfiles.Add(profile);
            await db.SaveChangesAsync(ct);
        }
        return ToDto(profile);
    }

    public async Task<BuyerProfileDto> UpsertBuyerProfileAsync(BuyerProfileUpsertRequest request, CancellationToken ct)
    {
        var profile = await db.BuyerProfiles.FirstOrDefaultAsync(p => p.UserId == current.UserId, ct);
        var isNew = profile is null;
        if (isNew)
        {
            profile = new BuyerProfile { UserId = current.UserId };
            db.BuyerProfiles.Add(profile);
        }
        var before = isNew ? null : new { profile.BusinessName, profile.GstIn, profile.Pan, profile.KycMediaIds };

        profile.BusinessName = request.BusinessName.Trim();
        profile.GstIn = request.GstIn?.Trim().ToUpperInvariant();
        profile.Pan = request.Pan?.Trim().ToUpperInvariant();
        if (request.KycMediaIds is not null) profile.KycMediaIds = request.KycMediaIds;
        // kyc_status is only changed by admin review (design §7.6).

        await db.SaveChangesAsync(ct);
        await audit.WriteAsync(isNew ? "account.buyer_profile_created" : "account.buyer_profile_updated",
            "buyer_profile", profile.UserId,
            before, new { profile.BusinessName, profile.GstIn, profile.Pan, profile.KycMediaIds }, ct);
        return ToDto(profile);
    }

    // ── Mapping ────────────────────────────────────────────────────────────────

    private async Task<string> GetRoleAsync(Guid userId, CancellationToken ct) =>
        await db.UserRoles
            .Where(ur => ur.UserId == userId)
            .Select(ur => ur.Role!.Name)
            .FirstOrDefaultAsync(ct) ?? "customer";

    private static MeDto ToMeDto(User user, string role) =>
        new(user.Id, user.Name, user.Email, user.Phone, role, user.SellerId, user.TenantId, user.PhoneVerifiedAt, user.CreatedAt);

    private static AddressDto ToDto(Address a) =>
        new(a.Id, a.Label, a.ContactName, a.Phone, a.Line1, a.Line2, a.City, a.State, a.StateCode, a.Pincode, a.GstIn, a.IsDefault);

    private static BuyerProfileDto ToDto(BuyerProfile p) =>
        new(p.UserId, p.BusinessName, p.GstIn, p.Pan, p.KycStatus, p.KycMediaIds, p.CreditLimitMinor, p.PaymentTermsDays);
}
