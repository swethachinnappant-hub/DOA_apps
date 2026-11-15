using BuildingBlocks;
using BuildingBlocks.Modules;
using Promotions.Data;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Promotions;

public sealed class PromotionsModule : IModule
{
    public string Name => "Promotions";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<PromotionsDbContext>(configuration);
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        // Coupons/loyalty endpoints are added in Step 8 (design §7.5).
    }
}
