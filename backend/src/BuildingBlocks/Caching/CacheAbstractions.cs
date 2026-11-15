namespace BuildingBlocks.Caching;

/// <summary>
/// Small key-value ticket store for OTPs, email-code throttles and rate-limit
/// buckets: Redis when configured, in-memory otherwise — the API must run without
/// Redis (design §9.1, §20.2 failure table).
/// </summary>
public interface ITicketStore
{
    Task<string?> GetAsync(string key, CancellationToken ct = default);
    Task SetAsync(string key, string value, TimeSpan ttl, CancellationToken ct = default);
    Task<bool> RemoveAsync(string key, CancellationToken ct = default);
}

/// <summary>
/// L1 (memory) + L2 (Redis, when present) cache with tag invalidation and
/// single-flight stampede protection — the perf contract of design §2.4
/// (hot reads p50 &lt; 40 ms) without depending on the HybridCache package.
/// </summary>
public interface ITaggedCache
{
    Task<T?> GetOrCreateAsync<T>(string key, TimeSpan ttl, string[] tags, Func<CancellationToken, Task<T?>> factory, CancellationToken ct = default);
    Task RemoveAsync(string key, CancellationToken ct = default);
    Task InvalidateTagsAsync(params string[] tags);
}
