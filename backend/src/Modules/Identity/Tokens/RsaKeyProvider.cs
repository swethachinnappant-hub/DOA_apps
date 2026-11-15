using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.IdentityModel.Tokens;

namespace Identity.Tokens;

/// <summary>
/// RS256 signing key with rotation support (design §8): the current private key
/// signs access tokens, current + previous keys verify them, JWKS publishes the
/// matching public keys. In Development the key is generated once at
/// App_Data/dev-jwt; in Production a missing key is a startup failure.
/// </summary>
public sealed class RsaKeyProvider
{
    private readonly RSA _current;
    private readonly List<RSA> _previous = [];
    private readonly string _issuer;
    private readonly string _audience;

    public string CurrentKid { get; }

    public RsaKeyProvider(IConfiguration configuration, IHostEnvironment environment)
    {
        _issuer = configuration["Jwt:Issuer"] ?? "jewelryb2b";
        _audience = configuration["Jwt:Audience"] ?? "jewelryb2b-client";

        var configuredPath = configuration["Jwt:PrivateKeyPath"];
        var path = string.IsNullOrWhiteSpace(configuredPath)
            ? Path.Combine(AppContext.BaseDirectory, "App_Data", "dev-jwt", "jwt.pem")
            : configuredPath;

        if (!File.Exists(path))
        {
            if (environment.IsEnvironment("Production"))
                throw new InvalidOperationException(
                    $"JWT private key not found at '{path}'. Configure Jwt:PrivateKeyPath (a missing key in Production is a startup failure — design §8).");
            Directory.CreateDirectory(Path.GetDirectoryName(path)!);
            using var rsa = RSA.Create(2048);
            File.WriteAllText(path, rsa.ExportRSAPrivateKeyPem());
        }

        _current = RSA.Create();
        _current.ImportFromPem(File.ReadAllText(path));
        CurrentKid = ComputeKid(_current);

        var previous = configuration["Jwt:PreviousPrivateKeys"];
        if (!string.IsNullOrWhiteSpace(previous))
        {
            foreach (var previousPath in previous.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            {
                if (!File.Exists(previousPath)) continue;
                var rsa = RSA.Create();
                rsa.ImportFromPem(File.ReadAllText(previousPath));
                _previous.Add(rsa);
            }
        }
    }

    public SigningCredentials SigningCredentials =>
        new(new RsaSecurityKey(_current) { KeyId = CurrentKid }, SecurityAlgorithms.RsaSha256);

    public TokenValidationParameters CreateValidationParameters()
    {
        var keys = AllKeys();
        return new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = _issuer,
            ValidateAudience = true,
            ValidAudience = _audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKeys = keys,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromSeconds(60),
            RequireExpirationTime = true
        };
    }

    /// <summary>GET /auth/jwks — public verification keys only.</summary>
    public object CreateJwks() => new
    {
        keys = AllKeys().Select(k =>
        {
            var rsa = ((RsaSecurityKey)k).Rsa!.ExportParameters(false);
            return new
            {
                kty = "RSA",
                use = "sig",
                alg = SecurityAlgorithms.RsaSha256,
                kid = k.KeyId,
                n = Base64UrlEncoder.Encode(rsa.Modulus),
                e = Base64UrlEncoder.Encode(rsa.Exponent)
            };
        }).ToArray()
    };

    private IEnumerable<SecurityKey> AllKeys()
    {
        yield return new RsaSecurityKey(_current) { KeyId = CurrentKid };
        foreach (var rsa in _previous)
            yield return new RsaSecurityKey(rsa) { KeyId = ComputeKid(rsa) };
    }

    private static string ComputeKid(RSA rsa)
    {
        var thumbprint = SHA256.HashData(rsa.ExportSubjectPublicKeyInfo());
        return Base64UrlEncoder.Encode(thumbprint)[..16];
    }
}
