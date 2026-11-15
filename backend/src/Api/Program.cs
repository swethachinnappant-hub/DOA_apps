using System.Security.Claims;
using System.Text.Json.Serialization;
using BuildingBlocks;
using BuildingBlocks.Idempotency;
using BuildingBlocks.Media;
using BuildingBlocks.Modules;
using BuildingBlocks.Security;
using Content;
using Catalog;
using Engagement;
using Identity;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.FeatureManagement;
using Microsoft.Extensions.Options;
using Microsoft.OpenApi;
using Microsoft.IdentityModel.Tokens;
using OpenTelemetry;
using OpenTelemetry.Metrics;
using OpenTelemetry.Trace;
using Ordering;
using Payments;
using Promotions;
using Scalar.AspNetCore;
using Serilog;
using Serilog.Events;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .Enrich.FromLogContext()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}")
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);
    builder.Host.UseSerilog();

    // Demo mode must never run in production (design §8) — startup fails fast.
    var demoEnabled = bool.TryParse(builder.Configuration["Demo:Enabled"], out var demo) && demo;
    if (builder.Environment.IsProduction() && demoEnabled)
        throw new InvalidOperationException("Demo:Enabled must be false in Production (design §8).");

    builder.Services.AddBuildingBlocks(builder.Configuration);
    builder.Services.AddAppHealthChecks(builder.Configuration);

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

    // AuthN/AuthZ (design §8): RS256 JWT with rotating keys from Identity's RsaKeyProvider.
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer();
    builder.Services.AddOptions<JwtBearerOptions>(JwtBearerDefaults.AuthenticationScheme)
        .Configure<TokenValidationParameters>((options, validation) =>
        {
            // Claims stay exactly as issued: sub, role, tenant, seller_id (§8).
            options.MapInboundClaims = false;
            options.TokenValidationParameters = validation;
            options.TokenValidationParameters.NameClaimType = "sub";
            options.TokenValidationParameters.RoleClaimType = "role";
            options.Events = new JwtBearerEvents
            {
                OnChallenge = async context =>
                {
                    context.HandleResponse();
                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    await context.Response.WriteAsJsonAsync(Problem(
                        "https://tools.ietf.org/html/rfc9110#section-15.5.2",
                        "Unauthorized", 401, "A valid access token is required.",
                        "unauthorized", context.HttpContext.TraceIdentifier));
                },
                OnForbidden = async context =>
                {
                    context.Response.StatusCode = StatusCodes.Status403Forbidden;
                    await context.Response.WriteAsJsonAsync(Problem(
                        "https://tools.ietf.org/html/rfc9110#section-15.5.4",
                        "Forbidden", 403, "You do not have access to this resource.",
                        "forbidden", context.HttpContext.TraceIdentifier));
                }
            };
        });

    builder.Services.AddAuthorization(options =>
    {
        // Policy name ("SellerOwner") vs role value ("seller_owner") — mapped explicitly (§8).
        var policyRoles = new Dictionary<string, string>
        {
            [AuthPolicies.Customer] = Roles.Customer,
            [AuthPolicies.SellerOwner] = Roles.SellerOwner,
            [AuthPolicies.SellerStaff] = Roles.SellerStaff,
            [AuthPolicies.Admin] = Roles.Admin,
            [AuthPolicies.Support] = Roles.Support
        };
        foreach (var (policy, role) in policyRoles)
            options.AddPolicy(policy, policyBuilder => policyBuilder.RequireAssertion(
                context => context.User.Identity?.IsAuthenticated == true && HasRole(context.User, role)));
    });

    // JSON: camelCase (default), nulls omitted (design §12).
    builder.Services.ConfigureHttpJsonOptions(o =>
        o.SerializerOptions.DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull);

    // CORS allow-list for the admin web console (design §8); disabled when unconfigured.
    var corsOrigins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>() ?? [];
    if (corsOrigins.Length > 0)
        builder.Services.AddCors(options => options.AddPolicy("console", policy => policy
            .WithOrigins(corsOrigins)
            .AllowAnyHeader()
            .AllowAnyMethod()));

    builder.Services.AddFeatureManagement();

    // Brotli/gzip (design §12-12) — AddResponseCompression registers both providers by default;
    // problem+json and other non-default MIME types stay uncompressed.
    builder.Services.AddResponseCompression(options => options.EnableForHttps = true);

    // OpenAPI (design §13-5) — built-in generator, JWT bearer scheme, Scalar UI at /scalar.
    builder.Services.AddOpenApi(options => options.AddDocumentTransformer((document, _, _) =>
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
        document.Components.SecuritySchemes["bearer"] = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "JWT access token (15 min)"
        };
        document.Security ??= [];
        document.Security.Add(new OpenApiSecurityRequirement
        {
            [new OpenApiSecuritySchemeReference("bearer", document)] = []
        });
        return Task.CompletedTask;
    }));

    // Observability (design §14): OTLP only when an endpoint is configured.
    var otel = builder.Services.AddOpenTelemetry()
        .WithTracing(tracing => tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation())
        .WithMetrics(metrics => metrics
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation());
    var otlpEndpoint = builder.Configuration["Otlp:Endpoint"]
        ?? Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT");
    if (!string.IsNullOrWhiteSpace(otlpEndpoint))
        otel.WithTracing(tracing => tracing.AddOtlpExporter())
            .WithMetrics(metrics => metrics.AddOtlpExporter());

    var app = builder.Build();

    // Eagerly build token validation (JWT signing key) so a missing Production key
    // fails at startup, not on the first authenticated request (design §8).
    _ = app.Services.GetRequiredService<TokenValidationParameters>();

    app.UseAppExceptionHandling();
    app.UseSerilogRequestLogging(logging => logging.GetLevel = (context, elapsed, exception) =>
        exception is not null || context.Response.StatusCode >= 500
            ? LogEventLevel.Error
            : elapsed > 1000
                ? LogEventLevel.Warning
                : LogEventLevel.Information);

    if (!app.Environment.IsDevelopment())
        app.UseHsts();
    app.UseSecurityHeaders();
    app.UseResponseCompression();
    if (corsOrigins.Length > 0)
        app.UseCors("console");
    app.UseAuthentication();
    app.UseAuthorization();
    app.UseMiddleware<IdempotencyMiddleware>();

    // Local-disk media served directly in dev (design §3.4 — /media).
    if (string.Equals(builder.Configuration["Storage:Provider"] ?? "local", "local", StringComparison.OrdinalIgnoreCase))
    {
        var mediaRoot = Path.GetFullPath(builder.Configuration["Storage:LocalRoot"] ?? "App_Data/media");
        Directory.CreateDirectory(mediaRoot);
        app.UseStaticFiles(new StaticFileOptions
        {
            RequestPath = "/media",
            FileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(mediaRoot)
        });
    }

    foreach (var module in modules)
        module.MapModule(app);

    app.MapMediaEndpoints();

    app.MapHealthChecks("/health/live", new HealthCheckOptions { Predicate = c => c.Tags.Contains("live") });
    app.MapHealthChecks("/health/ready", new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
    app.MapOpenApi();
    app.MapScalarApiReference();
    app.MapGet("/", () => Results.Ok(new
    {
        service = "JewelryB2B API",
        openapi = "/openapi/v1.json",
        docs = "/scalar",
        live = "/health/live"
    }));

    await app.RunAsync();
    return 0;
}
catch (Exception ex)
{
    Log.Fatal(ex, "API terminated unexpectedly");
    return 1;
}
finally
{
    Log.CloseAndFlush();
}

static bool HasRole(ClaimsPrincipal user, string role) =>
    user.Claims.Any(c =>
        (c.Type == "role" || c.Type == System.Security.Claims.ClaimTypes.Role) &&
        string.Equals(c.Value, role, StringComparison.OrdinalIgnoreCase));

static ProblemDetails Problem(string type, string title, int status, string detail, string code, string traceId) => new()
{
    Type = type,
    Title = title,
    Status = status,
    Detail = detail,
    Instance = traceId,
    Extensions =
    {
        ["code"] = code,
        ["traceId"] = traceId
    }
};

/// <summary>HTTP hygiene (design §8): sniffing, framing and referrer hardening.</summary>
internal static class ApiSecurityHeadersExtensions
{
    public static IApplicationBuilder UseSecurityHeaders(this IApplicationBuilder app) =>
        app.Use(async (context, next) =>
        {
            context.Response.OnStarting(() =>
            {
                var headers = context.Response.Headers;
                headers["X-Content-Type-Options"] = "nosniff";
                headers["X-Frame-Options"] = "DENY";
                headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
                headers["X-Permitted-Cross-Domain-Policies"] = "none";
                return Task.CompletedTask;
            });
            await next();
        });
}
