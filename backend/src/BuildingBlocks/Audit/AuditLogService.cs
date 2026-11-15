using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Security;
using Microsoft.AspNetCore.Http;

namespace BuildingBlocks.Audit;

public interface IAuditLog
{
    /// <summary>Record a before/after snapshot of a sensitive mutation (design §2.6/§5.7).</summary>
    Task WriteAsync(string action, string entityType, Guid? entityId, object? before, object? after, CancellationToken ct = default);
}

public sealed class AuditLogService(
    PlatformDbContext platform,
    ICurrentUser currentUser,
    ITenantContext tenant,
    IHttpContextAccessor http) : IAuditLog
{
    public Task WriteAsync(string action, string entityType, Guid? entityId, object? before, object? after, CancellationToken ct = default)
    {
        var entry = AuditLog.Create(
            tenant, currentUser, action, entityType, entityId, before, after,
            http.HttpContext?.Connection.RemoteIpAddress?.ToString());
        platform.AuditLogs.Add(entry);
        return platform.SaveChangesAsync(ct);
    }
}
