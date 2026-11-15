using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Security;
using Catalog.Data;
using Content.Data;
using Engagement.Data;
using Identity.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Ordering.Data;
using Payments.Data;
using Promotions.Data;

namespace DatabaseMigrator;

/// <summary>
/// Design-time factories for `dotnet ef migrations add -s tools/DatabaseMigrator`
/// (no database access needed — a dummy connection string is used). Keep the
/// options identical to runtime: Npgsql + snake_case.
/// </summary>
internal static class DesignTime
{
    public static string ConnectionString { get; } =
        Environment.GetEnvironmentVariable("ConnectionStrings__Postgres")
        ?? "Host=localhost;Database=jewelryb2b;Username=design;Password=design";

    public static DbContextOptions<T> Options<T>() where T : DbContext =>
        new DbContextOptionsBuilder<T>()
            .UseNpgsql(ConnectionString)
            .UseSnakeCaseNamingConvention()
            .Options;

    internal sealed class Tenant : ITenantContext
    {
        public Guid TenantId => Guid.Parse("11111111-1111-4111-8111-111111111111");
        public bool HasTenant => true;
    }

    public static readonly Tenant DesignTenant = new();
}

internal sealed class PlatformDbContextFactory : IDesignTimeDbContextFactory<PlatformDbContext>
{
    public PlatformDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<PlatformDbContext>());
}

internal sealed class IdentityDbContextFactory : IDesignTimeDbContextFactory<IdentityDbContext>
{
    public IdentityDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<IdentityDbContext>(), DesignTime.DesignTenant);
}

internal sealed class CatalogDbContextFactory : IDesignTimeDbContextFactory<CatalogDbContext>
{
    public CatalogDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<CatalogDbContext>(), DesignTime.DesignTenant);
}

internal sealed class OrderingDbContextFactory : IDesignTimeDbContextFactory<OrderingDbContext>
{
    public OrderingDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<OrderingDbContext>(), DesignTime.DesignTenant);
}

internal sealed class PaymentsDbContextFactory : IDesignTimeDbContextFactory<PaymentsDbContext>
{
    public PaymentsDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<PaymentsDbContext>(), DesignTime.DesignTenant);
}

internal sealed class PromotionsDbContextFactory : IDesignTimeDbContextFactory<PromotionsDbContext>
{
    public PromotionsDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<PromotionsDbContext>(), DesignTime.DesignTenant);
}

internal sealed class EngagementDbContextFactory : IDesignTimeDbContextFactory<EngagementDbContext>
{
    public EngagementDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<EngagementDbContext>());
}

internal sealed class ContentDbContextFactory : IDesignTimeDbContextFactory<ContentDbContext>
{
    public ContentDbContext CreateDbContext(string[] args) =>
        new(DesignTime.Options<ContentDbContext>(), DesignTime.DesignTenant);
}
