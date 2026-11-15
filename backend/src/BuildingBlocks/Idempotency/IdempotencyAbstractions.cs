namespace BuildingBlocks.Idempotency;

/// <summary>
/// Idempotency-Key replay protection for POST /orders and POST /payments/intents
/// (design §2.5, §6.4). First writer claims (user, key); identical payload hashes
/// replay the stored response; different payloads under the same key → 409.
/// </summary>
public interface IIdempotencyService
{
    Task<IdempotencyClaim> ClaimAsync(string key, string payloadHash, CancellationToken ct = default);
    Task CompleteAsync(string key, int statusCode, string responseBody, CancellationToken ct = default);
    Task ReleaseAsync(string key, CancellationToken ct = default);
}

public enum IdempotencyClaimKind
{
    /// <summary>Caller owns the key — proceed with the real work.</summary>
    New,

    /// <summary>Same endpoint + same body hash already completed — replay <see cref="StatusCode"/>/<see cref="ResponseBody"/>.</summary>
    Replay,

    /// <summary>A request with the same key is still in flight — 409/idle retry (§6.4).</summary>
    InProgress,

    /// <summary>Same key, different body hash — 409 idempotency_key_conflict.</summary>
    Conflict
}

public sealed record IdempotencyClaim(
    IdempotencyClaimKind Kind,
    int StatusCode = 0,
    string? ResponseBody = null);
