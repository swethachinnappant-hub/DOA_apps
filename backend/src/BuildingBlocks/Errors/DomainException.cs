using BuildingBlocks.Results;

namespace BuildingBlocks.Errors;

/// <summary>
/// Domain/application failure carrying an RFC 7807 error and the HTTP status the
/// exception middleware should render (design §13.2).
/// </summary>
public class DomainException : Exception
{
    public Error Error { get; }
    public int StatusCode { get; }

    public DomainException(Error error, int statusCode = 422) : base(error.Message)
    {
        Error = error;
        StatusCode = statusCode;
    }

    public static DomainException NotFound(string resource, object? key = null) =>
        new(Error.NotFound(resource, key), 404);

    public static DomainException Validation(string field, string message) =>
        new(Error.Validation(field, message), 422);

    public static DomainException Validation(IReadOnlyDictionary<string, string[]> details) =>
        new(Error.Validation(details), 422);

    public static DomainException Conflict(string message, string code = "conflict") =>
        new(Error.Conflict(message, code), 409);

    /// <summary>Stock conflict (409) listing the unavailable product ids — design §6.3 step 7.</summary>
    public static DomainException StockConflict(IEnumerable<Guid> productIds) =>
        new(Error.Conflict(
            "One or more items are no longer available.",
            "stock_conflict"), 409) { ExtraProductIds = productIds.ToList() };

    public static DomainException Forbidden(string message = "You are not allowed to perform this action.") =>
        new(Error.Forbidden(message), 403);

    public static DomainException Unauthorized(string message = "Authentication is required.") =>
        new(Error.Unauthorized(message), 401);

    public static DomainException RuleViolation(string code, string message) =>
        new(Error.RuleViolation(code, message), 422);

    public static DomainException TooManyRequests(string message = "Too many requests. Please retry later.") =>
        new(new Error("rate_limited", message), 429);

    public IReadOnlyList<Guid>? ExtraProductIds { get; init; }
}

public sealed class OutOfStockException(IReadOnlyList<Guid> productIds)
    : DomainException(Error.Conflict("One or more items are no longer available.", "stock_conflict"), 409)
{
    public IReadOnlyList<Guid> ProductIds { get; } = productIds;
}
