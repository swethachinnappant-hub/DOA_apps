using System.Security.Cryptography;
using System.Text.Json;
using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Errors;
using BuildingBlocks.Security;
using BuildingBlocks.Storage;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Processing;

namespace BuildingBlocks.Media;

public sealed class MediaOptions
{
    public int[] Widths { get; set; } = [400, 800, 1600];
    public long MaxBytes { get; set; } = 10 * 1024 * 1024;
    public long MaxPixels { get; set; } = 50_000_000; // decompression-bomb guard
    public string[] AllowedContentTypes { get; set; } = ["image/jpeg", "image/png", "image/webp"];
    public string[] AllowedPurposes { get; set; } = ["product", "category", "hero", "collection", "invoice", "kyc"];
}

/// <summary>
/// Upload slots + variant rendering (design §3.4/§10): the row is created with
/// status 'processing' and a presigned PUT; processing validates the object,
/// strips EXIF, renders thumb/medium/large WebP with JPEG fallback, then flips
/// to 'ready'. Product linking lives in catalog.product_images (media_id).
/// </summary>
public interface IMediaService
{
    Task<(MediaAsset Asset, string UploadUrl)> StartUploadAsync(
        string purpose, string fileName, string contentType, long bytes,
        Guid? sellerId = null, bool isPrivate = false, CancellationToken ct = default);

    Task<MediaAsset> ProcessAsync(Guid assetId, CancellationToken ct = default);
    Task<MediaAsset?> GetAsync(Guid assetId, CancellationToken ct = default);
}

