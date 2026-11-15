using System.Text;
using BuildingBlocks.Errors;
using BuildingBlocks.Idempotency;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Options;

namespace BuildingBlocks.Idempotency;

/// <summary>
/// Design §6.4 — opt-in per request via the Idempotency-Key header, mandatory on
/// POST /orders and POST /payments/intents (configured required path prefixes).
/// Replay returns the stored status+body; concurrent in-flight → 409; a failed
/// (5xx) or thrown attempt releases the key so a retry can proceed.
/// </summary>
public sealed class IdempotencyMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context, IIdempotencyService service, IOptions<IdempotencyOptions> optionsAccessor)
    {
        var options = optionsAccessor.Value;
        var key = context.Request.Headers["Idempotency-Key"].FirstOrDefault();
        var isPost = HttpMethods.IsPost(context.Request.Method);
        var required = isPost && options.IsRequiredPath(context.Request.Path);

        if (!isPost || (string.IsNullOrWhiteSpace(key) && !required))
        {
            await next(context);
            return;
        }

        if (string.IsNullOrWhiteSpace(key))
            throw DomainException.Validation("Idempotency-Key", "The Idempotency-Key header is required for this endpoint.");
        if (key.Length > 200)
            throw DomainException.Validation("Idempotency-Key", "The Idempotency-Key header must be 200 characters or fewer.");

        // Body must be hashable and replayable downstream.
        context.Request.EnableBuffering();
        string body;
        using (var reader = new StreamReader(context.Request.Body, Encoding.UTF8, leaveOpen: true))
            body = await reader.ReadToEndAsync(context.RequestAborted);
        context.Request.Body.Position = 0;

        var hash = IdempotencyService.HashPayload(context.Request.Method, context.Request.Path.Value ?? "/", body);

        var claim = await service.ClaimAsync(key, hash, context.RequestAborted);

        switch (claim.Kind)
        {
            case IdempotencyClaimKind.Replay:
                context.Response.StatusCode = claim.StatusCode;
                context.Response.ContentType = "application/json";
                context.Response.Headers["Idempotency-Replayed"] = "true";
                await context.Response.WriteAsync(claim.ResponseBody ?? "{}", context.RequestAborted);
                return;

            case IdempotencyClaimKind.InProgress:
                context.Response.StatusCode = StatusCodes.Status409Conflict;
                context.Response.ContentType = "application/problem+json";
                context.Response.Headers["Retry-After"] = "2";
                await context.Response.WriteAsync(
                    """{"type":"https://tools.ietf.org/html/rfc9110#section-15.5.10","title":"Conflict","status":409,"detail":"A request with this Idempotency-Key is still in progress.","code":"idempotency_in_progress"}""",
                    context.RequestAborted);
                return;
        }

        // Kind == New: capture the downstream response so it can be stored + replayed.
        var originalBody = context.Response.Body;
        await using var buffer = new MemoryStream();
        context.Response.Body = buffer;
        var statusCode = 200;
        try
        {
            await next(context);
            statusCode = context.Response.StatusCode;
        }
        catch
        {
            context.Response.Body = originalBody;
            await service.ReleaseAsync(key, CancellationToken.None);
            throw;
        }
        finally
        {
            context.Response.Body = originalBody;
        }

        if (statusCode < 500 && !context.Response.HasStarted)
        {
            buffer.Position = 0;
            using var reader = new StreamReader(buffer, Encoding.UTF8, leaveOpen: true);
            var responseBody = await reader.ReadToEndAsync(CancellationToken.None);
            await service.CompleteAsync(key, statusCode, responseBody, CancellationToken.None);
            buffer.Position = 0;
            await buffer.CopyToAsync(originalBody, CancellationToken.None);
        }
        else if (statusCode >= 500)
        {
            await service.ReleaseAsync(key, CancellationToken.None);
            if (buffer.Length > 0)
            {
                buffer.Position = 0;
                await buffer.CopyToAsync(originalBody, CancellationToken.None);
            }
        }
        else if (buffer.Length > 0)
        {
            buffer.Position = 0;
            await buffer.CopyToAsync(originalBody, CancellationToken.None);
        }
    }
}

public sealed class IdempotencyOptions
{
    /// <summary>Path prefixes where the Idempotency-Key header is mandatory (design §6.4).</summary>
    public string[] RequiredPathPrefixes { get; set; } =
    [
        "/api/v1/orders",
        "/api/v1/payments/intents"
    ];

    public bool IsRequiredPath(PathString path) =>
        RequiredPathPrefixes.Any(p => path.StartsWithSegments(p, StringComparison.OrdinalIgnoreCase));
}
