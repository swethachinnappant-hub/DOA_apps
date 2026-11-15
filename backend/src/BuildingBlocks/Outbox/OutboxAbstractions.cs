namespace BuildingBlocks.Outbox;

/// <summary>Stages integration events / domain events as outbox rows (design §2.5).</summary>
public interface IOutbox
{
    void Enqueue(string messageType, string aggregateType, Guid aggregateId, object payload, Guid? tenantId = null);
    IReadOnlyList<OutboxEntry> Staged { get; }
    void Clear();
}

public sealed record OutboxEntry(string MessageType, string AggregateType, Guid AggregateId, string Payload, Guid? TenantId);

/// <summary>Inbox dedupe for consumers (design §2.5, §7.5).</summary>
public interface IInbox
{
    Task<bool> WasProcessedAsync(string consumer, Guid messageId, CancellationToken ct = default);
    Task MarkProcessedAsync(string consumer, Guid messageId, CancellationToken ct = default);
}
