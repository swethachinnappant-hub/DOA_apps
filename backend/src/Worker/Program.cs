using BuildingBlocks;
using BuildingBlocks.Modules;
using BuildingBlocks.Outbox;
using BuildingBlocks.Security;
using Content;
using Catalog;
using Engagement;
using Identity;
using Microsoft.Extensions.DependencyInjection;
using Ordering;
using Payments;
using Promotions;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

try
{
    var builder = Host.CreateApplicationBuilder(args);
    builder.Services.AddSerilog(Log.Logger, dispose: true);

    builder.Services.AddBuildingBlocks(builder.Configuration);

    // Background jobs run as the system user with the fixed configured tenant (§2.6).
    builder.Services.AddScoped<ICurrentUser, SystemCurrentUser>();
    builder.Services.AddScoped<ITenantContext, FixedTenantContext>();

    // Modules are registered so their DbContexts participate in UnitOfWork transactions;
    // module consumers (IOutboxConsumer) are added as they land in later milestones.
    IModule[] modules =
    [
        new IdentityModule(),
        new CatalogModule(),
        new OrderingModule(),
        new PaymentsModule(),
        new PromotionsModule(),
        new EngagementModule(),
        new ContentModule()
    ];
    foreach (var module in modules)
        module.AddModule(builder.Services, builder.Configuration);

    builder.Services.AddHostedService<OutboxDispatcher>();

    var host = builder.Build();
    await host.RunAsync();
    return 0;
}
catch (Exception ex)
{
    Log.Fatal(ex, "Worker terminated unexpectedly");
    return 1;
}
finally
{
    Log.CloseAndFlush();
}
