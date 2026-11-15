using BuildingBlocks;
using BuildingBlocks.Modules;
using Engagement.Data;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Engagement;

public sealed class EngagementModule : IModule
{
    public string Name => "Engagement";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<EngagementDbContext>(configuration);
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        // Wishlist/review/notification endpoints are added in Step 8 (design §7.5).
    }
}
