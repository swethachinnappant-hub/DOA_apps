using BuildingBlocks;
using BuildingBlocks.Modules;
using Catalog.Contracts;
using Catalog.Data;
using Catalog.Endpoints;
using Catalog.Pricing;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Catalog;

public sealed class CatalogModule : IModule
{
    public string Name => "Catalog";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<CatalogDbContext>(configuration);
        services.AddScoped<CatalogReadService>();
        services.AddScoped<CatalogOwnerService>();
        services.AddScoped<ICatalogPricing, CatalogPricingService>();
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        endpoints.MapCatalogEndpoints();
        // Catalog endpoints are added in Step 5 (design §7.2).
    }
}
