using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace BuildingBlocks.Modules;

/// <summary>
/// One module = one schema (design §2.1). Api's Program wires every module
/// explicitly (no reflection): AddModule at startup, MapModule after routing.
/// Modules may only reference other modules' *.Contracts projects.
/// </summary>
public interface IModule
{
    string Name { get; }
    void AddModule(IServiceCollection services, IConfiguration configuration);
    void MapModule(IEndpointRouteBuilder endpoints);
}