public sealed class MediaService(
    PlatformDbContext platform,
    IObjectStorage storage,
    IOptions<MediaOptions> options,
    ICurrentUser current,
    ITenantContext tenant,
    TimeProvider clock,
    ILogger<MediaService> logger) : IMediaService
{
    private readonly MediaOptions _options = options.Value;

    private static readonly string[] VariantNames = ["thumb", "medium", "large"];

    public async Task<(MediaAsset Asset, string UploadUrl)> StartUploadAsync(
        string purpose, string fileName, string contentType, long bytes,
        Guid? sellerId = null, bool isPrivate = false, CancellationToken ct = default)
    {
        if (!_options.AllowedPurposes.Contains(purpose, StringComparer.OrdinalIgnoreCase))
            throw DomainException.Validation("purpose", $"Purpose must be one of: {string.Join(", ", _options.AllowedPurposes)}.");
        if (!_options.AllowedContentTypes.Contains(contentType, StringComparer.OrdinalIgnoreCase))
            throw DomainException.Validation("content_type", $"Content type must be one of: {string.Join(", ", _options.AllowedContentTypes)}.");
        if (bytes <= 0 || bytes > _options.MaxBytes)
            throw DomainException.Validation("file_size", $"File must be between 1 byte and {_options.MaxBytes / (1024 * 1024)} MB.");
        if (!tenant.HasTenant)
            throw new InvalidOperationException("Uploads require a tenant context.");

        var now = clock.GetUtcNow().UtcDateTime;
        var key = $"{Sanitize(purpose)}/{now:yyyy}/{MM(now)}/{Guid.CreateVersion7():N}/{Sanitize(fileName)}";

        var asset = new MediaAsset
        {
            Id = Guid.CreateVersion7(),
            TenantId = tenant.TenantId,
            SellerId = sellerId,
            UploadedBy = current.IsAuthenticated && current.UserId != Guid.Empty ? current.UserId : null,
            Purpose = purpose.ToLowerInvariant(),
            StorageKey = key,
            ContentType = contentType,
            Bytes = bytes,
            Status = "processing",
            IsPrivate = isPrivate,
            CreatedAt = now
        };
        platform.MediaAssets.Add(asset);
        await platform.SaveChangesAsync(ct);

        var url = await storage.PresignPutAsync(key, contentType, ct: ct);
        return (asset, url);
    }

    public async Task<MediaAsset> ProcessAsync(Guid assetId, CancellationToken ct = default)
    {
        var asset = await platform.MediaAssets.FirstOrDefaultAsync(
            a => a.Id == assetId && a.TenantId == tenant.TenantId, ct)
            ?? throw DomainException.NotFound("Media asset", assetId);

        try
        {
            await using var source = new MemoryStream();
            await storage.GetIntoAsync(asset.StorageKey, source, ct);
            asset.Sha256 = SHA256.HashData(source.ToArray());
            source.Position = 0;

            Image image;
            try
            {
                image = Image.Load(source);
            }
            catch (UnknownImageFormatException)
            {
                throw DomainException.Validation("content_type", "The uploaded file is not a supported image.");
            }

            using (image)
            {
                if ((long)image.Width * image.Height > _options.MaxPixels)
                    throw DomainException.Validation("image_dimensions",
                        $"Image exceeds {_options.MaxPixels / 1_000_000} megapixels.");

                asset.Width = image.Width;
                asset.Height = image.Height;

                var variants = new Dictionary<string, string>();
                for (var i = 0; i < _options.Widths.Length; i++)
                {
                    var width = _options.Widths[i];
                    var name = i < VariantNames.Length ? VariantNames[i] : $"w{width}";

                    source.Position = 0;
                    var webpKey = VariantKey(asset.StorageKey, width, "webp");
                    using (var rendered = await RenderVariantAsync(source, width, ct))
                    using (var buffer = new MemoryStream())
                    {
                        await rendered.SaveAsync(buffer, new SixLabors.ImageSharp.Formats.Webp.WebpEncoder { Quality = 82 }, ct);
                        buffer.Position = 0;
                        await storage.PutAsync(webpKey, buffer, "image/webp", ct);
                    }
                    variants[name] = asset.IsPrivate ? webpKey : storage.GetPublicUrl(webpKey);

                    source.Position = 0;
                    var jpgKey = VariantKey(asset.StorageKey, width, "jpg");
                    using (var rendered = await RenderVariantAsync(source, width, ct))
                    using (var buffer = new MemoryStream())
                    {
                        await rendered.SaveAsync(buffer, new SixLabors.ImageSharp.Formats.Jpeg.JpegEncoder { Quality = 85 }, ct);
                        buffer.Position = 0;
                        await storage.PutAsync(jpgKey, buffer, "image/jpeg", ct);
                    }
                    variants[$"{name}_jpg"] = asset.IsPrivate ? jpgKey : storage.GetPublicUrl(jpgKey);
                }

                asset.Variants = JsonSerializer.Serialize(variants);
                asset.Status = "ready";
            }
        }
        catch (Exception ex) when (ex is not DomainException and not OperationCanceledException)
        {
            logger.LogError(ex, "Media processing failed for asset {AssetId}", assetId);
            asset.Status = "failed";
        }

        await platform.SaveChangesAsync(ct);
        return asset;
    }

    public Task<MediaAsset?> GetAsync(Guid assetId, CancellationToken ct = default) =>
        platform.MediaAssets.AsNoTracking()
            .FirstOrDefaultAsync(a => a.Id == assetId && a.TenantId == tenant.TenantId, ct);

    private static async Task<Image> RenderVariantAsync(Stream source, int width, CancellationToken ct)
    {
        var image = Image.Load(source);
        image.Metadata.ExifProfile = null;
        image.Metadata.XmpProfile = null;
        image.Metadata.IptcProfile = null;
        if (image.Width > width)
            image.Mutate(x => x.Resize(width, 0));
        await Task.CompletedTask;
        return image;
    }

    private static string VariantKey(string originalKey, int width, string ext)
    {
        var directory = Path.GetDirectoryName(originalKey)?.Replace('\\', '/') ?? "";
        var stem = Path.GetFileNameWithoutExtension(originalKey);
        return $"{directory}/{stem}_{width}.{ext}";
    }

    private static string Sanitize(string value)
    {
        var invalid = Path.GetInvalidFileNameChars();
        var cleaned = new string(value.Select(c => invalid.Contains(c) || c is ' ' or '\\' ? '_' : c).ToArray()).Trim('_');
        return string.IsNullOrWhiteSpace(cleaned) ? "file" : Truncate(cleaned, 120);
    }

    private static string Truncate(string value, int max) => value.Length <= max ? value : value[..max];
    private static int MM(DateTime d) => d.Month;
}

public static class ObjectStorageReadExtensions
{
    public static async Task GetIntoAsync(this IObjectStorage storage, string key, Stream destination, CancellationToken ct = default)
    {
        if (storage is S3ObjectStorage s3) { await s3.DownloadIntoAsync(key, destination, ct); return; }
        // Local disk provider.
        var local = Path.Combine(AppContext.BaseDirectory, "App_Data/media", key.TrimStart('/'));
        if (!File.Exists(local)) throw DomainException.NotFound("Media object", key);
        await using var file = File.OpenRead(local);
        await file.CopyToAsync(destination, ct);
    }
}
