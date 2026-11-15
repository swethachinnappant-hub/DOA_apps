using System.Diagnostics;
using BuildingBlocks.Errors;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;

namespace BuildingBlocks.Exceptions;

/// <summary>
/// Single RFC 7807 (Problem Details) boundary for the whole Api (design §13.2):
/// DomainException → mapped status + code + errors dictionary, unknown → 500 with
/// traceId. Client-visible contract mirrors the existing Flutter client handlers.
/// </summary>
public sealed class AppExceptionMiddleware(RequestDelegate next, ILogger<AppExceptionMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex) when (!context.Response.HasStarted)
        {
            var problem = Map(ex, context);
            context.Response.StatusCode = problem.Status ?? StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/problem+json";
            context.Response.Headers["X-Trace-Id"] = Activity.Current?.Id ?? context.TraceIdentifier;

            if (problem.Status >= 500)
                logger.LogError(ex, "Unhandled exception for {Method} {Path}", context.Request.Method, context.Request.Path);

            await context.Response.WriteAsJsonAsync(problem, options: null, contentType: "application/problem+json", cancellationToken: context.RequestAborted);
        }
    }

    private static ProblemDetails Map(Exception ex, HttpContext context)
    {
        var traceId = Activity.Current?.Id ?? context.TraceIdentifier;

        if (ex is DomainException domain)
        {
            var problem = new ProblemDetails
            {
                Status = domain.StatusCode,
                Title = TitleFor(domain.StatusCode),
                Detail = domain.Error.Message,
                Type = TypeFor(domain.StatusCode),
                Instance = context.Request.Path
            };
            problem.Extensions["code"] = domain.Error.Code;
            problem.Extensions["traceId"] = traceId;
            if (domain.Error.Details is { Count: > 0 })
                problem.Extensions["errors"] = domain.Error.Details;
            if (domain.ExtraProductIds is { Count: > 0 } ids)
                problem.Extensions["unavailableProductIds"] = ids;
            return problem;
        }

        if (ex is FluentValidation.ValidationException validation)
        {
            var errors = validation.Errors
                .GroupBy(e => string.IsNullOrWhiteSpace(e.PropertyName) ? "request" : e.PropertyName)
                .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());
            var problem = new ProblemDetails
            {
                Status = 422,
                Title = "Unprocessable Entity",
                Detail = "One or more validation errors occurred.",
                Type = "https://tools.ietf.org/html/rfc9110#section-15.5.16",
                Instance = context.Request.Path
            };
            problem.Extensions["code"] = "validation_failed";
            problem.Extensions["errors"] = errors;
            problem.Extensions["traceId"] = traceId;
            return problem;
        }

        if (ex is BadHttpRequestException bad)
        {
            var problem = new ProblemDetails
            {
                Status = bad.StatusCode,
                Title = TitleFor(bad.StatusCode),
                Detail = bad.Message,
                Type = TypeFor(bad.StatusCode),
                Instance = context.Request.Path
            };
            problem.Extensions["code"] = "bad_request";
            problem.Extensions["traceId"] = traceId;
            return problem;
        }

        var fallback = new ProblemDetails
        {
            Status = 500,
            Title = "Internal Server Error",
            Detail = "An unexpected error occurred. Please retry or contact support with the trace id.",
            Type = "https://tools.ietf.org/html/rfc9110#section-15.6.1",
            Instance = context.Request.Path
        };
        fallback.Extensions["code"] = "internal_error";
        fallback.Extensions["traceId"] = traceId;
        return fallback;
    }

    private static string TitleFor(int status) => status switch
    {
        400 => "Bad Request",
        401 => "Unauthorized",
        403 => "Forbidden",
        404 => "Not Found",
        409 => "Conflict",
        422 => "Unprocessable Entity",
        429 => "Too Many Requests",
        >= 500 => "Internal Server Error",
        _ => "Error"
    };

    private static string TypeFor(int status) => status switch
    {
        400 => "https://tools.ietf.org/html/rfc9110#section-15.5.1",
        401 => "https://tools.ietf.org/html/rfc9110#section-15.5.2",
        403 => "https://tools.ietf.org/html/rfc9110#section-15.5.4",
        404 => "https://tools.ietf.org/html/rfc9110#section-15.5.5",
        409 => "https://tools.ietf.org/html/rfc9110#section-15.5.10",
        422 => "https://tools.ietf.org/html/rfc9110#section-15.5.16",
        429 => "https://tools.ietf.org/html/rfc9110#section-15.5.29",
        >= 500 => "https://tools.ietf.org/html/rfc9110#section-15.6.1",
        _ => "about:blank"
    };
}
