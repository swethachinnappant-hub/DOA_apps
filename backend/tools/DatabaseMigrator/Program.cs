using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Security;
using Catalog.Data;
using Content.Data;
using Engagement.Data;
using Identity.Data;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using Ordering.Data;
using Payments.Data;
using Promotions.Data;
using System.Text.Json;

namespace DatabaseMigrator;

/// <summary>
/// One-shot migrate step (design §13-7, §17 "migrate" service): idempotent
/// bootstrap SQL (extensions) → per-module EF migrations → unmapped SQL
/// (search_vector, mv_trending_30d, fillfactor). Run:
///   dotnet run --project tools/DatabaseMigrator -- [migrate]
/// Connection: ConnectionStrings__Postgres env var or appsettings.json.
/// </summary>
public static class Program
{
    public static async Task<int> Main(string[] args)
    {
        var connectionString = ResolveConnectionString(args);
        var command = args.Length > 0 ? args[0].ToLowerInvariant() : "migrate";
        if (command is not "migrate")
        {
            Console.Error.WriteLine("usage: DatabaseMigrator [migrate]");
            return 2;
        }

        try
        {
            await EnsureDatabaseExistsAsync(connectionString);
            await RunScriptAsync(connectionString, "extensions (design §3.5)", BootstrapSql.Extensions);
            await RunScriptAsync(connectionString, "pg_stat_statements (best effort)", BootstrapSql.PgStatStatements);

            var tenant = new FixedTenant(ResolveTenantId(args));
            await using var platform = new PlatformDbContext(
                Options<PlatformDbContext>(connectionString));
            var contexts = new DbContext[]
            {
                platform,
                new IdentityDbContext(Options<IdentityDbContext>(connectionString), tenant),
                new CatalogDbContext(Options<CatalogDbContext>(connectionString), tenant),
                new OrderingDbContext(Options<OrderingDbContext>(connectionString), tenant),
                new PaymentsDbContext(Options<PaymentsDbContext>(connectionString), tenant),
                new PromotionsDbContext(Options<PromotionsDbContext>(connectionString), tenant),
                new EngagementDbContext(Options<EngagementDbContext>(connectionString)),
                new ContentDbContext(Options<ContentDbContext>(connectionString), tenant)
            };

            foreach (var context in contexts)
            {
                var name = context.GetType().Name;
                Console.WriteLine($"[{name}] migrating...");
                await context.Database.MigrateAsync();
            }

            await RunScriptAsync(connectionString, "unmapped search/trending (design §5.2/§11)", BootstrapSql.AfterMigrations);
            Console.WriteLine("migrate: done");
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"migrate failed: {ex.Message}");
            return 1;
        }
    }

    private static DbContextOptions<T> Options<T>(string connectionString) where T : DbContext =>
        new DbContextOptionsBuilder<T>()
            .UseNpgsql(connectionString)
            .UseSnakeCaseNamingConvention()
            .Options;

    private static async Task EnsureDatabaseExistsAsync(string connectionString)
    {
        try
        {
            await using var probe = new NpgsqlConnection(connectionString);
            await probe.OpenAsync();
            return;
        }
        catch (PostgresException ex) when (ex.SqlState == PostgresErrorCodes.InvalidCatalogName)
        {
            // Database missing — create it from the maintenance database.
        }

        var builder = new NpgsqlConnectionStringBuilder(connectionString);
        var database = builder.Database
            ?? throw new InvalidOperationException("Connection string must set a Database.");
        builder.Database = "postgres";
        await using var admin = new NpgsqlConnection(builder.ConnectionString);
        await admin.OpenAsync();
        await using var create = admin.CreateCommand();
        create.CommandText = $"create database \"{database.Replace("\"", "\"\"")}\"";
        await create.ExecuteNonQueryAsync();
        Console.WriteLine($"created database \"{database}\"");
    }

    private static async Task RunScriptAsync(string connectionString, string label, string sql)
    {
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        await using var command = connection.CreateCommand();
        command.CommandText = sql;
        try
        {
            await command.ExecuteNonQueryAsync();
            Console.WriteLine($"bootstrap: {label} ok");
        }
        catch (PostgresException ex) when (label.Contains("best effort"))
        {
            // pg_stat_statements needs shared_preload_libraries — optional (design §3.5).
            Console.WriteLine($"bootstrap: {label} skipped ({ex.MessageText})");
        }
    }

    private static string ResolveConnectionString(string[] args)
    {
        for (var i = 0; i < args.Length - 1; i++)
            if (args[i] == "--connection" && !string.IsNullOrWhiteSpace(args[i + 1]))
                return args[i + 1];

        var environment = Environment.GetEnvironmentVariable("ConnectionStrings__Postgres");
        if (!string.IsNullOrWhiteSpace(environment)) return environment!;

        var path = Path.Combine(AppContext.BaseDirectory, "appsettings.json");
        if (File.Exists(path))
        {
            using var document = JsonDocument.Parse(File.ReadAllText(path));
            if (document.RootElement.TryGetProperty("ConnectionStrings", out var connections) &&
                connections.TryGetProperty("Postgres", out var postgres) &&
                postgres.GetString() is { Length: > 0 } configured)
                return configured;
        }

        throw new InvalidOperationException(
            "Connection string not found. Set ConnectionStrings__Postgres, pass --connection, or add appsettings.json.");
    }

    private static Guid ResolveTenantId(string[] args)
    {
        var environment = Environment.GetEnvironmentVariable("Tenants__DefaultId");
        if (Guid.TryParse(environment, out var fromEnvironment)) return fromEnvironment;

        var path = Path.Combine(AppContext.BaseDirectory, "appsettings.json");
        if (File.Exists(path))
        {
            using var document = JsonDocument.Parse(File.ReadAllText(path));
            if (document.RootElement.TryGetProperty("Tenants", out var tenants) &&
                tenants.TryGetProperty("DefaultId", out var id) &&
                Guid.TryParse(id.GetString(), out var fromFile))
                return fromFile;
        }

        return Guid.Parse("11111111-1111-4111-8111-111111111111");
    }
}

internal sealed class FixedTenant(Guid tenantId) : ITenantContext
{
    public Guid TenantId => tenantId;
    public bool HasTenant => tenantId != Guid.Empty;
}
