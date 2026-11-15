using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using BuildingBlocks.Security;
using Identity.Data.Entities;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using AppClaimTypes = BuildingBlocks.Security.ClaimTypes;
using SysClaimTypes = System.Security.Claims.ClaimTypes;

namespace Identity.Tokens;

public sealed record IssuedSession(string AccessToken, string RefreshToken, int ExpiresInSeconds);

/// <summary>
/// Access tokens (RS256, 15 min, minimal claims sub/role/tenant/seller_id — design §8)
/// plus opaque refresh token generation + hashing (stored hashed, §8 refresh row).
/// </summary>
public interface ITokenService
{
    (string AccessToken, int ExpiresInSeconds) CreateAccessToken(User user, string role);
    string CreateOpaqueRefreshToken();
    string HashRefreshToken(string rawToken);
    int AccessTokenMinutes { get; }
    TimeSpan RefreshTokenLifetime { get; }
}

public sealed class TokenService(RsaKeyProvider keys, IConfiguration configuration) : ITokenService
{
    private static readonly JwtSecurityTokenHandler Handler = new() { MapInboundClaims = false };

    public int AccessTokenMinutes { get; } = int.TryParse(configuration["Jwt:AccessTokenMinutes"], out var m) ? m : 15;

    public TimeSpan RefreshTokenLifetime { get; } =
        TimeSpan.FromDays(int.TryParse(configuration["Jwt:RefreshDays"], out var d) ? d : 30);

    public (string AccessToken, int ExpiresInSeconds) CreateAccessToken(User user, string role)
    {
        var now = DateTime.UtcNow;
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(SysClaimTypes.Role, role),
            new(AppClaimTypes.Tenant, user.TenantId.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.CreateVersion7().ToString()),
            new(JwtRegisteredClaimNames.Iat, new DateTimeOffset(now).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64)
        };
        if (user.SellerId is { } sellerId)
            claims.Add(new Claim(AppClaimTypes.SellerId, sellerId.ToString()));

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            IssuedAt = now,
            NotBefore = now,
            Expires = now.AddMinutes(AccessTokenMinutes),
            Issuer = configuration["Jwt:Issuer"] ?? "jewelryb2b",
            Audience = configuration["Jwt:Audience"] ?? "jewelryb2b-client",
            SigningCredentials = keys.SigningCredentials
        };

        var token = Handler.CreateToken(descriptor);
        return (Handler.WriteToken(token), AccessTokenMinutes * 60);
    }

    public string CreateOpaqueRefreshToken() =>
        Base64UrlEncoder.Encode(RandomNumberGenerator.GetBytes(64));

    public string HashRefreshToken(string rawToken)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(rawToken));
        return Convert.ToHexString(bytes).ToLowerInvariant();
    }
}
