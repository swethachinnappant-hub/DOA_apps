using System.Security.Cryptography;

namespace Identity.Passwords;

/// <summary>
/// PBKDF2-SHA256 password hashing (OWASP 2023 recommendation: 600 000 iterations),
/// format: pbkdf2-sha256$600000$&lt;salt-b64&gt;$&lt;hash-b64&gt; — replaces the ASP.NET
/// Identity hasher referenced in design §8 without taking the whole Identity stack.
/// </summary>
public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string? passwordHash);
    bool NeedsRehash(string? passwordHash);
}

public sealed class PasswordHasher : IPasswordHasher
{
    private const string Prefix = "pbkdf2-sha256";
    private const int Iterations = 600_000;
    private const int SaltSize = 16;
    private const int KeySize = 32;

    public string Hash(string password)
    {
        ArgumentException.ThrowIfNullOrEmpty(password);
        var salt = RandomNumberGenerator.GetBytes(SaltSize);
        var key = Rfc2898DeriveBytes.Pbkdf2(password, salt, Iterations, HashAlgorithmName.SHA256, KeySize);
        return $"{Prefix}${Iterations}${Convert.ToBase64String(salt)}${Convert.ToBase64String(key)}";
    }

    public bool Verify(string password, string? passwordHash)
    {
        if (string.IsNullOrEmpty(passwordHash)) return false;
        var parts = passwordHash.Split('$');
        if (parts.Length != 4 || parts[0] != Prefix) return false;
        if (!int.TryParse(parts[1], out var iterations)) return false;

        var salt = Convert.FromBase64String(parts[2]);
        var expected = Convert.FromBase64String(parts[3]);
        var actual = Rfc2898DeriveBytes.Pbkdf2(password, salt, iterations, HashAlgorithmName.SHA256, expected.Length);
        return CryptographicOperations.FixedTimeEquals(actual, expected);
    }

    public bool NeedsRehash(string? passwordHash)
    {
        if (string.IsNullOrEmpty(passwordHash)) return true;
        var parts = passwordHash.Split('$');
        return parts.Length != 4 || parts[0] != Prefix || !int.TryParse(parts[1], out var iterations) || iterations != Iterations;
    }
}
