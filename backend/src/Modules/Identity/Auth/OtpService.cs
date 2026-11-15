using System.Text.Json;
using BuildingBlocks.Caching;
using BuildingBlocks.Errors;
using BuildingBlocks.Results;
using Microsoft.Extensions.Logging;

namespace Identity.Auth;

/// <summary>
/// OTP login codes (design §8): Redis-held with in-memory fallback via
/// ITicketStore — 6-digit code, 5 minute TTL, 5 verify attempts, resend once per
/// 60 s, max 10 sends/hour per phone and 10/hour per IP.
/// </summary>
public interface IOtpService
{
    Task<string> IssueAsync(string phone, string? ip, CancellationToken ct = default);
    Task VerifyAsync(string phone, string code, string? ip, CancellationToken ct = default);
}

public interface ISmsSender
{
    Task SendAsync(string phone, string code, CancellationToken ct = default);
}

/// <summary>Dev sink — logs the code (replaced by an SMS/WhatsApp provider later, design §8).</summary>
public sealed class LoggingSmsSender(ILogger<LoggingSmsSender> logger) : ISmsSender
{
    public Task SendAsync(string phone, string code, CancellationToken ct = default)
    {
        logger.LogInformation("OTP for {Phone}: {Code} (valid 5 minutes)", phone, code);
        return Task.CompletedTask;
    }
}

public sealed class OtpService(ITicketStore tickets, ISmsSender sms, ILogger<OtpService> logger) : IOtpService
{
    private static readonly TimeSpan CodeTtl = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan ResendThrottle = TimeSpan.FromSeconds(60);

    private const int MaxAttempts = 5;
    private const int MaxSendsPerHour = 10;

    private sealed record OtpRecord(string Code, int Attempts, int Sends);

    public async Task<string> IssueAsync(string phone, string? ip, CancellationToken ct = default)
    {
        // Per-IP hourly cap (design §8 rate limits).
        if (ip is not null)
        {
            var ipKey = $"otp:ip:{ip}";
            var ipSends = int.Parse(await tickets.GetAsync(ipKey, ct) ?? "0");
            if (ipSends >= MaxSendsPerHour)
                throw DomainException.TooManyRequests("Too many OTP requests from this network. Try again later.");
            await tickets.SetAsync(ipKey, (ipSends + 1).ToString(), TimeSpan.FromHours(1), ct);
        }

        // Resend throttle + per-phone hourly cap share the stored record.
        var key = CodeKey(phone);
        var existingRaw = await tickets.GetAsync(key, ct);
        var record = existingRaw is null ? null : JsonSerializer.Deserialize<OtpRecord>(existingRaw);
        if (record is not null && record.Sends >= MaxSendsPerHour)
            throw DomainException.TooManyRequests("Daily OTP limit reached for this phone number. Try again later.");

        var throttleRaw = await tickets.GetAsync(ThrottleKey(phone), ct);
        if (throttleRaw is not null)
            throw DomainException.TooManyRequests("Please wait a minute before requesting another code.");

        var code = Random.Shared.Next(0, 1_000_000).ToString("D6");
        var sends = (record?.Sends ?? 0) + 1;
        await tickets.SetAsync(key, JsonSerializer.Serialize(new OtpRecord(code, 0, sends)), CodeTtl, ct);
        await tickets.SetAsync(ThrottleKey(phone), "1", ResendThrottle, ct);

        await sms.SendAsync(phone, code, ct);
        logger.LogInformation("OTP issued for {Phone} (send #{Sends})", phone, sends);
        return code;
    }

    public async Task VerifyAsync(string phone, string code, string? ip, CancellationToken ct = default)
    {
        var lockKey = LockKey(phone);
        if (await tickets.GetAsync(lockKey, ct) is not null)
            throw DomainException.TooManyRequests("Too many incorrect attempts. Try again in 15 minutes.");

        var key = CodeKey(phone);
        var raw = await tickets.GetAsync(key, ct);
        if (raw is null)
            throw new DomainException(new Error("otp_expired", "The code has expired or was never requested. Request a new one."), 401);

        var record = JsonSerializer.Deserialize<OtpRecord>(raw)!;
        if (record.Attempts >= MaxAttempts)
        {
            await tickets.RemoveAsync(key, ct);
            await tickets.SetAsync(lockKey, "1", TimeSpan.FromMinutes(15), ct);
            throw DomainException.TooManyRequests("Too many incorrect attempts. Try again in 15 minutes.");
        }

        if (!string.Equals(record.Code, code, StringComparison.Ordinal))
        {
            var updated = record with { Attempts = record.Attempts + 1 };
            await tickets.SetAsync(key, JsonSerializer.Serialize(updated), CodeTtl, ct);
            var remaining = MaxAttempts - updated.Attempts;
            throw new DomainException(
                new Error("invalid_otp", remaining > 0
                    ? $"The code is incorrect. {remaining} attempt(s) remaining."
                    : "The code is incorrect."), 401);
        }

        await tickets.RemoveAsync(key, ct);
        await tickets.RemoveAsync(ThrottleKey(phone), ct);
    }

    private static string CodeKey(string phone) => $"otp:code:{phone}";
    private static string ThrottleKey(string phone) => $"otp:sent:{phone}";
    private static string LockKey(string phone) => $"otp:lock:{phone}";
}
