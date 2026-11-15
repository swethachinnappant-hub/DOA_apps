using FluentValidation;

namespace Identity.Auth;

// ── Requests ──────────────────────────────────────────────────────────────────

public sealed record RegisterRequest(
    string Role, string Name, string Email, string Phone, string Password,
    string? ShopName, string? GstIn, string? StateCode);

public sealed record LoginRequest(string Identifier, string Password);
public sealed record OtpRequest(string Phone);
public sealed record OtpVerifyRequest(string Phone, string Code);
public sealed record RefreshRequest(string RefreshToken, string? DeviceId);
public sealed record LogoutRequest(string RefreshToken);
public sealed record ForgotPasswordRequest(string Email);
public sealed record ResetPasswordRequest(string Email, string Code, string NewPassword);

public sealed record UpdateProfileRequest(string? Name, string? Phone);

public sealed record AddressRequest(
    Guid? Id, string? Label, string ContactName, string Phone,
    string Line1, string? Line2, string City, string State, string StateCode,
    string Pincode, string? GstIn, bool IsDefault);

public sealed record DeviceRequest(string Token, string Platform);

public sealed record BuyerProfileUpsertRequest(string BusinessName, string? GstIn, string? Pan, Guid[]? KycMediaIds);

// ── Responses ─────────────────────────────────────────────────────────────────

public sealed record AuthUserDto(
    Guid Id, string Name, string Email, string Phone, string Role,
    Guid? SellerId, Guid TenantId, DateTime CreatedAt);

public sealed record MeDto(
    Guid Id, string Name, string Email, string Phone, string Role,
    Guid? SellerId, Guid TenantId, DateTime? PhoneVerifiedAt, DateTime CreatedAt);

public sealed record TokenResponse(
    string AccessToken, string RefreshToken, int ExpiresInSeconds, AuthUserDto User);

public sealed record AddressDto(
    Guid Id, string? Label, string ContactName, string Phone,
    string Line1, string? Line2, string City, string State, string StateCode,
    string Pincode, string? GstIn, bool IsDefault);

public sealed record BuyerProfileDto(
    Guid UserId, string BusinessName, string? GstIn, string? Pan, string KycStatus,
    Guid[] KycMediaIds, long CreditLimitMinor, int PaymentTermsDays);

// ── Validators ────────────────────────────────────────────────────────────────

public sealed class RegisterRequestValidator : AbstractValidator<RegisterRequest>
{
    public RegisterRequestValidator()
    {
        RuleFor(x => x.Role).Must(r => r is "customer" or "seller_owner")
            .WithMessage("Role must be 'customer' or 'seller_owner'.");
        RuleFor(x => x.Name).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Email).NotEmpty().EmailAddress().MaximumLength(320);
        RuleFor(x => x.Phone).NotEmpty().Matches(@"^\+?[0-9]{8,15}$").WithMessage("Phone must be in E.164 format.");
        RuleFor(x => x.Password).NotEmpty().MinimumLength(8).MaximumLength(200);
        When(x => x.Role == "seller_owner", () =>
        {
            RuleFor(x => x.ShopName).NotEmpty().WithMessage("Shop name is required to register a shop.")
                .MaximumLength(300);
            RuleFor(x => x.StateCode).NotEmpty().WithMessage("State code is required (GST place of supply).")
                .Length(2).WithMessage("State code must be 2 characters.");
        });
    }
}

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Identifier).NotEmpty().MaximumLength(320);
        RuleFor(x => x.Password).NotEmpty();
    }
}

public sealed class OtpRequestValidator : AbstractValidator<OtpRequest>
{
    public OtpRequestValidator() =>
        RuleFor(x => x.Phone).NotEmpty().Matches(@"^\+?[0-9]{8,15}$").WithMessage("Phone must be in E.164 format.");
}

public sealed class OtpVerifyRequestValidator : AbstractValidator<OtpVerifyRequest>
{
    public OtpVerifyRequestValidator()
    {
        RuleFor(x => x.Phone).NotEmpty().Matches(@"^\+?[0-9]{8,15}$");
        RuleFor(x => x.Code).NotEmpty().Matches(@"^\d{6}$").WithMessage("Code must be 6 digits.");
    }
}

public sealed class RefreshRequestValidator : AbstractValidator<RefreshRequest>
{
    public RefreshRequestValidator() => RuleFor(x => x.RefreshToken).NotEmpty();
}

public sealed class LogoutRequestValidator : AbstractValidator<LogoutRequest>
{
    public LogoutRequestValidator() => RuleFor(x => x.RefreshToken).NotEmpty();
}

public sealed class ForgotPasswordRequestValidator : AbstractValidator<ForgotPasswordRequest>
{
    public ForgotPasswordRequestValidator() => RuleFor(x => x.Email).NotEmpty().EmailAddress();
}

public sealed class ResetPasswordRequestValidator : AbstractValidator<ResetPasswordRequest>
{
    public ResetPasswordRequestValidator()
    {
        RuleFor(x => x.Email).NotEmpty().EmailAddress();
        RuleFor(x => x.Code).NotEmpty().Matches(@"^\d{6}$");
        RuleFor(x => x.NewPassword).NotEmpty().MinimumLength(8).MaximumLength(200);
    }
}

public sealed class AddressRequestValidator : AbstractValidator<AddressRequest>
{
    public AddressRequestValidator()
    {
        RuleFor(x => x.ContactName).NotEmpty().MaximumLength(200);
        RuleFor(x => x.Phone).NotEmpty().Matches(@"^\+?[0-9]{8,15}$");
        RuleFor(x => x.Line1).NotEmpty().MaximumLength(300);
        RuleFor(x => x.Line2).MaximumLength(300);
        RuleFor(x => x.City).NotEmpty().MaximumLength(120);
        RuleFor(x => x.State).NotEmpty().MaximumLength(120);
        RuleFor(x => x.StateCode).NotEmpty().Length(2);
        RuleFor(x => x.Pincode).NotEmpty().Matches(@"^\d{6}$").WithMessage("Pincode must be 6 digits.");
        When(x => x.GstIn is not null, () =>
            RuleFor(x => x.GstIn!).Matches(@"^\d{2}[A-Z]{5}\d{4}[A-Z]\d[A-Z]Z[A-Z\d]$")
                .WithMessage("GSTIN format is invalid."));
    }
}

public static class ValidationExtensions
{
    public static async Task EnsureValidAsync<T>(this IValidator<T> validator, T instance, CancellationToken ct)
    {
        var result = await validator.ValidateAsync(instance, ct);
        if (result.IsValid) return;
        var errors = result.Errors
            .GroupBy(e => string.IsNullOrWhiteSpace(e.PropertyName) ? "request" : e.PropertyName)
            .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());
        throw BuildingBlocks.Errors.DomainException.Validation(errors);
    }
}
