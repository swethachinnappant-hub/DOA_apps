using BuildingBlocks.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;

namespace Payments.Endpoints;

public static class PaymentEndpoints
{
    public static IEndpointRouteBuilder MapPaymentEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var payments = endpoints.MapGroup("/api/v1/payments")
            .RequireAuthorization(AuthPolicies.Customer);

        payments.MapPost("/delivery-check", async (
            object request, IServiceProvider sp, CancellationToken ct) =>
        {
            return Results.Ok(new { status = "address_verified" });
        });

        payments.MapPost("/checkout", async (
            object request, IServiceProvider sp, CancellationToken ct) =>
        {
            return Results.Ok(new { status = "order_placed" });
        });

        return endpoints;
    }
}