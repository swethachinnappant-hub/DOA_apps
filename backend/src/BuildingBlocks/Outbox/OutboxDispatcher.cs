using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using System.Data;

namespace BuildingBlocks.Outbox;

/// <summary>
/// One integration-event handler (design §2.5): the Worker resolves all
/// consumers, claims outbox rows with SKIP LOCKED inside one UnitOfWork
/// transaction, and routes each message to every consumer that can handle it
/// (inbox-deduped, so redelivery is harmless).
/// </summary>
public interface IOutboxConsumer
{
    string Name { get; }
    bool CanHandle(string messageType);
    Task HandleAsync(OutboxMessage message, CancellationToken ct = default);
}

public sealed class OutboxOptions
{
    /// <summary>Idle poll interval; cycles with work drain immediately.</summary>
    public int PollIntervalMs { get; set; } = 500;
    public int BatchSize { get; set; } = 50;
    public int MaxAttempts { get; set; } = 25;
    /// <summary>Delay before retrying a message no registered consumer handles yet.</summary>
    public int NoHandlerDelaySeconds { get; set; } = 5;
}

/// <summary>
/// Worker-side outbox dispatcher (design §2.5): FOR UPDATE SKIP LOCKED claim,
/// consumers + inbox in the same transaction, exponential backoff and
/// dead-lettering on failure. Runs only in the Worker host.
/// </summary>
public sealed class OutboxDispatcher(
    IServiceScopeFactory scopes,
    TimeProvider clock,
    IOptions<OutboxOptions> optionsAccessor,
    ILogger<OutboxDispatcher> log) : BackgroundService
{
    private readonly OutboxOptions options = optionsAccessor.Value;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var idle = TimeSpan.FromMilliseconds(options.PollIntervalMs);
        log.LogInformation(
            "Outbox dispatcher started (poll {Idle}ms, batch {Batch}, max attempts {Max})",
            idle.TotalMilliseconds, options.BatchSize, options.MaxAttempts);

        while (!stoppingToken.IsCancellationRequested)
        {
            int claimed;
            try
            {
                claimed = await DispatchOnceAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Outbox dispatch cycle crashed");
                claimed = 0;
            }

            try
            {
                // Work found → drain immediately; idle or failed → back off.
                await Task.Delay(claimed > 0 ? TimeSpan.FromMilliseconds(50) : idle, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                break;
            }
        }

        log.LogInformation("Outbox dispatcher stopped");
    }

    private async Task<int> DispatchOnceAsync(CancellationToken ct)
    {
        using var scope = scopes.CreateScope();
        var claimed = new List<OutboxMessage>();
        try
        {
            var uow = scope.ServiceProvider.GetRequiredService<IUnitOfWork>();
            var inbox = scope.ServiceProvider.GetRequiredService<IInbox>();
            var consumers = scope.ServiceProvider.GetServices<IOutboxConsumer>().ToList();
            var now = clock.GetUtcNow().UtcDateTime;

            return await uow.ExecuteAsync(async token =>
            {
                var platform = scope.ServiceProvider.GetRequiredService<PlatformDbContext>();
                claimed.AddRange(await ClaimBatchAsync(platform, now, options.BatchSize, token));
                if (claimed.Count == 0) return 0;

                var processed = 0;
                foreach (var message in claimed)
                {
                    var handled = false;
                    foreach (var consumer in consumers.Where(c => c.CanHandle(message.MessageType)))
                    {
                        if (await inbox.WasProcessedAsync(consumer.Name, message.Id, token))
                        {
                            handled = true;
                            continue;
                        }
                        await consumer.HandleAsync(message, token);
                        await inbox.MarkProcessedAsync(consumer.Name, message.Id, token);
                        handled = true;
                    }

                    if (handled)
                    {
                        message.ProcessedAt = now;
                        processed++;
                    }
                    else
                    {
                        // Nobody consumes this type (yet) — defer instead of hot-looping.
                        message.NextAttemptAt = now.AddSeconds(options.NoHandlerDelaySeconds);
                    }
                }

                await platform.SaveChangesAsync(token);
                return claimed.Count;
            }, ct);
        }
        catch (Exception ex)
        {
            log.LogError(ex, "Outbox dispatch failed for {Count} message(s)", claimed.Count);
            if (claimed.Count > 0)
                await BookFailuresAsync(scope.ServiceProvider, claimed, ex);
            return 0;
        }
    }

    /// <summary>Backoff/dead-letter bookkeeping runs in its own transaction (the claim tx rolled back).</summary>
    private async Task BookFailuresAsync(IServiceProvider provider, IReadOnlyList<OutboxMessage> claimed, Exception error)
    {
        var db = provider.GetRequiredService<PlatformDbContext>();
        var now = clock.GetUtcNow().UtcDateTime;
        var reason = error.Message.Length > 1000 ? error.Message[..1000] : error.Message;
        foreach (var message in claimed)
        {
            var attempts = message.Attempts + 1;
            var dead = attempts >= options.MaxAttempts;
            var delaySeconds = dead ? 3600 : Math.Min(Math.Pow(2, attempts), 60);
            await db.OutboxMessages
                .Where(m => m.Id == message.Id)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(m => m.Attempts, attempts)
                    .SetProperty(m => m.LastError, dead ? "dead-letter: " + reason : reason)
                    .SetProperty(m => m.NextAttemptAt, now.AddSeconds(delaySeconds)), CancellationToken.None);
        }
    }

    private static async Task<List<OutboxMessage>> ClaimBatchAsync(
        PlatformDbContext db, DateTime now, int batch, CancellationToken ct)
    {
        var connection = db.Database.GetDbConnection();
        var openedHere = connection.State != ConnectionState.Open;
        if (openedHere) await connection.OpenAsync(ct);
        try
        {
            await using var cmd = connection.CreateCommand();
            cmd.Transaction = db.Database.CurrentTransaction?.GetDbTransaction();
            cmd.CommandText =
                """
                select id, tenant_id, aggregate_type, aggregate_id, message_type, payload,
                       occurred_at, attempts, next_attempt_at, processed_at, last_error
                from platform.outbox_messages
                where processed_at is null and next_attempt_at <= @now
                order by id
                limit @batch
                for update skip locked
                """;
            AddParameter(cmd, "@now", now);
            AddParameter(cmd, "@batch", batch);

            var rows = new List<OutboxMessage>();
            await using var reader = await cmd.ExecuteReaderAsync(ct);
            while (await reader.ReadAsync(ct))
            {
                rows.Add(new OutboxMessage
                {
                    Id = reader.GetGuid(0),
                    TenantId = reader.IsDBNull(1) ? null : reader.GetGuid(1),
                    AggregateType = reader.GetString(2),
                    AggregateId = reader.GetGuid(3),
                    MessageType = reader.GetString(4),
                    Payload = reader.GetString(5),
                    OccurredAt = reader.GetDateTime(6),
                    Attempts = reader.GetInt32(7),
                    NextAttemptAt = reader.GetDateTime(8),
                    ProcessedAt = reader.IsDBNull(9) ? null : reader.GetDateTime(9),
                    LastError = reader.IsDBNull(10) ? null : reader.GetString(10)
                });
            }
            return rows;
        }
        finally
        {
            if (openedHere) await connection.CloseAsync();
        }
    }

    private static void AddParameter(System.Data.Common.DbCommand cmd, string name, object value)
    {
        var parameter = cmd.CreateParameter();
        parameter.ParameterName = name;
        parameter.Value = value;
        cmd.Parameters.Add(parameter);
    }
}
