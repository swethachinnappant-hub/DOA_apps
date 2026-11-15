using System.Collections.Concurrent;
using BuildingBlocks.Caching;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace BuildingBlocks.Caching;

/// <summary>Process-local TTL store — the Redis-free fallback (design §20.2).</summary>
public sealed class MemoryTicketStore : ITicketStore
{
    private sealed record Entry(string Value, DateTimeOffset ExpiresAt);
    private readonly ConcurrentDictionary<string, Entry> _entries = new();
    private readonly TimeProvider _clock;

    public MemoryTicketStore(TimeProvider clock) => _clock = clock;

    public Task<string?> GetAsync(string key, CancellationToken ct = default)
    {
        if (_entries.TryGetValue(key, out var entry))
        {
            if (entry.ExpiresAt > _clock.GetUtcNow()) return Task.FromResult<string?>(entry.Value);
            _entries.TryRemove(key, out _);
        }
        return Task.FromResult<string?>(null);
    }

    public Task SetAsync(string key, string value, TimeSpan ttl, CancellationToken ct = default)
    {
        _entries[key] = new Entry(value, _clock.GetUtcNow().Add(ttl));
        return Task.CompletedTask;
    }

    public Task<bool> RemoveAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(_entries.TryRemove(key, out _));
}

/// <summary>Redis ticket store used for OTPs + rate buckets when Redis is configured.</summary>
public sealed class RedisTicketStore(IConnectionMultiplexer redis) : ITicketStore
{
    public async Task<string?> GetAsync(string key, CancellationToken ct = default)
    {
        var value = await redis.GetDatabase().StringGetAsync(key);
        return value.IsNull ? null : value.ToString();
    }

    public Task SetAsync(string key, string value, TimeSpan ttl, CancellationToken ct = default) =>
        redis.GetDatabase().StringSetAsync(key, value, ttl);

    public Task<bool> RemoveAsync(string key, CancellationToken ct = default) =>
        redis.GetDatabase().KeyDeleteAsync(key);
}

/// <summary>
/// L1 memory + optional L2 Redis, per-tag key sets and single-flight stampede
/// protection (design §2.4 hot-read budget).
/// </summary>
public sealed class TaggedCache : ITaggedCache, IDisposable
{
    private readonly IMemoryCache _l1;
    private readonly IConnectionMultiplexer? _redis;
    private readonly TimeProvider _clock;
    private readonly ILogger<TaggedCache> _logger;
    private readonly ConcurrentDictionary<string, SemaphoreSlim> _inflight = new();
    private readonly ConcurrentDictionary<string, HashSet<string>> _taggedKeys = new();
    private readonly object _tagLock = new();

    public TaggedCache(IMemoryCache l1, IConnectionMultiplexer? redis, TimeProvider clock, ILogger<TaggedCache> logger)
    {
        _l1 = l1;
        _redis = redis;
        _clock = clock;
        _logger = logger;
    }

    public async Task<T?> GetOrCreateAsync<T>(string key, TimeSpan ttl, string[] tags, Func<CancellationToken, Task<T?>> factory, CancellationToken ct = default)
    {
        if (TryGet(key, out T? cached)) return cached;

        // L2 read-through before computing (design §2.4: L1 miss → L2 → source).
        if (_redis is not null)
        {
            try
            {
                var raw = await _redis.GetDatabase().StringGetAsync(key);
                if (!raw.IsNull)
                {
                    var fromL2 = System.Text.Json.JsonSerializer.Deserialize<T>(raw.ToString()!);
                    if (fromL2 is not null)
                    {
                        _l1.Set(key, new CacheItem(fromL2, _clock.GetUtcNow().Add(ttl), tags), new MemoryCacheEntryOptions
                        {
                            AbsoluteExpiration = _clock.GetUtcNow().Add(ttl)
                        });
                        RememberTags(key, tags);
                        return fromL2;
                    }
                }
            }
            catch (RedisException ex)
            {
                _logger.LogWarning(ex, "L2 cache read failed for {Key} — falling through to source", key);
            }
        }

        var gate = _inflight.GetOrAdd(key, _ => new SemaphoreSlim(1, 1));
        await gate.WaitAsync(ct);
        try
        {
            if (TryGet(key, out cached)) return cached;

            var created = await factory(ct);
            if (created is not null)
            {
                var l1Item = new CacheItem(created, _clock.GetUtcNow().Add(ttl), tags);
                _l1.Set(key, l1Item, new MemoryCacheEntryOptions
                {
                    AbsoluteExpiration = _clock.GetUtcNow().Add(ttl)
                });
                RememberTags(key, tags);
                if (_redis is not null)
                {
                    try
                    {
                        await _redis.GetDatabase().StringSetAsync(key, Serialize(created), ttl);
                        foreach (var tag in tags)
                        {
                            var tagSet = TagSet(tag);
                            await _redis.GetDatabase().SetAddAsync(tagSet, key);
                            await _redis.GetDatabase().KeyExpireAsync(tagSet, ttl.Add(ttl));
                        }
                    }
                    catch (RedisException ex)
                    {
                        _logger.LogWarning(ex, "L2 cache write failed for {Key} — serving L1", key);
                    }
                }
            }
            return created;
        }
        finally
        {
            gate.Release();
            _inflight.TryRemove(key, out _);
        }
    }

    public Task RemoveAsync(string key, CancellationToken ct = default)
    {
        _l1.Remove(key);
        if (_redis is not null)
            return _redis.GetDatabase().KeyDeleteAsync(key);
        return Task.CompletedTask;
    }

    public async Task InvalidateTagsAsync(params string[] tags)
    {
        lock (_tagLock)
        {
            foreach (var tag in tags)
            {
                if (_taggedKeys.TryRemove(tag, out var keys))
                    foreach (var key in keys) _l1.Remove(key);
            }
        }
        if (_redis is null) return;
        foreach (var tag in tags)
        {
            try
            {
                var db = _redis.GetDatabase();
                var members = await db.SetMembersAsync(TagSet(tag));
                if (members.Length > 0)
                {
                    var keys = members.Select(m => (RedisKey)m.ToString()!).ToArray();
                    await db.KeyDeleteAsync(keys);
                }
                await db.KeyDeleteAsync(TagSet(tag));
            }
            catch (RedisException ex)
            {
                _logger.LogWarning(ex, "L2 tag invalidation failed for {Tag}", tag);
            }
        }
    }

    private static string TagSet(string tag) => $"tagset:{tag}";

    private bool TryGet<T>(string key, out T? value)
    {
        if (_l1.TryGetValue(key, out var item) && item is CacheItem ci && ci.ExpiresAt > _clock.GetUtcNow())
        {
            value = (T?)ci.Value;
            return true;
        }
        value = default;
        return false;
    }

    private void RememberTags(string key, string[] tags)
    {
        lock (_tagLock)
        {
            foreach (var tag in tags)
            {
                var set = _taggedKeys.GetOrAdd(tag, _ => new HashSet<string>(StringComparer.Ordinal));
                set.Add(key);
            }
        }
    }

    private static string? Serialize<T>(T value) => value is null ? null : System.Text.Json.JsonSerializer.Serialize(value);

    private sealed record CacheItem(object Value, DateTimeOffset ExpiresAt, string[] Tags);

    public void Dispose()
    {
        foreach (var gate in _inflight.Values) gate.Dispose();
        _inflight.Clear();
    }
}
