using FluentValidation;
using Identity.Accounts;
using Identity.Auth;
using Identity.Tokens;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace Identity.Endpoints;

/// <summary>Design §7.1 — auth endpoints (anonymous) + account endpoints (authenticated).</summary>
public static class IdentityEndpoints
{
    public static IEndpointRouteBuilder MapIdentityEndpoints(this IEndpointRouteBuilder endpoints, bool demoEnabled)
    {
        MapAuth(endpoints, demoEnabled);
        MapAccount(endpoints);
        MapBuyer(endpoints);
        return endpoints;
    }

    private static void MapAuth(IEndpointRouteBuilder endpoints, bool demoEnabled)
    {
        var g = endpoints.MapGroup("/api/v1/auth");

        g.MapPost("/register", async (
            RegisterRequest body, IValidator<RegisterRequest> validator, AuthService auth,
            HttpContext ctx, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            var (device, ua, ip) = ClientInfo(ctx);
            return Results.Ok(await auth.RegisterAsync(body, device, ua, ip, ct));
        });

        g.MapPost("/login", async (
            LoginRequest body, IValidator<LoginRequest> validator, AuthService auth,
            HttpContext ctx, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            var (device, ua, ip) = ClientInfo(ctx);
            return Results.Ok(await auth.LoginAsync(body, device, ua, ip, ct));
        });

        g.MapPost("/otp/request", async (
            OtpRequest body, IValidator<OtpRequest> validator, IOtpService otp,
            HttpContext ctx, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            await otp.IssueAsync(AuthService.NormalizePhone(body.Phone), ctx.Connection.RemoteIpAddress?.ToString(), ct);
            return Results.Accepted(value: new { status = "sent" });
        });

        g.MapPost("/otp/verify", async (
            OtpVerifyRequest body, IValidator<OtpVerifyRequest> validator, AuthService auth,
            HttpContext ctx, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            var (device, ua, ip) = ClientInfo(ctx);
            return Results.Ok(await auth.VerifyOtpAsync(body, device, ua, ip, ct));
        });

        g.MapPost("/refresh", async (
            RefreshRequest body, IValidator<RefreshRequest> validator, AuthService auth,
            HttpContext ctx, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            var ua = ctx.Request.Headers.UserAgent.ToString();
            var ip = ctx.Connection.RemoteIpAddress?.ToString();
            return Results.Ok(await auth.RefreshAsync(body with { DeviceId = body.DeviceId ?? ctx.Request.Headers["X-Device-Id"].FirstOrDefault() }, ua, ip, ct));
        });

        g.MapPost("/logout", async (
            LogoutRequest body, IValidator<LogoutRequest> validator, AuthService auth, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            await auth.LogoutAsync(body.RefreshToken, ct);
            return Results.Ok(new { status = "ok" });
        });

        g.MapPost("/forgot-password", async (
            ForgotPasswordRequest body, IValidator<ForgotPasswordRequest> validator, AuthService auth, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            await auth.ForgotPasswordAsync(body.Email, ct);
            return Results.Accepted(value: new { status = "accepted" });
        });

        g.MapPost("/reset-password", async (
            ResetPasswordRequest body, IValidator<ResetPasswordRequest> validator, AuthService auth, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            await auth.ResetPasswordAsync(body, ct);
            return Results.Ok(new { status = "ok" });
        });

        if (demoEnabled)
        {
            g.MapPost("/demo", async (AuthService auth, HttpContext ctx, CancellationToken ct) =>
            {
                var (device, ua, ip) = ClientInfo(ctx);
                return Results.Ok(await auth.DemoLoginAsync(device, ua, ip, ct));
            });
        }

        g.MapGet("/jwks", (Tokens.RsaKeyProvider keys) => Results.Ok(keys.CreateJwks()));
    }

    private static void MapAccount(IEndpointRouteBuilder endpoints)
    {
        var me = endpoints.MapGroup("/api/v1/me").RequireAuthorization();

        me.MapGet("", (AccountService account, CancellationToken ct) => account.GetMeDtoAsync(ct));

        me.MapPatch("", async (UpdateProfileRequest body, AccountService account, CancellationToken ct) =>
        {
            if (body.Name is null && body.Phone is null)
                throw BuildingBlocks.Errors.DomainException.Validation("request", "Provide at least one field to update.");
            return await account.PatchMeAsync(body, ct);
        });

        me.MapGet("/addresses", (AccountService account, CancellationToken ct) => account.ListAddressesAsync(ct));

        me.MapPost("/addresses", async (AddressRequest body, IValidator<AddressRequest> validator, AccountService account, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            if (body.Id is not null)
                throw BuildingBlocks.Errors.DomainException.Validation("id", "Remove the id when creating an address.");
            return Results.Ok(await account.UpsertAddressAsync(body, ct));
        });

        me.MapPut("/addresses", async (AddressRequest body, IValidator<AddressRequest> validator, AccountService account, CancellationToken ct) =>
        {
            await validator.EnsureValidAsync(body, ct);
            if (body.Id is null)
                throw BuildingBlocks.Errors.DomainException.Validation("id", "id is required to update an address.");
            return Results.Ok(await account.UpsertAddressAsync(body, ct));
        });

        me.MapDelete("/addresses/{id:guid}", async (Guid id, AccountService account, CancellationToken ct) =>
        {
            await account.DeleteAddressAsync(id, ct);
            return Results.NoContent();
        });

        me.MapPost("/devices", async (DeviceRequest body, AccountService account, CancellationToken ct) =>
        {
            await account.RegisterDeviceAsync(body, ct);
            return Results.Ok(new { status = "ok" });
        });

        me.MapDelete("/devices", async (string token, AccountService account, CancellationToken ct) =>
        {
            await account.RemoveDeviceAsync(token, ct);
            return Results.NoContent();
        });
    }

    private static void MapBuyer(IEndpointRouteBuilder endpoints)
    {
        var buyer = endpoints.MapGroup("/api/v1/buyer").RequireAuthorization();

        buyer.MapGet("/profile", (AccountService account, CancellationToken ct) => account.GetBuyerProfileAsync(ct));

        buyer.MapPut("/profile", async (BuyerProfileUpsertRequest body, AccountService account, CancellationToken ct) =>
        {
            if (string.IsNullOrWhiteSpace(body.BusinessName))
                throw BuildingBlocks.Errors.DomainException.Validation("businessName", "Business name is required.");
            return await account.UpsertBuyerProfileAsync(body, ct);
        });
    }

    private static (string? Device, string UserAgent, string? Ip) ClientInfo(HttpContext ctx) =>
    (
        ctx.Request.Headers["X-Device-Id"].FirstOrDefault(),
        ctx.Request.Headers.UserAgent.ToString(),
        ctx.Connection.RemoteIpAddress?.ToString()
    );
}
