using Amazon;
using Amazon.S3;
using Amazon.S3.Model;
using Amazon.S3.Util;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace BuildingBlocks.Storage;

public sealed class StorageOptions
{
    /// <summary>"s3" or "local" — local writes to disk and is served by the Api at /media (dev, design §3.4).</summary>
    public string Provider { get; set; } = "local";
    public string Bucket { get; set; } = "jewelry-media";
    public string? ServiceUrl { get; set; }            // MinIO: http://localhost:9000
    public string? AccessKey { get; set; }
    public string? SecretKey { get; set; }
    public string? Region { get; set; } = "us-east-1";
    public string? PublicBaseUrl { get; set; }          // cdn base or http://localhost:5000/media
    public bool ForcePathStyle { get; set; } = true;    // MinIO requires path-style
    public string LocalRoot { get; set; } = "App_Data/media";
}

public sealed class S3ObjectStorage(IOptions<StorageOptions> options, TimeProvider clock, ILogger<S3ObjectStorage> logger) : IObjectStorage
{
    private readonly StorageOptions _options = options.Value;
    private AmazonS3Client? _client;
    private readonly SemaphoreSlim _initLock = new(1, 1);

    public string Provider => "s3";

    private async Task<AmazonS3Client> GetClientAsync(CancellationToken ct)
    {
        if (_client is not null) return _client;
        await _initLock.WaitAsync(ct);
        try
        {
            if (_client is not null) return _client;
            var config = new AmazonS3Config
            {
                ForcePathStyle = _options.ForcePathStyle,
                AuthenticationRegion = _options.Region
            };
            if (!string.IsNullOrWhiteSpace(_options.ServiceUrl))
                config.ServiceURL = _options.ServiceUrl;
            _client = new AmazonS3Client(_options.AccessKey, _options.SecretKey, config);
            return _client;
        }
        finally
        {
            _initLock.Release();
        }
    }

    public string GetPublicUrl(string key) =>
        string.IsNullOrWhiteSpace(_options.PublicBaseUrl)
            ? $"https://{_options.Bucket}.s3.{_options.Region}.amazonaws.com/{key}"
            : $"{_options.PublicBaseUrl.TrimEnd('/')}/{key}";

    public async Task<string> PresignPutAsync(string key, string contentType, TimeSpan? ttl = null, CancellationToken ct = default)
    {
        var client = await GetClientAsync(ct);
        var request = new GetPreSignedUrlRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            Verb = HttpVerb.PUT,
            Expires = clock.GetUtcNow().UtcDateTime.Add(ttl ?? TimeSpan.FromMinutes(15)),
            ContentType = contentType
        };
        return await Task.FromResult(client.GetPreSignedURL(request));
    }

    public async Task PutAsync(string key, Stream content, string contentType, CancellationToken ct = default)
    {
        var client = await GetClientAsync(ct);
        var put = new PutObjectRequest
        {
            BucketName = _options.Bucket,
            Key = key,
            InputStream = content,
            ContentType = contentType,
            AutoCloseStream = false
        };
        var response = await client.PutObjectAsync(put, ct);
        if (response.HttpStatusCode is not (System.Net.HttpStatusCode.OK or System.Net.HttpStatusCode.Created))
            logger.LogError("S3 PUT {Key} returned {Status}", key, response.HttpStatusCode);
    }

    public async Task DeleteAsync(string key, CancellationToken ct = default)
    {
        try
        {
            var client = await GetClientAsync(ct);
            await client.DeleteObjectAsync(_options.Bucket, key, ct);
        }
        catch (AmazonS3Exception ex)
        {
            logger.LogWarning(ex, "S3 DELETE {Key} failed", key);
        }
    }

    public async Task<bool> ExistsAsync(string key, CancellationToken ct = default)
    {
        try
        {
            var client = await GetClientAsync(ct);
            await client.GetObjectMetadataAsync(_options.Bucket, key, ct);
            return true;
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return false;
        }
    }

    public async Task DownloadIntoAsync(string key, Stream destination, CancellationToken ct = default)
    {
        var client = await GetClientAsync(ct);
        try
        {
            using var response = await client.GetObjectAsync(_options.Bucket, key, ct);
            await response.ResponseStream.CopyToAsync(destination, ct);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            throw Errors.DomainException.NotFound("Media object", key);
        }
    }
}

/// <summary>Local-disk fallback for dev without MinIO (design §3.4).</summary>
public sealed class LocalDiskObjectStorage(IOptions<StorageOptions> options) : IObjectStorage
{
    private readonly StorageOptions _options = options.Value;

    public string Provider => "local";

    private string Resolve(string key)
    {
        var relative = key.Replace('\\', '/').TrimStart('/');
        if (relative.Contains("..") || Path.IsPathRooted(relative))
            throw new ArgumentException("Invalid object key.", nameof(key));
        return Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, _options.LocalRoot, relative));
    }

    public string GetPublicUrl(string key) =>
        string.IsNullOrWhiteSpace(_options.PublicBaseUrl)
            ? $"/media/{key.TrimStart('/')}"
            : $"{_options.PublicBaseUrl.TrimEnd('/')}/{key.TrimStart('/')}";

    public Task<string> PresignPutAsync(string key, string contentType, TimeSpan? ttl = null, CancellationToken ct = default) =>
        // Local provider has no real presign — the Api accepts direct uploads at the same key (dev only).
        Task.FromResult(GetPublicUrl(key));

    public async Task PutAsync(string key, Stream content, string contentType, CancellationToken ct = default)
    {
        var path = Resolve(key);
        Directory.CreateDirectory(Path.GetDirectoryName(path)!);
        await using var file = File.Create(path);
        await content.CopyToAsync(file, ct);
    }

    public async Task DeleteAsync(string key, CancellationToken ct = default)
    {
        var path = Resolve(key);
        if (File.Exists(path)) File.Delete(path);
        await Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(string key, CancellationToken ct = default) =>
        Task.FromResult(File.Exists(Resolve(key)));
}
