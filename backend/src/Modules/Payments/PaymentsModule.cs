using BuildingBlocks;
using BuildingBlocks.Modules;
using Payments.Data;
using Payments.Endpoints;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Payments;

public sealed class PaymentsModule : IModule
{
    public string Name => "Payments";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<PaymentsDbContext>(configuration);
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        endpoints.MapPaymentEndpoints();
        // Payment endpoints + webhooks are added in Step 7 (design §7.4).
    }
}
