using BuildingBlocks.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace BuildingBlocks.Media;

using static Microsoft.AspNetCore.Http.Results;

public sealed record StartMediaUploadRequest(
    string Purpose,
    string FileName,
    string ContentType,
    long Bytes);

public sealed record CompleteMediaUploadRequest(Guid Id);

/// <summary>Authenticated upload-slot endpoints. Files go directly to object storage.</summary>
public static class MediaEndpoints
{
    public static IEndpointRouteBuilder MapMediaEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var group = endpoints.MapGroup("/api/v1/media").RequireAuthorization();
        group.MapPost("/upload", async Task<IResult> (
            StartMediaUploadRequest request,
            ICurrentUser current,
            IMediaService media,
            CancellationToken ct) =>
        {
            var purpose = request.Purpose.Trim().ToLowerInvariant();
            if (purpose is "product" or "category" or "collection" or "hero")
            {
                if (!current.IsSeller && !current.IsAdmin) return Forbid();
            }
            else if (purpose == "kyc")
            {
                if (!current.IsAuthenticated) return Forbid();
            }
            else if (purpose == "invoice")
            {
                if (!current.IsAdmin && !current.IsSeller) return Forbid();
            }

            var sellerId = current.IsSeller ? current.SellerId : null;
            var isPrivate = purpose is "kyc" or "invoice";
            var (asset, uploadUrl) = await media.StartUploadAsync(
                purpose, request.FileName, request.ContentType, request.Bytes,
                sellerId, isPrivate, ct);
            return Created($"/api/v1/media/{asset.Id}", new
            {
                id = asset.Id,
                status = asset.Status,
                uploadUrl,
                contentType = asset.ContentType
            });
        });

        group.MapPost("/upload/complete", async Task<IResult> (
            CompleteMediaUploadRequest request,
            ICurrentUser current,
            IMediaService media,
            CancellationToken ct) =>
        {
            var asset = await media.GetAsync(request.Id, ct)
                ?? throw new KeyNotFoundException("Media asset not found");
            if (!current.IsAdmin && asset.UploadedBy != current.UserId &&
                (asset.SellerId is null || asset.SellerId != current.SellerId))
                return Forbid();

            var processed = await media.ProcessAsync(request.Id, ct);
            if (processed.Status == "ready")
                return Ok(new { id = processed.Id, status = processed.Status, variants = processed.Variants });
            return Problem(statusCode: 422, detail: "Unprocessable entity");
        });

        group.MapGet("/{id:guid}", async Task<IResult> (Guid id, ICurrentUser current, IMediaService media, CancellationToken ct) =>
        {
            var asset = await media.GetAsync(id, ct);
            if (asset is null) return NotFound();
            if (!current.IsAdmin && asset.UploadedBy != current.UserId && asset.SellerId != current.SellerId)
                return Forbid();
            return Ok(new { id = asset.Id, status = asset.Status, variants = asset.Variants });
        });

        return endpoints;
    }
}