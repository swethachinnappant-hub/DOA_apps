using System.Text.Json;
using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;

namespace BuildingBlocks.Outbox;

/// <summary>
/// Stages events in memory; <see cref="PlatformDbContext.FlushAsync"/> (called by
/// the UnitOfWork inside the transaction) materializes them as outbox rows.
/// </summary>
public sealed class Outbox : IOutbox
{
    private readonly List<OutboxEntry> _staged = [];

    public IReadOnlyList<OutboxEntry> Staged => _staged;

    public void Enqueue(string messageType, string aggregateType, Guid aggregateId, object payload, Guid? tenantId = null)
    {
        if (string.IsNullOrWhiteSpace(messageType)) throw new ArgumentException("Message type is required.", nameof(messageType));
        _staged.Add(new OutboxEntry(messageType, aggregateType, aggregateId, JsonSerializer.Serialize(payload), tenantId));
    }

    public void Clear() => _staged.Clear();
}

public static class PlatformDbContextOutboxExtensions
{
    /// <summary>Materialize staged events as outbox rows in this context (same tx — §2.5).</summary>
    public static async Task FlushAsync(this PlatformDbContext platform, IOutbox outbox, CancellationToken ct = default)
    {
        if (outbox.Staged.Count == 0) return;
        foreach (var entry in outbox.Staged)
            platform.OutboxMessages.Add(OutboxMessage.From(entry));
        await platform.SaveChangesAsync(ct);
        outbox.Clear();
    }

    public static async Task<long> NextSequenceAsync(this PlatformDbContext platform, string scope, CancellationToken ct = default)
    {
        // Increment-and-return in one statement (design §2.5/§4 number_sequences).
        await using var cmd = platform.Database.GetDbConnection().CreateCommand();
        cmd.Transaction = platform.Database.CurrentTransaction?.GetDbTransaction();
        cmd.CommandText =
            """
            insert into platform.number_sequences (scope, next_value)
            values (@scope, 1)
            on conflict (scope) do update set next_value = number_sequences.next_value + 1
            returning next_value
            """;
        var scopeParam = cmd.CreateParameter();
        scopeParam.ParameterName = "@scope";
        scopeParam.Value = scope;
        cmd.Parameters.Add(scopeParam);
        var connectionOpen = platform.Database.GetDbConnection().State == System.Data.ConnectionState.Open;
        if (!connectionOpen) await platform.Database.GetDbConnection().OpenAsync(ct);
        try
        {
            var result = await cmd.ExecuteScalarAsync(ct);
            return Convert.ToInt64(result);
        }
        finally
        {
            if (!connectionOpen) await platform.Database.GetDbConnection().CloseAsync();
        }
    }
}
