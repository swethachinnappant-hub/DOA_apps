using BuildingBlocks.Data;
using Identity.Data.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;

namespace Identity.Data;

public class IdentityDbContext : DbContext, IEnlistedDbContext
{
    private readonly Guid _tenantId;

    public IdentityDbContext(DbContextOptions<IdentityDbContext> options, BuildingBlocks.Security.ITenantContext tenant)
        : base(options) => _tenantId = tenant.TenantId;

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<Seller> Sellers => Set<Seller>();
    public DbSet<User> Users => Set<User>();
    public DbSet<BuyerProfile> BuyerProfiles => Set<BuyerProfile>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Address> Addresses => Set<Address>();
    public DbSet<DeviceToken> DeviceTokens => Set<DeviceToken>();
    public DbSet<Role> Roles => Set<Role>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("identity");
        // snake_case comes from UseSnakeCaseNamingConvention() at the options level (§5.0).

        modelBuilder.Entity<Seller>(e =>
        {
            e.ToTable("sellers");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(300).IsRequired();
            e.Property(x => x.GstIn).HasColumnName("gstin").HasMaxLength(20);
            e.Property(x => x.StateCode).HasColumnType("char(2)");
            e.Property(x => x.Status).HasMaxLength(20);
            e.HasIndex(x => x.TenantId).IsUnique().HasFilter("is_platform = true");
            // Global tenant filter — _tenantId is an instance field so EF binds the
            // current scope's value per query (design §2.6).
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("users");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Email).HasColumnType("citext").HasMaxLength(320);
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.Name).HasMaxLength(200).IsRequired();
            e.Property(x => x.PasswordHash).HasMaxLength(500);
            e.HasIndex(x => new { x.TenantId, x.Email }).IsUnique();
            e.HasIndex(x => new { x.TenantId, x.Phone }).IsUnique();
            e.HasIndex(x => x.SellerId).HasFilter("seller_id is not null");
            e.HasQueryFilter(x => x.TenantId == _tenantId);
        });

        modelBuilder.Entity<BuyerProfile>(e =>
        {
            e.ToTable("buyer_profiles");
            e.HasKey(x => x.UserId);
            e.Property(x => x.BusinessName).HasMaxLength(300).IsRequired();
            e.Property(x => x.GstIn).HasColumnName("gstin").HasMaxLength(20);
            e.Property(x => x.Pan).HasMaxLength(10);
            e.Property(x => x.KycStatus).HasMaxLength(20);
            e.Property(x => x.KycMediaIds).HasColumnName("kyc_media_ids").HasColumnType("uuid[]");
            e.Property(x => x.CreditLimitMinor).HasColumnName("credit_limit_minor");
            e.Property(x => x.PaymentTermsDays).HasColumnName("payment_terms_days");
            e.HasOne(x => x.User).WithOne().HasForeignKey<BuyerProfile>(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RefreshToken>(e =>
        {
            e.ToTable("refresh_tokens");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.TokenHash).HasMaxLength(128);
            e.Property(x => x.DeviceId).HasMaxLength(200);
            e.Property(x => x.UserAgent).HasMaxLength(500);
            e.Property(x => x.CreatedIp).HasColumnName("created_ip").HasMaxLength(64);
            e.HasIndex(x => x.TokenHash).IsUnique();
            e.HasIndex(x => x.FamilyId);
            e.HasIndex(x => x.UserId).HasFilter("revoked_at is null");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Address>(e =>
        {
            e.ToTable("addresses");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Label).HasMaxLength(100);
            e.Property(x => x.ContactName).HasMaxLength(200).IsRequired();
            e.Property(x => x.Phone).HasMaxLength(20);
            e.Property(x => x.Line1).HasMaxLength(300).IsRequired();
            e.Property(x => x.Line2).HasMaxLength(300);
            e.Property(x => x.City).HasMaxLength(120).IsRequired();
            e.Property(x => x.State).HasMaxLength(120).IsRequired();
            e.Property(x => x.StateCode).HasColumnType("char(2)");
            e.Property(x => x.Pincode).HasColumnType("char(6)");
            e.Property(x => x.GstIn).HasColumnName("gstin").HasMaxLength(20);
            e.HasIndex(x => x.UserId);
            e.HasIndex(x => x.UserId).IsUnique().HasFilter("is_default").HasName("ux_addresses_default");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DeviceToken>(e =>
        {
            e.ToTable("device_tokens");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Platform).HasMaxLength(20);
            e.Property(x => x.Token).HasMaxLength(500);
            e.HasIndex(x => x.Token).IsUnique();
            e.HasIndex(x => x.UserId).HasFilter("revoked_at is null");
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Role>(e =>
        {
            e.ToTable("roles");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Name).HasMaxLength(50);
            e.HasIndex(x => x.Name).IsUnique();
        });

        modelBuilder.Entity<UserRole>(e =>
        {
            e.ToTable("user_roles");
            e.HasKey(x => new { x.UserId, x.RoleId });
            e.HasOne(x => x.User).WithMany().HasForeignKey(x => x.UserId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(x => x.Role).WithMany().HasForeignKey(x => x.RoleId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.RoleId);
        });
    }
}
