using BuildingBlocks.Audit;
using BuildingBlocks.Caching;
using BuildingBlocks.Data;
using BuildingBlocks.Errors;
using BuildingBlocks.Outbox;
using BuildingBlocks.Results;
using BuildingBlocks.Security;
using Identity.Contracts;
using Identity.Data;
using Identity.Data.Entities;
using Identity.Passwords;
using Identity.Tokens;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Identity.Auth;

/// <summary>
/// Design §7.1/§8 — register, password + OTP login, rotating refresh with family
/// reuse revocation, logout, password reset, demo login. All role/tenant facts are
/// re-read per request; the JWT only carries minimal claims.
/// </summary>
public sealed class AuthService(
    IdentityDbContext db,
    IPasswordHasher hasher,
    ITokenService tokens,
    IOtpService otp,
    IOutbox outbox,
    IUnitOfWork unitOfWork,
    ITenantContext tenant,
    ITicketStore tickets,
    IEmailSender email,
    IAuditLog audit,
    IConfiguration configuration,
    ILogger<AuthService> logger)
{
    private static readonly string[] AllRoles = ["customer", "seller_owner", "seller_staff", "admin", "support"];
    private static readonly Lazy<string> DummyHash = new(() => new PasswordHasher().Hash(Guid.NewGuid().ToString()));

    private static TimeSpan LockoutWindow => TimeSpan.FromMinutes(15);
    private const int MaxPasswordFailures = 5;

    // ── Registration ───────────────────────────────────────────────────────────

    public async Task<TokenResponse> RegisterAsync(RegisterRequest request, string? deviceId, string? userAgent, string? ip, CancellationToken ct)
    {
        var phone = NormalizePhone(request.Phone);
        var email = request.Email.Trim();

        if (await db.Users.AnyAsync(u => u.Email == email, ct))
            throw DomainException.Conflict("An account with this email already exists.", "email_exists");
        if (await db.Users.AnyAsync(u => u.Phone == phone, ct))
            throw DomainException.Conflict("An account with this phone already exists.", "phone_exists");

        await EnsureRolesAsync(ct);

        var user = new User
        {
            Id = Guid.CreateVersion7(),
            TenantId = tenant.TenantId,
            Name = request.Name.Trim(),
            Email = email,
            Phone = phone,
            PasswordHash = hasher.Hash(request.Password),
            IsActive = true
        };
        var role = request.Role;

        TokenResponse? response = null;
        await unitOfWork.ExecuteAsync(async inner =>
        {
            if (role == "seller_owner")
            {
                var seller = new Seller
                {
                    Id = Guid.CreateVersion7(),
                    TenantId = tenant.TenantId,
                    Name = request.ShopName!.Trim(),
                    GstIn = request.GstIn?.Trim().ToUpperInvariant(),
                    StateCode = request.StateCode!.Trim().ToUpperInvariant(),
                    IsPlatform = false,
                    IsVerified = false,
                    Status = "active"
                };
                db.Sellers.Add(seller);
                user.SellerId = seller.Id;
            }
            else
            {
                db.BuyerProfiles.Add(new BuyerProfile
                {
                    UserId = user.Id,
                    BusinessName = user.Name,
                    KycStatus = "pending"
                });
            }

            db.Users.Add(user);
            var roleId = await db.Roles.Where(r => r.Name == role).Select(r => r.Id).FirstAsync(inner);
            db.UserRoles.Add(new UserRole { UserId = user.Id, RoleId = roleId });

            outbox.Enqueue("identity.user_registered.v1", "user", user.Id,
                new UserRegisteredEvent(user.Id, user.TenantId, role, user.Name), user.TenantId);

            response = CreateSession(user, role, deviceId, userAgent, ip);
            await db.SaveChangesAsync(inner);
        }, ct);

        return response!;
    }

    // ── Password login ─────────────────────────────────────────────────────────

    public async Task<TokenResponse> LoginAsync(LoginRequest request, string? deviceId, string? userAgent, string? ip, CancellationToken ct)
    {
        var identifier = request.Identifier.Trim();
        User? user = identifier.Contains('@')
            ? await db.Users.FirstOrDefaultAsync(u => u.Email == identifier, ct)
            : await db.Users.FirstOrDefaultAsync(u => u.Phone == NormalizePhone(identifier), ct);

        if (user is null || !user.IsActive)
        {
            hasher.Verify(request.Password, DummyHash.Value); // equalise timing
            throw DomainException.Unauthorized("Email/phone or password is incorrect.");
        }

        var lockKey = $"auth:lock:{user.Id}";
        if (await tickets.GetAsync(lockKey, ct) is not null)
            throw DomainException.TooManyRequests("Too many failed attempts. Try again in 15 minutes.");

        if (!hasher.Verify(request.Password, user.PasswordHash))
        {
            var failKey = $"auth:fail:{user.Id}";
            var failures = int.Parse(await tickets.GetAsync(failKey, ct) ?? "0") + 1;
            await tickets.SetAsync(failKey, failures.ToString(), LockoutWindow, ct);
            if (failures >= MaxPasswordFailures)
            {
                await tickets.SetAsync(lockKey, "1", LockoutWindow, ct);
                await tickets.RemoveAsync(failKey, ct);
                throw DomainException.TooManyRequests("Too many failed attempts. Try again in 15 minutes.");
            }
            throw DomainException.Unauthorized("Email/phone or password is incorrect.");
        }

        await tickets.RemoveAsync($"auth:fail:{user.Id}", ct);
        if (hasher.NeedsRehash(user.PasswordHash))
        {
            user.PasswordHash = hasher.Hash(request.Password);
            user.UpdatedAt = DateTime.UtcNow;
            await db.SaveChangesAsync(ct);
        }

        var role = await GetRoleAsync(user.Id, ct);
        return CreateSession(user, role, deviceId, userAgent, ip, save: true, ct: ct);
    }

    // ── OTP login (design §8) ──────────────────────────────────────────────────

    public async Task<TokenResponse> VerifyOtpAsync(OtpVerifyRequest request, string? deviceId, string? userAgent, string? ip, CancellationToken ct)
    {
        var phone = NormalizePhone(request.Phone);
        await otp.VerifyAsync(phone, request.Code, ip, ct);

        var user = await db.Users.FirstOrDefaultAsync(u => u.Phone == phone, ct);
        if (user is null || !user.IsActive)
            throw new DomainException(new Error("unknown_phone", "No account is registered with this phone number. Register first."), 401);

        user.PhoneVerifiedAt ??= DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        var role = await GetRoleAsync(user.Id, ct);
        return CreateSession(user, role, deviceId, userAgent, ip, save: true, ct: ct);
    }

    // ── Refresh rotation with reuse detection (design §8) ──────────────────────

    public async Task<TokenResponse> RefreshAsync(RefreshRequest request, string? userAgent, string? ip, CancellationToken ct)
    {
        var hash = tokens.HashRefreshToken(request.RefreshToken);
        var row = await db.RefreshTokens.Include(r => r.User).FirstOrDefaultAsync(r => r.TokenHash == hash, ct);

        if (row is null)
            throw new DomainException(new Error("invalid_refresh", "The refresh token is invalid."), 401);

        if (row.RevokedAt is not null)
        {
            if (row.ReplacedBy is not null)
            {
                // Rotation reuse — revoke the whole family (design §8).
                await db.RefreshTokens
                    .Where(f => f.FamilyId == row.FamilyId && f.RevokedAt == null)
                    .ExecuteUpdateAsync(s => s.SetProperty(f => f.RevokedAt, DateTime.UtcNow), ct);
                logger.LogWarning("Refresh token reuse detected for family {FamilyId} — family revoked", row.FamilyId);
                await audit.WriteAsync("security.refresh_reuse", "refresh_family", row.FamilyId, null, null, ct);
            }
            throw new DomainException(new Error("refresh_revoked", "The session has been signed out. Please log in again."), 401);
        }

        if (row.ExpiresAt <= DateTime.UtcNow)
            throw new DomainException(new Error("refresh_expired", "The session has expired. Please log in again."), 401);

        var user = row.User!;
        if (!user.IsActive)
            throw new DomainException(new Error("invalid_refresh", "The account is deactivated."), 401);

        var role = await GetRoleAsync(user.Id, ct);
        var newRaw = tokens.CreateOpaqueRefreshToken();
        var replacement = new RefreshToken
        {
            Id = Guid.CreateVersion7(),
            UserId = user.Id,
            FamilyId = row.FamilyId,
            TokenHash = tokens.HashRefreshToken(newRaw),
            ExpiresAt = DateTime.UtcNow + tokens.RefreshTokenLifetime,
            DeviceId = request.DeviceId,
            UserAgent = userAgent,
            CreatedIp = ip
        };
        db.RefreshTokens.Add(replacement);
        row.RevokedAt = DateTime.UtcNow;
        row.ReplacedBy = replacement.Id;
        await db.SaveChangesAsync(ct);

        var (access, expires) = tokens.CreateAccessToken(user, role);
        return new TokenResponse(access, newRaw, expires, ToDto(user, role));
    }

    // ── Logout — revokes the whole family, idempotent ──────────────────────────

    public async Task LogoutAsync(string refreshToken, CancellationToken ct)
    {
        var hash = tokens.HashRefreshToken(refreshToken);
        var row = await db.RefreshTokens.FirstOrDefaultAsync(r => r.TokenHash == hash, ct);
        if (row is null) return;
        await db.RefreshTokens
            .Where(f => f.FamilyId == row.FamilyId && f.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(f => f.RevokedAt, DateTime.UtcNow), ct);
    }

    // ── Password reset ─────────────────────────────────────────────────────────

    public async Task ForgotPasswordAsync(string emailAddress, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == emailAddress.Trim(), ct);
        if (user is not null && user.IsActive)
        {
            var code = Random.Shared.Next(0, 1_000_000).ToString("D6");
            await tickets.SetAsync($"pwd:{user.Id}", code, TimeSpan.FromMinutes(15), ct);
            await email.SendAsync(user.Email, "Reset your password",
                $"Your password reset code is {code}. It expires in 15 minutes.", ct);
        }
        // Never reveal whether the account exists (design §8).
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request, CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == request.Email.Trim(), ct);
        if (user is null)
            throw new DomainException(new Error("invalid_reset_code", "The reset code is invalid or expired."), 401);

        var expected = await tickets.GetAsync($"pwd:{user.Id}", ct);
        if (expected is null || !string.Equals(expected, request.Code, StringComparison.Ordinal))
            throw new DomainException(new Error("invalid_reset_code", "The reset code is invalid or expired."), 401);

        user.PasswordHash = hasher.Hash(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);
        await tickets.RemoveAsync($"pwd:{user.Id}", ct);

        // A password reset signs every session out (design §8 revocation).
        await db.RefreshTokens
            .Where(f => f.UserId == user.Id && f.RevokedAt == null)
            .ExecuteUpdateAsync(s => s.SetProperty(f => f.RevokedAt, DateTime.UtcNow), ct);

        await audit.WriteAsync("security.password_reset", "user", user.Id, null, null, ct);
    }

    // ── Demo login — only mapped when Demo:Enabled (design §8) ────────────────

    public async Task<TokenResponse> DemoLoginAsync(string? deviceId, string? userAgent, string? ip, CancellationToken ct)
    {
        var demoEmail = configuration["Demo:UserEmail"] ?? "demo.customer@kirtilals.test";
        var user = await db.Users.FirstOrDefaultAsync(u => u.Email == demoEmail, ct)
            ?? throw DomainException.NotFound("Demo user (run the demo seed first — `dotnet run -- seed --profile demo`)", demoEmail);
        if (!user.IsActive)
            throw DomainException.Forbidden("The demo account is disabled.");

        var role = await GetRoleAsync(user.Id, ct);
        return CreateSession(user, role, deviceId, userAgent, ip, save: true, ct: ct);
    }

    // ── Helpers ────────────────────────────────────────────────────────────────

    private TokenResponse CreateSession(User user, string role, string? deviceId, string? userAgent, string? ip, bool save = false, CancellationToken ct = default)
    {
        var (access, expires) = tokens.CreateAccessToken(user, role);
        var rawRefresh = tokens.CreateOpaqueRefreshToken();
        db.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.CreateVersion7(),
            UserId = user.Id,
            FamilyId = Guid.CreateVersion7(),
            TokenHash = tokens.HashRefreshToken(rawRefresh),
            ExpiresAt = DateTime.UtcNow + tokens.RefreshTokenLifetime,
            DeviceId = deviceId,
            UserAgent = userAgent,
            CreatedIp = ip
        });
        if (save) db.SaveChanges();
        return new TokenResponse(access, rawRefresh, expires, ToDto(user, role));
    }

    private async Task EnsureRolesAsync(CancellationToken ct)
    {
        var existing = (await db.Roles.Select(r => r.Name).ToListAsync(ct)).ToHashSet(StringComparer.Ordinal);
        foreach (var name in AllRoles.Where(name => !existing.Contains(name)))
            db.Roles.Add(new Role { Id = Guid.CreateVersion7(), Name = name });
        if (db.ChangeTracker.HasChanges()) await db.SaveChangesAsync(ct);
    }

    private async Task<string> GetRoleAsync(Guid userId, CancellationToken ct)
    {
        var role = await db.UserRoles
            .Where(ur => ur.UserId == userId)
            .Select(ur => ur.Role!.Name)
            .FirstOrDefaultAsync(ct);
        if (role is not null) return role;
        logger.LogWarning("User {UserId} has no role row — defaulting to customer", userId);
        return "customer";
    }

    private static AuthUserDto ToDto(User user, string role) =>
        new(user.Id, user.Name, user.Email, user.Phone, role, user.SellerId, user.TenantId, user.CreatedAt);

    internal static string NormalizePhone(string phone)
    {
        var digits = phone.Trim().Replace(" ", "").Replace("-", "").Replace("(", "").Replace(")", "");
        if (digits.Length == 10 && digits.All(char.IsDigit)) return $"+91{digits}";
        if (!digits.StartsWith('+') && digits.All(char.IsDigit)) return $"+{digits}";
        return digits;
    }
}
