using BuildingBlocks;
using BuildingBlocks.Modules;
using Content.Data;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Content;

public sealed class ContentModule : IModule
{
    public string Name => "Content";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<ContentDbContext>(configuration);
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        // Store-config/hero/nav endpoints are added in Step 9 (design §7.6).
    }
}
