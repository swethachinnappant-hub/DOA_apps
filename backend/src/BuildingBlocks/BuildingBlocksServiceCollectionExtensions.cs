using BuildingBlocks.Audit;
using BuildingBlocks.Caching;
using BuildingBlocks.Data;
using BuildingBlocks.Idempotency;
using BuildingBlocks.Media;
using BuildingBlocks.Outbox;
using BuildingBlocks.Security;
using BuildingBlocks.Storage;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using Npgsql;
using StackExchange.Redis;

namespace BuildingBlocks;

public static class BuildingBlocksServiceCollectionExtensions
{
    /// <summary>
    /// Registers the shared core (design §2): platform schema, unit of work,
    /// outbox/inbox, idempotency, audit, caches (Redis when configured, memory
    /// otherwise), object storage (S3/MinIO or local disk) and the HTTP
    /// principal services. Modules add their own DbContexts via
    /// <see cref="AddModuleDbContext{TContext}"/>.
    /// </summary>
    public static IServiceCollection AddBuildingBlocks(this IServiceCollection services, IConfiguration configuration)
    {
        var connectionString = configuration.GetConnectionString("Postgres")
            ?? throw new InvalidOperationException("Connection string 'Postgres' is required (the database is the system of record).");

        services.AddHttpContextAccessor();
        services.AddMemoryCache();
        services.AddSingleton(TimeProvider.System);

        // All DbContexts in a request share this connection. UnitOfWork must enlist
        // every module context in one PostgreSQL transaction for checkout atomicity.
        services.AddScoped(_ => new NpgsqlConnection(connectionString));

        services.Configure<StorageOptions>(configuration.GetSection("Storage"));
        services.Configure<MediaOptions>(configuration.GetSection("Media"));
        services.Configure<IdempotencyOptions>(configuration.GetSection("Idempotency"));
        services.Configure<OutboxOptions>(configuration.GetSection("Outbox"));

        services.AddDbContext<PlatformDbContext>((sp, options) =>
            options.UseNpgsql(sp.GetRequiredService<NpgsqlConnection>()).UseSnakeCaseNamingConvention());
        services.AddScoped<IEnlistedDbContext>(sp => sp.GetRequiredService<PlatformDbContext>());

        services.AddScoped<ICurrentUser, ClaimsCurrentUser>();
        services.AddScoped<ITenantContext, ClaimsTenantContext>();
        services.AddScoped<IAuditLog, AuditLogService>();
        services.AddScoped<IOutbox, Outbox.Outbox>();
        services.AddScoped<IInbox, Inbox>();
        services.AddScoped<IIdempotencyService, IdempotencyService>();
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        // Caching: Redis when configured (design §2.4), in-process fallback otherwise.
        var redisConfiguration = configuration["Redis:Configuration"] ?? configuration.GetConnectionString("Redis");
        if (!string.IsNullOrWhiteSpace(redisConfiguration))
        {
            services.AddSingleton<IConnectionMultiplexer>(_ =>
                ConnectionMultiplexer.Connect(redisConfiguration));
            services.AddSingleton<ITicketStore, RedisTicketStore>();
        }
        else
        {
            services.AddSingleton<ITicketStore, MemoryTicketStore>();
        }
        services.AddSingleton<ITaggedCache>(sp => new TaggedCache(
            sp.GetRequiredService<IMemoryCache>(),
            sp.GetService<IConnectionMultiplexer>(),
            sp.GetRequiredService<TimeProvider>(),
            sp.GetRequiredService<ILogger<TaggedCache>>()));

        // Object storage (design §3.4): local disk in dev, S3/MinIO otherwise.
        var storageProvider = configuration["Storage:Provider"] ?? "local";
        if (string.Equals(storageProvider, "s3", StringComparison.OrdinalIgnoreCase))
            services.AddSingleton<IObjectStorage, S3ObjectStorage>();
        else
            services.AddSingleton<IObjectStorage, LocalDiskObjectStorage>();

        services.AddScoped<IMediaService, MediaService>();

        return services;
    }

    /// <summary>Each module DbContext gets the shared connection + snake_case columns + enlistment (design §2.3).</summary>
    public static void AddModuleDbContext<TContext>(this IServiceCollection services, IConfiguration configuration)
        where TContext : DbContext, IEnlistedDbContext
    {
        var connectionString = configuration.GetConnectionString("Postgres")
            ?? throw new InvalidOperationException("Connection string 'Postgres' is required.");
        services.AddDbContext<TContext>((sp, options) =>
            options.UseNpgsql(sp.GetRequiredService<NpgsqlConnection>()).UseSnakeCaseNamingConvention());
        services.AddScoped<IEnlistedDbContext>(sp => sp.GetRequiredService<TContext>());
    }

    /// <summary>Health: /health/live is process liveness, /health/ready checks Postgres (+Redis when present).</summary>
    public static IServiceCollection AddAppHealthChecks(this IServiceCollection services, IConfiguration configuration)
    {
        var builder = services.AddHealthChecks();
        builder.AddCheck("self", () => HealthCheckResult.Healthy(), tags: ["live"]);
        builder.AddCheck<PostgresHealthCheck>("postgres", tags: ["ready"]);
        if (!string.IsNullOrWhiteSpace(configuration["Redis:Configuration"] ?? configuration.GetConnectionString("Redis")))
            builder.AddCheck<RedisHealthCheck>("redis", tags: ["ready"]);
        return services;
    }
}

public sealed class PostgresHealthCheck(IServiceScopeFactory scopeFactory) : IHealthCheck
{
    public async Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            using var scope = scopeFactory.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<PlatformDbContext>();
            var canConnect = await db.Database.CanConnectAsync(cancellationToken);
            return canConnect ? HealthCheckResult.Healthy("postgres reachable") : HealthCheckResult.Unhealthy("postgres unreachable");
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("postgres check failed", ex);
        }
    }
}

public sealed class RedisHealthCheck(IConnectionMultiplexer redis) : IHealthCheck
{
    public Task<HealthCheckResult> CheckHealthAsync(HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        try
        {
            var connected = redis.IsConnected;
            return Task.FromResult(connected
                ? HealthCheckResult.Healthy("redis reachable")
                : HealthCheckResult.Degraded("redis unreachable — running on L1 cache only"));
        }
        catch (Exception ex)
        {
            // Redis must never take the API down (design §20.2).
            return Task.FromResult(HealthCheckResult.Degraded("redis check failed", ex));
        }
    }
}

public static class ApplicationBuilderExtensions
{
    /// <summary>Outermost boundary: RFC 7807 mapping for every unhandled exception (design §13.2).</summary>
    public static IApplicationBuilder UseAppExceptionHandling(this IApplicationBuilder app) =>
        app.UseMiddleware<Exceptions.AppExceptionMiddleware>();
}
