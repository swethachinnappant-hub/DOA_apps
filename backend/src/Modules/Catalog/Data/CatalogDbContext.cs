using BuildingBlocks.Data;
using Catalog.Data.Entities;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Data;

public class CatalogDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public CatalogDbContext(DbContextOptions<CatalogDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Brand> Brands => Set<Brand>();
    public DbSet<TaxonomyTerm> TaxonomyTerms => Set<TaxonomyTerm>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<StockLevel> StockLevels => Set<StockLevel>();
    public DbSet<StockMovement> StockMovements => Set<StockMovement>();
    public DbSet<ProductImage> ProductImages => Set<ProductImage>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<WholesalePriceTier> WholesalePriceTiers => Set<WholesalePriceTier>();
    public DbSet<ProductSpec> ProductSpecs => Set<ProductSpec>();
    public DbSet<Collection> Collections => Set<Collection>();
    public DbSet<CollectionProduct> CollectionProducts => Set<CollectionProduct>();
    public DbSet<ProductDailyStat> ProductDailyStats => Set<ProductDailyStat>();
    public DbSet<GoldRate> GoldRates => Set<GoldRate>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("catalog");

        modelBuilder.Entity<Category>(e =>
        {
            e.ToTable("categories");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(200).IsRequired();
            e.Property(x => x.IconEmoji).HasMaxLength(20);
            e.HasIndex(x => new { x.TenantId, x.Slug }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<Brand>(e =>
        {
            e.ToTable("brands");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(200).IsRequired();
            e.HasIndex(x => new { x.TenantId, x.Slug }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<TaxonomyTerm>(e =>
        {
            e.ToTable("taxonomy_terms");
            e.HasKey(x => new { x.TenantId, x.Kind, x.Value });
            e.Property(x => x.Kind).HasMaxLength(20);
            e.Property(x => x.Value).HasMaxLength(100);
            e.Property(x => x.Label).HasMaxLength(200).IsRequired();
            e.HasCheckConstraint("ck_taxonomy_terms_kind",
                "kind in ('metal','purity','family','style','audience','occasion')");
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<Product>(e =>
        {
            e.ToTable("products");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();

            e.Property(x => x.Name).HasMaxLength(300).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(300).IsRequired();
            e.Property(x => x.Sku).HasMaxLength(100).IsRequired();
            e.Property(x => x.SeoTitle).HasMaxLength(300);
            e.Property(x => x.Status).HasMaxLength(20);
            e.Property(x => x.HsnCode).HasMaxLength(20);
            e.Property(x => x.PricingMode).HasMaxLength(20);
            e.Property(x => x.MakingChargeKind).HasMaxLength(20);
            e.Property(x => x.Family).HasMaxLength(100);
            e.Property(x => x.Style).HasMaxLength(100);
            e.Property(x => x.Metal).HasMaxLength(50);
            e.Property(x => x.Purity).HasMaxLength(50);
            e.Property(x => x.Audience).HasMaxLength(50);

            // Generated stored column (design §5.2) — powers `discount` sort + % OFF badge.
            e.Property(x => x.DiscountBps)
                .HasComputedColumnSql("case when mrp_minor > price_minor then ((mrp_minor - price_minor) * 10000 / mrp_minor) else 0 end",
                    stored: true);

            // Optimistic concurrency via the xmin system column (design §5.0).
            e.Property(x => x.Xmin).HasColumnName("xmin").IsRowVersion();

            e.Property(x => x.Occasions).HasColumnType("text[]");
            e.Property(x => x.Highlights).HasColumnType("text[]");

            e.HasCheckConstraint("ck_products_status", "status in ('draft','active','archived')");
            e.HasCheckConstraint("ck_products_pricing_mode", "pricing_mode in ('fixed','weight_based')");
            e.HasCheckConstraint("ck_products_making_charge_kind",
                "making_charge_kind is null or making_charge_kind in ('percent','per_gram','flat')");
            e.HasCheckConstraint("ck_products_price", "price_minor >= 0 and mrp_minor >= 0");
            e.HasCheckConstraint("ck_products_moq", "minimum_order_quantity >= 1");
            e.HasCheckConstraint("ck_products_weights",
                "(net_weight_mg is null or net_weight_mg > 0) and (gross_weight_mg is null or gross_weight_mg > 0)");
            e.HasCheckConstraint("ck_products_weight_based_fields",
                "pricing_mode = 'fixed' or (net_weight_mg is not null and making_charge_kind is not null and making_charge_value is not null)");

            // Uniqueness only among live rows (soft delete must not block re-use).
            e.HasIndex(x => new { x.TenantId, x.Slug }).IsUnique()
                .HasFilter("deleted_at is null").HasDatabaseName("ux_products_slug");
            e.HasIndex(x => new { x.TenantId, x.Sku }).IsUnique()
                .HasFilter("deleted_at is null").HasDatabaseName("ux_products_sku");

            // Keyset-friendly listing indexes: filter column(s), then sort key, then id.
            e.HasIndex(x => new { x.TenantId, x.CategoryId, x.CreatedAt, x.Id })
                .IsDescending(true, false, true, true)
                .HasFilter("deleted_at is null and status = 'active'").HasDatabaseName("ix_products_new");
            e.HasIndex(x => new { x.TenantId, x.CategoryId, x.PriceMinor, x.Id })
                .HasFilter("deleted_at is null and status = 'active'").HasDatabaseName("ix_products_price");
            e.HasIndex(x => new { x.TenantId, x.Metal, x.CreatedAt, x.Id })
                .IsDescending(false, false, true, true)
                .HasFilter("deleted_at is null and status = 'active'").HasDatabaseName("ix_products_metal");
            e.HasIndex(x => new { x.SellerId, x.CreatedAt, x.Id })
                .IsDescending(false, true, true)
                .HasFilter("deleted_at is null").HasDatabaseName("ix_products_seller");
            e.HasIndex(x => x.BrandId).HasFilter("deleted_at is null").HasDatabaseName("ix_products_brand");
            e.HasIndex(x => new { x.TenantId, x.DiscountBps, x.Id })
                .IsDescending(false, true, true)
                .HasFilter("deleted_at is null and status = 'active'").HasDatabaseName("ix_products_discount");

            // Typo-tolerant search (design §11) — pg_trgm GIN; the tsvector column and
            // its GIN index are added by the idempotent SQL bootstrap (unmapped column).
            e.HasIndex(x => x.Name).HasMethod("gin").HasOperators("gin_trgm_ops")
                .HasFilter("deleted_at is null").HasDatabaseName("ix_products_name_trgm");
            e.HasIndex(x => x.Sku).HasMethod("gin").HasOperators("gin_trgm_ops")
                .HasFilter("deleted_at is null").HasDatabaseName("ix_products_sku_trgm");
            e.HasIndex(x => x.Occasions).HasMethod("gin").HasDatabaseName("ix_products_occasions");

            e.HasOne(x => x.Brand).WithMany().HasForeignKey(x => x.BrandId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Category).WithMany().HasForeignKey(x => x.CategoryId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(x => x.Stock).WithOne(x => x.Product).HasForeignKey<StockLevel>(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);

            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<StockLevel>(e =>
        {
            e.ToTable("stock_levels");
            e.HasKey(x => x.ProductId);
            e.Property(x => x.ProductId).ValueGeneratedNever();
            e.HasCheckConstraint("ck_stock_levels_on_hand", "on_hand >= 0");
            e.HasCheckConstraint("ck_stock_levels_reserved", "reserved >= 0 and reserved <= on_hand");
        });

        modelBuilder.Entity<StockMovement>(e =>
        {
            e.ToTable("stock_movements");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Reason).HasMaxLength(20);
            e.HasCheckConstraint("ck_stock_movements_reason",
                "reason in ('reserve','release','commit','restock','adjust','return','import')");
            e.HasIndex(x => new { x.ProductId, x.CreatedAt }).IsDescending(false, true)
                .HasDatabaseName("ix_stock_movements_product");
            e.HasIndex(x => x.OrderId);
        });

        modelBuilder.Entity<ProductImage>(e =>
        {
            e.ToTable("product_images");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Alt).HasMaxLength(500);
            e.HasIndex(x => new { x.ProductId, x.Position });
            e.HasOne(x => x.Product).WithMany(p => p.Images).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.MediaId);
        });

        modelBuilder.Entity<ProductVariant>(e =>
        {
            e.ToTable("product_variants");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Kind).HasMaxLength(20);
            e.Property(x => x.Name).HasMaxLength(200);
            e.HasCheckConstraint("ck_product_variants_kind", "kind in ('size','shade')");
            e.HasIndex(x => new { x.ProductId, x.Kind, x.Name }).IsUnique();
            e.HasOne(x => x.Product).WithMany(p => p.Variants).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<WholesalePriceTier>(e =>
        {
            e.ToTable("wholesale_price_tiers");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.HasCheckConstraint("ck_wholesale_price_tiers_qty", "minimum_quantity >= 2");
            e.HasCheckConstraint("ck_wholesale_price_tiers_price", "unit_price_minor > 0");
            e.HasIndex(x => new { x.ProductId, x.MinimumQuantity }).IsUnique();
            e.HasOne(x => x.Product).WithMany(p => p.WholesalePriceTiers).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ProductSpec>(e =>
        {
            e.ToTable("product_specs");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.FieldKey).HasMaxLength(100);
            e.Property(x => x.FieldValue).HasMaxLength(500);
            e.HasIndex(x => new { x.ProductId, x.FieldKey }).IsUnique();
            e.HasOne(x => x.Product).WithMany(p => p.Specs).HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Collection>(e =>
        {
            e.ToTable("collections");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Slug).HasMaxLength(200).IsRequired();
            e.Property(x => x.Route).HasMaxLength(500);
            e.HasIndex(x => new { x.TenantId, x.Slug }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<CollectionProduct>(e =>
        {
            e.ToTable("collection_products");
            e.HasKey(x => new { x.CollectionId, x.ProductId });
            e.HasIndex(x => x.ProductId);
            e.HasOne(x => x.Collection).WithMany(c => c.Products).HasForeignKey(x => x.CollectionId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Product).WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ProductDailyStat>(e =>
        {
            e.ToTable("product_daily_stats");
            e.HasKey(x => new { x.ProductId, x.Day });
            e.Property(x => x.Day).HasColumnType("date");
            e.HasIndex(x => x.Day);
            e.HasOne<Product>().WithMany().HasForeignKey(x => x.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<GoldRate>(e =>
        {
            e.ToTable("gold_rates");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Metal).HasMaxLength(20);
            e.Property(x => x.Karat).HasMaxLength(10);
            e.Property(x => x.Source).HasMaxLength(20);
            e.HasCheckConstraint("ck_gold_rates_metal", "metal in ('gold','silver','platinum')");
            e.HasCheckConstraint("ck_gold_rates_source", "source in ('feed','manual')");
            e.HasCheckConstraint("ck_gold_rates_rate", "rate_per_gram_minor > 0");
            e.HasIndex(x => new { x.TenantId, x.Metal, x.Karat, x.EffectiveAt })
                .IsDescending(false, false, false, true);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });
    }
}
