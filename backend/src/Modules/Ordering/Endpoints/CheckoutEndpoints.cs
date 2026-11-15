using BuildingBlocks.Security;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Ordering.Checkout;
using Ordering.Contracts;

namespace Ordering.Endpoints;

public static class CheckoutEndpoints
{
    public static IEndpointRouteBuilder MapCheckoutEndpoints(this IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPost("/api/v1/orders", async (
                PlaceOrderRequest request, CheckoutService checkout, CancellationToken ct) =>
            Results.Created("/api/v1/orders", await checkout.PlaceAsync(request, ct)))
            .RequireAuthorization(AuthPolicies.Customer);
        return endpoints;
    }
}
