using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Payments.Data.Entities;

namespace Payments.Data;

public class PaymentsDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public PaymentsDbContext(DbContextOptions<PaymentsDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<Refund> Refunds => Set<Refund>();
    public DbSet<WebhookEvent> WebhookEvents => Set<WebhookEvent>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("payments");

        modelBuilder.Entity<Payment>(e =>
        {
            e.ToTable("payments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Provider).HasMaxLength(50).IsRequired();
            e.Property(x => x.ProviderOrderId).HasMaxLength(200);
            e.Property(x => x.ProviderPaymentId).HasMaxLength(200);
            e.Property(x => x.Method).HasMaxLength(50);
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.Currency).HasColumnType("char(3)");
            e.Property(x => x.FailureCode).HasMaxLength(200);

            e.HasCheckConstraint("ck_payments_status",
                "status in ('created','authorized','captured','failed','cancelled')");
            e.HasCheckConstraint("ck_payments_amount", "amount_minor > 0");

            e.HasIndex(x => new { x.Provider, x.ProviderPaymentId }).IsUnique();
            e.HasIndex(x => x.CheckoutId);
            e.HasIndex(x => new { x.Provider, x.ProviderOrderId }).IsUnique()
                .HasFilter("provider_order_id is not null")
                .HasDatabaseName("ux_payments_provider_order");
            e.HasIndex(x => x.TenantId);

            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<Refund>(e =>
        {
            e.ToTable("refunds");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.ProviderRefundId).HasMaxLength(200);
            e.Property(x => x.Reason).HasMaxLength(500);

            e.HasCheckConstraint("ck_refunds_amount", "amount_minor > 0");
            e.HasCheckConstraint("ck_refunds_status", "status in ('pending','processed','failed')");

            e.HasIndex(x => x.PaymentId);
            e.HasIndex(x => x.OrderId);
            e.HasIndex(x => x.ProviderRefundId).IsUnique();
            e.HasOne(x => x.Payment).WithMany().HasForeignKey(x => x.PaymentId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<WebhookEvent>(e =>
        {
            e.ToTable("webhook_events");
            e.HasKey(x => new { x.Provider, x.EventId });
            e.Property(x => x.Provider).HasMaxLength(50);
            e.Property(x => x.EventId).HasMaxLength(200);
            e.Property(x => x.Payload).HasColumnType("jsonb");
        });
    }
}
