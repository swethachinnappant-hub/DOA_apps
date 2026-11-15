using BuildingBlocks.Security;

namespace BuildingBlocks.Data.Platform;

public class Tenant
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string BusinessType { get; set; } = "jewellery";
    public string Status { get; set; } = "active"; // active | suspended
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>Design §5.7 — written only inside the UnitOfWork transaction, before pg_notify.</summary>
public class OutboxMessage
{
    public Guid Id { get; set; }
    public Guid? TenantId { get; set; }
    public string AggregateType { get; set; } = null!;
    public Guid AggregateId { get; set; }
    public string MessageType { get; set; } = null!;
    public string Payload { get; set; } = null!;
    public DateTime OccurredAt { get; set; } = DateTime.UtcNow;
    public int Attempts { get; set; }
    public DateTime NextAttemptAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
    public string? LastError { get; set; }

    public static OutboxMessage From(Outbox.OutboxEntry entry) => new()
    {
        Id = Guid.CreateVersion7(),
        TenantId = entry.TenantId,
        AggregateType = entry.AggregateType,
        AggregateId = entry.AggregateId,
        MessageType = entry.MessageType,
        Payload = entry.Payload,
        OccurredAt = DateTime.UtcNow,
        NextAttemptAt = DateTime.UtcNow
    };
}

/// <summary>Design §5.7 — PK (consumer, message_id) makes redelivery harmless.</summary>
public class InboxMessage
{
    public string Consumer { get; set; } = null!;
    public Guid MessageId { get; set; }
    public DateTime ProcessedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// Design §5.7 — PK (user_id, key); SHA-256 of method+path+body guards key reuse;
/// locked_until lets an abandoned in_progress claim be retaken.
/// </summary>
public class IdempotencyRecord
{
    public const double RetentionHours = 48;
    public static readonly TimeSpan ClaimLock = TimeSpan.FromMinutes(2);

    public Guid UserId { get; set; }
    public string Key { get; set; } = null!;
    public byte[] RequestHash { get; set; } = null!;
    public string Status { get; set; } = "in_progress"; // in_progress | completed
    public int? ResponseStatus { get; set; }
    public string? ResponseBody { get; set; }
    public DateTime? LockedUntil { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
}

/// <summary>Design §5.7 — append-only: price, stock, coupon, loyalty, KYC, role changes.</summary>
public class AuditLog
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid? ActorUserId { get; set; }
    public string? ActorRole { get; set; }
    public string Action { get; set; } = null!;
    public string EntityType { get; set; } = null!;
    public Guid? EntityId { get; set; }
    public string? Before { get; set; }
    public string? After { get; set; }
    public string? IpAddress { get; set; }
    public DateTime At { get; set; } = DateTime.UtcNow;

    public static AuditLog Create(
        ITenantContext tenant, ICurrentUser actor, string action,
        string entityType, Guid? entityId, object? before, object? after, string? ip = null)
    {
        if (!tenant.HasTenant)
            throw new InvalidOperationException("Audit writes require a tenant context.");
        return new AuditLog
        {
            Id = Guid.CreateVersion7(),
            TenantId = tenant.TenantId,
            ActorUserId = actor.IsAuthenticated && actor.UserId != Guid.Empty ? actor.UserId : null,
            ActorRole = actor.IsAuthenticated && actor.UserId != Guid.Empty ? actor.Role : "system",
            Action = action,
            EntityType = entityType,
            EntityId = entityId,
            Before = before is null ? null : System.Text.Json.JsonSerializer.Serialize(before),
            After = after is null ? null : System.Text.Json.JsonSerializer.Serialize(after),
            IpAddress = ip
        };
    }
}

/// <summary>Design §5.7 — gap-free numbering: scope 'invoice:{sellerId}:{fy}'.</summary>
public class NumberSequence
{
    public string Scope { get; set; } = null!;
    public long NextValue { get; set; } = 1;
}

/// <summary>
/// Design §5.7/§10 — media registry; variants hold the rendered URLs
/// {"thumb": w400.webp, "medium": w800.webp, "large": w1600.webp, *_jpg fallbacks}.
/// </summary>
public class MediaAsset
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid? SellerId { get; set; }
    public Guid? UploadedBy { get; set; }
    public string Purpose { get; set; } = null!; // product|category|hero|collection|invoice|kyc
    public string StorageKey { get; set; } = null!;
    public string ContentType { get; set; } = null!;
    public long Bytes { get; set; }
    public int? Width { get; set; }
    public int? Height { get; set; }
    public byte[]? Sha256 { get; set; }
    public string? BlurHash { get; set; }
    public string Status { get; set; } = "processing"; // processing | ready | failed
    public string Variants { get; set; } = "{}";
    public bool IsPrivate { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
