using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Content.Data.Entities;

namespace Content.Data;

public class ContentDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public ContentDbContext(DbContextOptions<ContentDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<StoreSettings> StoreSettings => Set<StoreSettings>();
    public DbSet<HeroSlide> HeroSlides => Set<HeroSlide>();
    public DbSet<NavMenuState> NavMenuStates => Set<NavMenuState>();
    public DbSet<HomeSectionState> HomeSectionStates => Set<HomeSectionState>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("content");

        modelBuilder.Entity<StoreSettings>(e =>
        {
            e.ToTable("store_settings");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.Tagline).HasDefaultValue("");
            e.Property(x => x.Currency).HasMaxLength(10);
            e.Property(x => x.CurrencySymbol).HasMaxLength(5);
            e.Property(x => x.PrimaryHex).HasMaxLength(20);
            e.Property(x => x.SecondaryHex).HasMaxLength(20);
            e.Property(x => x.AccentHex).HasMaxLength(20);
            e.Property(x => x.SearchHint).HasDefaultValue("");
            e.Property(x => x.Rules).HasColumnType("jsonb").HasDefaultValue("{}");
            e.Property(x => x.ProductFields).HasColumnType("jsonb").HasDefaultValue("[]");
            e.Property(x => x.Version).HasDefaultValue(1);
            e.HasIndex(x => x.TenantId).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<HeroSlide>(e =>
        {
            e.ToTable("hero_slides");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Title).HasMaxLength(200);
            e.Property(x => x.Subtitle).HasMaxLength(300);
            e.Property(x => x.Cta).HasMaxLength(100);
            e.Property(x => x.Location).HasMaxLength(500);
            e.HasIndex(x => new { x.TenantId, x.Position });
            e.HasIndex(x => x.ImageMediaId);
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<NavMenuState>(e =>
        {
            e.ToTable("nav_menu_states");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.View).HasMaxLength(20);
            e.Property(x => x.Route).HasMaxLength(500);
            e.Property(x => x.Label).HasMaxLength(200);
            e.Property(x => x.IconKey).HasMaxLength(100);
            e.HasCheckConstraint("ck_nav_menu_view", "view in ('header','drawer')");
            e.HasIndex(x => new { x.TenantId, x.View, x.Route }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<HomeSectionState>(e =>
        {
            e.ToTable("home_section_states");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.SectionId).HasMaxLength(100);
            e.HasIndex(x => new { x.TenantId, x.SectionId }).IsUnique();
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });
    }
}
