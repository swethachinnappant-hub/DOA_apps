using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Identity.Auth;

public interface IEmailSender
{
    Task SendAsync(string to, string subject, string body, CancellationToken ct = default);
}

/// <summary>Logs the message when no SMTP is configured (dev/mailpit are wired at Step 12 — design §17).</summary>
public sealed class LoggingEmailSender(ILogger<LoggingEmailSender> logger) : IEmailSender
{
    public Task SendAsync(string to, string subject, string body, CancellationToken ct = default)
    {
        logger.LogInformation("Email to {To}: {Subject} — {Body}", to, subject, body);
        return Task.CompletedTask;
    }
}

public sealed class SmtpEmailSender(IConfiguration configuration, ILogger<SmtpEmailSender> logger) : IEmailSender
{
    public async Task SendAsync(string to, string subject, string body, CancellationToken ct = default)
    {
        var host = configuration["Mail:Host"]!;
        var port = int.TryParse(configuration["Mail:Port"], out var p) ? p : 1025;
        var from = configuration["Mail:From"] ?? "no-reply@jewelryb2b.local";

        using var client = new SmtpClient(host, port)
        {
            EnableSsl = bool.TryParse(configuration["Mail:EnableSsl"], out var ssl) && ssl,
            DeliveryMethod = SmtpDeliveryMethod.Network
        };
        var message = new MailMessage(from, to, subject, body);
        try
        {
            await client.SendMailAsync(message, ct);
        }
        catch (Exception ex)
        {
            // Never block auth flows on mail delivery (design §20.2 degradation rules).
            logger.LogError(ex, "SMTP delivery failed for {To}", to);
        }
    }
}
