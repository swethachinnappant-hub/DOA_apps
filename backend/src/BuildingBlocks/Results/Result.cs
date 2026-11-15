namespace BuildingBlocks.Results;

/// <summary>Uniform operation error carried through handlers to the RFC 7807 edge (design §13).</summary>
public sealed record Error(string Code, string Message, IReadOnlyDictionary<string, string[]>? Details = null)
{
    public static Error NotFound(string resource, object? key = null) =>
        new("not_found", key is null ? $"{resource} was not found." : $"{resource} '{key}' was not found.");

    public static Error Validation(IReadOnlyDictionary<string, string[]> details, string message = "One or more validation errors occurred.") =>
        new("validation_failed", message, details);

    public static Error Validation(string field, string message) =>
        new("validation_failed", "One or more validation errors occurred.", new Dictionary<string, string[]> { [field] = [message] });

    public static Error Conflict(string message, string code = "conflict") => new(code, message);
    public static Error Forbidden(string message = "You are not allowed to perform this action.") => new("forbidden", message);
    public static Error Unauthorized(string message = "Authentication is required.") => new("unauthorized", message);
    public static Error RuleViolation(string code, string message) => new(code, message);
}

public class Result
{
    public bool IsSuccess { get; }
    public Error? Error { get; }

    protected Result(bool isSuccess, Error? error)
    {
        if (isSuccess && error is not null) throw new InvalidOperationException("A successful result cannot carry an error.");
        if (!isSuccess && error is null) throw new InvalidOperationException("A failed result must carry an error.");
        IsSuccess = isSuccess;
        Error = error;
    }

    public static Result Ok() => new(true, null);
    public static Result Fail(Error error) => new(false, error);
    public static Result<T> Ok<T>(T value) => new(value, true, null);
    public static Result<T> Fail<T>(Error error) => new(default!, false, error);
}

public sealed class Result<T> : Result
{
    public T Value { get; }

    internal Result(T value, bool isSuccess, Error? error) : base(isSuccess, error) => Value = value;

    public static implicit operator Result<T>(T value) => Ok(value);
}
