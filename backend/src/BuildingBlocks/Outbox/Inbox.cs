using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;

namespace BuildingBlocks.Outbox;

/// <summary>
/// Inbox dedupe (design §2.5/§5.7): consumers call <see cref="WasProcessedAsync"/> before
/// handling and <see cref="MarkProcessedAsync"/> inside their own UnitOfWork —
/// the (consumer, message_id) primary key makes double delivery harmless.
/// </summary>
public sealed class Inbox(PlatformDbContext platform) : IInbox
{
    public async Task<bool> WasProcessedAsync(string consumer, Guid messageId, CancellationToken ct = default) =>
        await platform.InboxMessages
            .AsNoTracking()
            .AnyAsync(m => m.Consumer == consumer && m.MessageId == messageId, ct);

    public async Task MarkProcessedAsync(string consumer, Guid messageId, CancellationToken ct = default)
    {
        if (await WasProcessedAsync(consumer, messageId, ct)) return;
        platform.InboxMessages.Add(new Data.Platform.InboxMessage
        {
            Consumer = consumer,
            MessageId = messageId
        });
        await platform.SaveChangesAsync(ct);
    }
}
