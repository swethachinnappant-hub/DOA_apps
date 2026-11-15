using System.Data;
using System.Data.Common;
using BuildingBlocks.Outbox;
using Microsoft.EntityFrameworkCore;

namespace BuildingBlocks.Data;

/// <summary>
/// Per-request unit of work (design §2.3): one connection + transaction enlisted
/// across PlatformDbContext and every registered module DbContext, so outbox rows,
/// audit rows and domain rows commit atomically (all module writes with events
/// must run inside <see cref="ExecuteAsync"/>).
/// </summary>
public interface IUnitOfWork
{
    Task ExecuteAsync(Func<CancellationToken, Task> action, CancellationToken ct = default);
    Task<T> ExecuteAsync<T>(Func<CancellationToken, Task<T>> action, CancellationToken ct = default);
}

public sealed class UnitOfWork(
    PlatformDbContext platform,
    Outbox.IOutbox outbox,
    IEnumerable<IEnlistedDbContext> enlisted) : IUnitOfWork
{
    public async Task ExecuteAsync(Func<CancellationToken, Task> action, CancellationToken ct = default)
    {
        await RunAsync(async token =>
        {
            await action(token);
            return 0;
        }, ct);
    }

    public Task<T> ExecuteAsync<T>(Func<CancellationToken, Task<T>> action, CancellationToken ct = default) =>
        RunAsync(action, ct);

    private async Task<T> RunAsync<T>(Func<CancellationToken, Task<T>> action, CancellationToken ct)
    {
        var contexts = enlisted.Select(e => e.Context).Distinct().ToList();
        var connection = platform.Database.GetDbConnection();
        var openedHere = connection.State != ConnectionState.Open;
        if (openedHere) await connection.OpenAsync(ct);

        DbTransaction? transaction = null;
        try
        {
            transaction = await connection.BeginTransactionAsync(ct);
            await platform.Database.UseTransactionAsync(transaction, ct);
            foreach (var context in contexts)
            {
                if (!ReferenceEquals(context, platform))
                    await context.Database.UseTransactionAsync(transaction, ct);
            }

            var result = await action(ct);

            // Flush staged outbox rows + audit rows into the same transaction (design §2.5).
            await platform.FlushAsync(outbox, ct);

            // Wake the outbox poller — NOTIFY is delivered on commit (§2.5).
            await using (var notify = connection.CreateCommand())
            {
                notify.Transaction = transaction;
                notify.CommandText = "select pg_notify('outbox', '')";
                await notify.ExecuteNonQueryAsync(ct);
            }

            await transaction.CommitAsync(ct);
            return result;
        }
        catch
        {
            if (transaction is not null) await transaction.RollbackAsync(CancellationToken.None);
            throw;
        }
        finally
        {
            if (transaction is not null) await transaction.DisposeAsync();
            foreach (var context in contexts) context.ChangeTracker.Clear();
            platform.ChangeTracker.Clear();
            if (openedHere) await connection.CloseAsync();
        }
    }
}

/// <summary>Marker implemented by each module DbContext so the UnitOfWork can enlist it.</summary>
public interface IEnlistedDbContext
{
    DbContext Context { get; }
}
