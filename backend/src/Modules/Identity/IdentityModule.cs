using BuildingBlocks;
using BuildingBlocks.Modules;
using FluentValidation;
using Identity.Accounts;
using Identity.Auth;
using Identity.Contracts;
using Identity.Data;
using Identity.Endpoints;
using Identity.Passwords;
using Identity.Tokens;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;

namespace Identity;

public sealed class IdentityModule : IModule
{
    public string Name => "Identity";

    public void AddModule(IServiceCollection services, IConfiguration configuration)
    {
        services.AddModuleDbContext<IdentityDbContext>(configuration);

        services.AddSingleton<RsaKeyProvider>();
        // Api resolves this when wiring JwtBearer (validation follows key rotation).
        services.AddSingleton(sp => sp.GetRequiredService<RsaKeyProvider>().CreateValidationParameters());

        services.AddScoped<ITokenService, TokenService>();
        services.AddScoped<IPasswordHasher, PasswordHasher>();
        services.AddScoped<IOtpService, OtpService>();
        services.AddScoped<AuthService>();
        services.AddScoped<AccountService>();
        services.AddScoped<ISellerDirectory, SellerDirectory>();
        services.AddScoped<IUserDirectory, UserDirectory>();

        services.AddSingleton<ISmsSender, LoggingSmsSender>();
        if (!string.IsNullOrWhiteSpace(configuration["Mail:Host"]))
            services.AddSingleton<IEmailSender, SmtpEmailSender>();
        else
            services.AddSingleton<IEmailSender, LoggingEmailSender>();

        services.AddValidatorsFromAssemblyContaining<RegisterRequestValidator>();
    }

    public void MapModule(IEndpointRouteBuilder endpoints)
    {
        var configuration = endpoints.ServiceProvider.GetRequiredService<IConfiguration>();
        var demoEnabled = bool.TryParse(configuration["Demo:Enabled"], out var enabled) && enabled;
        endpoints.MapIdentityEndpoints(demoEnabled);
    }
}
