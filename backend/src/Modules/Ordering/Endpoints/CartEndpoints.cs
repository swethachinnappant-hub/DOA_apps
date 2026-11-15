using BuildingBlocks.Security;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Ordering.Cart;
using Ordering.Contracts;
using static Microsoft.AspNetCore.Http.Results;

namespace Ordering.Endpoints;

public static class CartEndpoints
{
    public static IEndpointRouteBuilder MapCartEndpoints(this IEndpointRouteBuilder endpoints)
    {
        var cart = endpoints.MapGroup("/api/v1/cart")
            .RequireAuthorization(AuthPolicies.Customer);
        cart.MapGet("", (CartService service, CancellationToken ct) => service.GetAsync(ct));
        cart.MapPost("/items", (AddCartItemRequest request, CartService service, CancellationToken ct) =>
            service.AddAsync(request, ct));
        cart.MapPatch("/items/{lineId:guid}", (Guid lineId, UpdateCartItemRequest request, CartService service, CancellationToken ct) =>
            service.UpdateAsync(lineId, request, ct));
        cart.MapDelete("/items/{lineId:guid}", (Guid lineId, CartService service, CancellationToken ct) =>
            service.RemoveAsync(lineId, ct));
        cart.MapDelete("", async (CartService service, CancellationToken ct) =>
        {
            await service.ClearAsync(ct);
            return Results.NoContent();
        });
        return endpoints;
    }
}
