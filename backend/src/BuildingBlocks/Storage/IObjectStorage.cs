namespace BuildingBlocks.Storage;

/// <summary>
/// Object storage port (design §3.4): S3/MinIO in deployments, local disk in dev —
/// checkout must never depend on it (§20.2).
/// </summary>
public interface IObjectStorage
{
    string Provider { get; }
    string GetPublicUrl(string key);
    Task<string> PresignPutAsync(string key, string contentType, TimeSpan? ttl = null, CancellationToken ct = default);
    Task PutAsync(string key, Stream content, string contentType, CancellationToken ct = default);
    Task DeleteAsync(string key, CancellationToken ct = default);
    Task<bool> ExistsAsync(string key, CancellationToken ct = default);
}

public sealed record PresignedPut(string Url, string Key, IReadOnlyDictionary<string, string> Headers);
