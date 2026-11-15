using BuildingBlocks.Data.Platform;
using BuildingBlocks.Idempotency;
using Microsoft.EntityFrameworkCore;

namespace BuildingBlocks.Data;

/// <summary>
/// The platform schema (design §5.7): tenants, outbox, inbox, idempotency,
/// audit, number sequences, media registry. Each module has its own DbContext —
/// this context owns the cross-cutting tables.
/// </summary>
public class PlatformDbContext : DbContext, IEnlistedDbContext
{
    public PlatformDbContext(DbContextOptions<PlatformDbContext> options) : base(options) { }

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Tenant> Tenants => Set<Tenant>();
    public DbSet<OutboxMessage> OutboxMessages => Set<OutboxMessage>();
    public DbSet<InboxMessage> InboxMessages => Set<InboxMessage>();
    public DbSet<IdempotencyRecord> IdempotencyKeys => Set<IdempotencyRecord>();
    public DbSet<AuditLog> AuditLogs => Set<AuditLog>();
    public DbSet<NumberSequence> NumberSequences => Set<NumberSequence>();
    public DbSet<MediaAsset> MediaAssets => Set<MediaAsset>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("platform");

        modelBuilder.Entity<Tenant>(e =>
        {
            e.ToTable("tenants");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.BusinessType).HasMaxLength(50);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasIndex(x => x.Name);
        });

        modelBuilder.Entity<OutboxMessage>(e =>
        {
            e.ToTable("outbox_messages");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Payload).HasColumnType("jsonb");
            e.Property(x => x.AggregateType).HasMaxLength(100).IsRequired();
            e.Property(x => x.MessageType).HasMaxLength(200).IsRequired();
            e.Property(x => x.LastError).HasMaxLength(2000);
            e.HasIndex(x => x.NextAttemptAt)
                .HasFilter("processed_at is null")
                .HasDatabaseName("ix_outbox_pending");
        });

        modelBuilder.Entity<InboxMessage>(e =>
        {
            e.ToTable("inbox_messages");
            e.HasKey(x => new { x.Consumer, x.MessageId });
            e.Property(x => x.Consumer).HasMaxLength(200);
        });

        modelBuilder.Entity<IdempotencyRecord>(e =>
        {
            e.ToTable("idempotency_keys");
            e.HasKey(x => new { x.UserId, x.Key });
            e.Property(x => x.Key).HasMaxLength(200);
            e.Property(x => x.RequestHash).HasColumnType("bytea");
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.ResponseBody).HasColumnType("jsonb");
            e.HasCheckConstraint("ck_idempotency_status", "status in ('in_progress','completed')");
            e.HasIndex(x => x.ExpiresAt);
        });

        modelBuilder.Entity<AuditLog>(e =>
        {
            e.ToTable("audit_log");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Action).HasMaxLength(200).IsRequired();
            e.Property(x => x.EntityType).HasMaxLength(200).IsRequired();
            e.Property(x => x.Before).HasColumnType("jsonb");
            e.Property(x => x.After).HasColumnType("jsonb");
            e.Property(x => x.IpAddress).HasMaxLength(64);
            e.HasIndex(x => new { x.EntityType, x.EntityId, x.At })
                .IsDescending(false, false, true);
            e.HasIndex(x => new { x.ActorUserId, x.At })
                .IsDescending(false, true);
        });

        modelBuilder.Entity<NumberSequence>(e =>
        {
            e.ToTable("number_sequences");
            e.HasKey(x => x.Scope);
            e.Property(x => x.Scope).HasMaxLength(200);
        });

        modelBuilder.Entity<MediaAsset>(e =>
        {
            e.ToTable("media_assets");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Purpose).HasMaxLength(20);
            e.Property(x => x.StorageKey).HasMaxLength(500).IsRequired();
            e.Property(x => x.ContentType).HasMaxLength(100).IsRequired();
            e.Property(x => x.Sha256).HasColumnType("bytea");
            e.Property(x => x.BlurHash).HasMaxLength(200);
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.Variants).HasColumnType("jsonb").HasDefaultValue("{}");
            e.HasCheckConstraint("ck_media_assets_purpose",
                "purpose in ('product','category','hero','collection','invoice','kyc')");
            e.HasCheckConstraint("ck_media_assets_status", "status in ('processing','ready','failed')");
            e.HasIndex(x => new { x.SellerId, x.CreatedAt })
                .IsDescending(false, true);
            e.HasIndex(x => x.Status);
        });
    }
}
