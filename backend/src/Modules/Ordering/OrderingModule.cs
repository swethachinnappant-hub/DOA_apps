using BuildingBlocks;
using BuildingBlocks.Modules;
using Ordering.Cart;
using Ordering.Checkout;
using Ordering.Data;
using Ordering.Endpoints;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Ordering;

public sealed class OrderingModule : IModule
{
    public string Name => "Ordering";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<OrderingDbContext>(configuration);
        services.AddScoped<CartService>();
        services.AddScoped<CheckoutService>();
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        endpoints.MapCartEndpoints();
        endpoints.MapCheckoutEndpoints();
        // Ordering endpoints are added in Step 6 (design §7.3).
    }
}
