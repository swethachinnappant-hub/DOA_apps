using System.Security.Cryptography;
using System.Text;
using BuildingBlocks.Data;
using BuildingBlocks.Errors;
using BuildingBlocks.Security;
using Microsoft.EntityFrameworkCore;

namespace BuildingBlocks.Idempotency;

/// <summary>
/// Design §2.5/§5.7/§6.4 — (user, key) claims; the SHA-256 request hash decides
/// replay vs. conflict; completed rows keep the stored status+body for 48 h
/// (expires_at index lets the Worker prune); locked_until lets an abandoned
/// in_progress claim be retaken.
/// </summary>
public sealed class IdempotencyService(
    PlatformDbContext platform,
    ICurrentUser currentUser,
    TimeProvider clock) : IIdempotencyService
{
    public async Task<IdempotencyClaim> ClaimAsync(string key, string payloadHash, CancellationToken ct = default)
    {
        var userId = currentUser.UserId;
        var now = clock.GetUtcNow().UtcDateTime;
        var hash = Convert.FromHexString(payloadHash);

        var existing = await platform.IdempotencyKeys
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Key == key, ct);

        if (existing is null)
        {
            platform.IdempotencyKeys.Add(new Data.Platform.IdempotencyRecord
            {
                UserId = userId,
                Key = key,
                RequestHash = hash,
                Status = "in_progress",
                LockedUntil = now.Add(Data.Platform.IdempotencyRecord.ClaimLock),
                CreatedAt = now,
                ExpiresAt = now.AddHours(Data.Platform.IdempotencyRecord.RetentionHours)
            });
            try
            {
                await platform.SaveChangesAsync(ct);
                return new IdempotencyClaim(IdempotencyClaimKind.New);
            }
            catch (DbUpdateException)
            {
                // Lost the race on the (user, key) primary key — re-read.
                platform.ChangeTracker.Clear();
                existing = await platform.IdempotencyKeys
                    .FirstOrDefaultAsync(r => r.UserId == userId && r.Key == key, ct)
                    ?? throw DomainException.Conflict("Idempotency key conflict.", "idempotency_key_conflict");
            }
        }

        if (!CryptographicOperations.FixedTimeEquals(existing.RequestHash, hash))
            throw DomainException.Conflict("This Idempotency-Key was already used with a different request body.", "idempotency_key_conflict");

        if (existing.Status == "completed")
            return new IdempotencyClaim(
                IdempotencyClaimKind.Replay,
                existing.ResponseStatus ?? 200,
                existing.ResponseBody);

        // in_progress: take over only when the previous claim's lock expired.
        if (existing.LockedUntil is null || existing.LockedUntil <= now)
        {
            existing.LockedUntil = now.Add(Data.Platform.IdempotencyRecord.ClaimLock);
            await platform.SaveChangesAsync(ct);
            return new IdempotencyClaim(IdempotencyClaimKind.New);
        }

        return new IdempotencyClaim(IdempotencyClaimKind.InProgress);
    }

    public async Task CompleteAsync(string key, int statusCode, string responseBody, CancellationToken ct = default)
    {
        var userId = currentUser.UserId;
        var record = await platform.IdempotencyKeys
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Key == key, ct);
        if (record is null) return;

        var now = clock.GetUtcNow().UtcDateTime;
        record.Status = "completed";
        record.ResponseStatus = statusCode;
        record.ResponseBody = responseBody;
        record.LockedUntil = null;
        record.ExpiresAt = now.AddHours(Data.Platform.IdempotencyRecord.RetentionHours);
        await platform.SaveChangesAsync(ct);
    }

    public async Task ReleaseAsync(string key, CancellationToken ct = default)
    {
        var userId = currentUser.UserId;
        var record = await platform.IdempotencyKeys
            .FirstOrDefaultAsync(r => r.UserId == userId && r.Key == key, ct);
        if (record is null || record.Status != "in_progress") return;
        platform.IdempotencyKeys.Remove(record);
        await platform.SaveChangesAsync(ct);
    }

    public static string HashPayload(string method, string path, string body)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes($"{method.ToUpperInvariant()}|{path}|{body}"));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
