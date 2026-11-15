using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Ordering.Data.Entities;

namespace Ordering.Data;

public class OrderingDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public OrderingDbContext(DbContextOptions<OrderingDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Ordering.Data.Entities.TaxRule> TaxRules => Set<Ordering.Data.Entities.TaxRule>();
    public DbSet<Ordering.Data.Entities.Cart> Carts => Set<Ordering.Data.Entities.Cart>();
    public DbSet<Ordering.Data.Entities.CartItem> CartItems => Set<Ordering.Data.Entities.CartItem>();
    public DbSet<Ordering.Data.Entities.Checkout> Checkouts => Set<Ordering.Data.Entities.Checkout>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<OrderStatusHistory> OrderStatusHistory => Set<OrderStatusHistory>();
    public DbSet<Shipment> Shipments => Set<Shipment>();
    public DbSet<Invoice> Invoices => Set<Invoice>();
    public DbSet<OrderReturn> OrderReturns => Set<OrderReturn>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("ordering");
        modelBuilder.HasPostgresEnum<OrderStatus>(schema: "ordering", name: "order_status");

        modelBuilder.Entity<TaxRule>(e =>
        {
            e.ToTable("tax_rules");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.HsnCode).HasMaxLength(20);
            e.Property(x => x.SupplyKind).HasMaxLength(20);
            e.Property(x => x.EffectiveFrom).HasColumnType("date");
            e.Property(x => x.EffectiveTo).HasColumnType("date");
            e.HasCheckConstraint("ck_tax_rules_supply_kind", "supply_kind in ('goods','job_work')");
            e.HasCheckConstraint("ck_tax_rules_rate", "rate_bps >= 0");
            e.HasIndex(x => new { x.TenantId, x.HsnCode, x.SupplyKind, x.EffectiveFrom }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<Ordering.Data.Entities.Cart>(e =>
        {
            e.ToTable("carts");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.CouponCode).HasColumnType("citext");
            e.HasIndex(x => x.UserId).IsUnique(); // one cart per account (design §18-7)
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<CartItem>(e =>
        {
            e.ToTable("cart_items");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.SelectedSize).HasMaxLength(100);
            e.Property(x => x.SelectedShade).HasMaxLength(100);
            e.HasCheckConstraint("ck_cart_items_quantity", "quantity > 0");
            // One line per product+size+shade (client lineKey rule); NULLs compare equal (§5.3).
            e.HasIndex(x => new { x.CartId, x.ProductId, x.SelectedSize, x.SelectedShade })
                .IsUnique().AreNullsDistinct(false).HasDatabaseName("ux_cart_items_line");
            e.HasIndex(x => x.ProductId);
            e.HasOne(x => x.Cart).WithMany(c => c.Items).HasForeignKey(x => x.CartId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Ordering.Data.Entities.Checkout>(e =>
        {
            e.ToTable("checkouts");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Currency).HasColumnType("char(3)");
            e.Property(x => x.ShippingAddress).HasColumnType("jsonb");
            e.Property(x => x.BillingAddress).HasColumnType("jsonb");
            e.Property(x => x.BuyerGstin).HasColumnName("buyer_gstin").HasMaxLength(20);
            e.Property(x => x.CouponCode).HasColumnType("citext");
            e.Property(x => x.GiftNote).HasMaxLength(500);
            e.Property(x => x.PaymentMethod).HasMaxLength(20);
            e.Property(x => x.PaymentStatus).HasMaxLength(30);
            e.HasCheckConstraint("ck_checkouts_delivery_option",
                "delivery_option in ('standard','express','priority')");
            e.HasCheckConstraint("ck_checkouts_payment_status", Ordering.Data.Entities.PaymentStatuses.Check);
            e.HasIndex(x => new { x.CustomerId, x.PlacedAt })
                .IsDescending(false, true);
            e.HasIndex(x => x.ExpiresAt)
                .HasFilter("payment_status = 'pending' and payment_method <> 'COD'")
                .HasDatabaseName("ix_checkouts_expiring");
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<Order>(e =>
        {
            e.ToTable("orders");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.OrderNumber).HasMaxLength(30);
            e.Property(x => x.Status).HasDefaultValue(OrderStatus.Placed);
            e.Property(x => x.PaymentStatus).HasMaxLength(30);
            e.Property(x => x.PaymentMethod).HasMaxLength(20);
            e.Property(x => x.DeliveryOption).HasMaxLength(20);
            e.Property(x => x.Currency).HasColumnType("char(3)");
            e.Property(x => x.CancelledReason).HasMaxLength(500);
            e.Property(x => x.Xmin).HasColumnName("xmin").IsRowVersion();

            e.HasCheckConstraint("ck_orders_payment_status", PaymentStatuses.Check);
            e.HasCheckConstraint("ck_orders_taxable", "taxable_minor = subtotal_minor - coupon_discount_minor");
            e.HasCheckConstraint("ck_orders_tax_split", "tax_minor = cgst_minor + sgst_minor + igst_minor");
            e.HasCheckConstraint("ck_orders_total",
                "total_minor = taxable_minor + tax_minor + shipping_minor + round_off_minor");

            e.HasIndex(x => x.OrderNumber).IsUnique();
            e.HasIndex(x => new { x.CustomerId, x.PlacedAt, x.Id })
                .IsDescending(false, true, true)
                .HasDatabaseName("ix_orders_customer");
            e.HasIndex(x => new { x.SellerId, x.Status, x.PlacedAt, x.Id })
                .IsDescending(false, false, true, true)
                .HasDatabaseName("ix_orders_seller");
            e.HasIndex(x => x.CheckoutId).HasDatabaseName("ix_orders_checkout");
            e.HasIndex(x => x.TenantId);

            e.HasOne(x => x.Checkout).WithMany(c => c.Orders).HasForeignKey(x => x.CheckoutId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<OrderItem>(e =>
        {
            e.ToTable("order_items");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Sku).HasMaxLength(100);
            e.Property(x => x.Name).HasMaxLength(300);
            e.Property(x => x.Brand).HasMaxLength(200);
            e.Property(x => x.HsnCode).HasMaxLength(20);
            e.Property(x => x.ImageKey).HasMaxLength(500);
            e.Property(x => x.SelectedSize).HasMaxLength(100);
            e.Property(x => x.SelectedShade).HasMaxLength(100);
            e.Property(x => x.PricingSnapshot).HasColumnType("jsonb");
            e.HasCheckConstraint("ck_order_items_quantity", "quantity > 0");
            e.HasCheckConstraint("ck_order_items_line_net", "line_net_minor = unit_price_minor * quantity");
            e.HasIndex(x => x.OrderId);
            e.HasIndex(x => x.ProductId);
            e.HasOne(x => x.Order).WithMany(o => o.Items).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<OrderStatusHistory>(e =>
        {
            e.ToTable("order_status_history");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.ActorRole).HasMaxLength(20);
            e.Property(x => x.Note).HasMaxLength(1000);
            e.HasIndex(x => new { x.OrderId, x.ChangedAt });
            e.HasOne(x => x.Order).WithMany(o => o.History).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Shipment>(e =>
        {
            e.ToTable("shipments");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Carrier).HasMaxLength(200);
            e.Property(x => x.Awb).HasMaxLength(100);
            e.Property(x => x.TrackingUrl).HasMaxLength(1000);
            e.HasIndex(x => x.OrderId);
            e.HasOne(x => x.Order).WithMany(o => o.Shipments).HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Invoice>(e =>
        {
            e.ToTable("invoices");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.FinancialYear).HasMaxLength(10);
            e.Property(x => x.InvoiceNo).HasMaxLength(30);
            e.Property(x => x.SellerGstin).HasColumnName("seller_gstin").HasMaxLength(20);
            e.Property(x => x.BuyerGstin).HasColumnName("buyer_gstin").HasMaxLength(20);
            e.Property(x => x.PlaceOfSupply).HasColumnType("char(2)");
            e.Property(x => x.Irn).HasMaxLength(64);
            e.HasIndex(x => x.OrderId).IsUnique();
            e.HasIndex(x => new { x.SellerId, x.FinancialYear, x.InvoiceNo }).IsUnique();
            e.HasOne(x => x.Order).WithOne().HasForeignKey<Invoice>(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<OrderReturn>(e =>
        {
            e.ToTable("order_returns");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Reason).HasMaxLength(1000);
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasCheckConstraint("ck_order_returns_quantity", "quantity > 0");
            e.HasCheckConstraint("ck_order_returns_status",
                "status in ('requested','approved','rejected','received','refunded')");
            e.HasIndex(x => x.OrderId);
            e.HasIndex(x => x.OrderItemId);
            e.HasOne(x => x.Order).WithMany().HasForeignKey(x => x.OrderId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.OrderItem).WithMany().HasForeignKey(x => x.OrderItemId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}
