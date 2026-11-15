using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Promotions.Data.Entities;

namespace Promotions.Data;

public class PromotionsDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public PromotionsDbContext(DbContextOptions<PromotionsDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Coupon> Coupons => Set<Coupon>();
    public DbSet<CouponRedemption> CouponRedemptions => Set<CouponRedemption>();
    public DbSet<LoyaltyAccount> LoyaltyAccounts => Set<LoyaltyAccount>();
    public DbSet<LoyaltyLedger> LoyaltyLedger => Set<LoyaltyLedger>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("promotions");

        modelBuilder.Entity<Coupon>(e =>
        {
            e.ToTable("coupons");
            e.HasKey(x => new { x.TenantId, x.Code });
            e.Property(x => x.Code).HasColumnType("citext").HasMaxLength(50);
            e.Property(x => x.Description).HasDefaultValue("");
            e.HasCheckConstraint("ck_coupons_flat_off", "flat_off_minor > 0");
            e.HasCheckConstraint("ck_coupons_min_subtotal", "min_subtotal_minor >= 0");
            e.HasCheckConstraint("ck_coupons_limits",
                "usage_limit >= 0 and per_user_limit >= 0 and used_count >= 0");
            // Every FK column gets an index (design §5.0): seller_id.
            e.HasIndex(x => x.SellerId);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<CouponRedemption>(e =>
        {
            e.ToTable("coupon_redemptions");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.CouponCode).HasColumnType("citext").HasMaxLength(50);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasCheckConstraint("ck_redemptions_status", "status in ('applied','reversed')");

            e.HasIndex(x => new { x.TenantId, x.CouponCode, x.CheckoutId }).IsUnique();
            e.HasIndex(x => new { x.UserId, x.CouponCode });
            // Composite FK to the composite-key coupon (same schema).
            e.HasOne<Coupon>().WithMany()
                .HasForeignKey(x => new { x.TenantId, x.CouponCode })
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(x => x.CheckoutId);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<LoyaltyAccount>(e =>
        {
            e.ToTable("loyalty_accounts");
            e.HasKey(x => x.UserId);
            e.HasCheckConstraint("ck_loyalty_points", "points >= 0");
        });

        modelBuilder.Entity<LoyaltyLedger>(e =>
        {
            e.ToTable("loyalty_ledger");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Reason).HasMaxLength(200);
            e.HasIndex(x => new { x.UserId, x.CreatedAt }).IsDescending(false, true);
            e.HasIndex(x => new { x.OrderId, x.Reason }).IsUnique()
                .HasFilter("order_id is not null")
                .HasDatabaseName("ux_loyalty_once");
            e.HasIndex(x => x.OrderId);
        });
    }
}
