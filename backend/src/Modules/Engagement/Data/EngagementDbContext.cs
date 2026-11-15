using BuildingBlocks.Data;
using Microsoft.EntityFrameworkCore;
using Engagement.Data.Entities;

namespace Engagement.Data;

public class EngagementDbContext : DbContext, IEnlistedDbContext
{
    public EngagementDbContext(DbContextOptions<EngagementDbContext> options)
        : base(options) { }

    DbContext IEnlistedDbContext.Context => this;

    public DbSet<WishlistItem> Wishlists => Set<WishlistItem>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Notification> Notifications => Set<Notification>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasDefaultSchema("engagement");

        modelBuilder.Entity<WishlistItem>(e =>
        {
            e.ToTable("wishlists");
            e.HasKey(x => new { x.UserId, x.ProductId });
            e.HasIndex(x => x.ProductId);
        });

        modelBuilder.Entity<Review>(e =>
        {
            e.ToTable("reviews");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Rating).HasColumnType("smallint");
            e.Property(x => x.Title).HasMaxLength(200);
            e.Property(x => x.Body).HasMaxLength(4000);
            e.Property(x => x.Status).HasMaxLength(20);

            e.HasCheckConstraint("ck_reviews_rating", "rating between 1 and 5");
            e.HasCheckConstraint("ck_reviews_status", "status in ('pending','published','rejected')");

            e.HasIndex(x => new { x.ProductId, x.UserId }).IsUnique();
            e.HasIndex(x => new { x.ProductId, x.Status, x.CreatedAt })
                .IsDescending(false, false, true);
            e.HasIndex(x => x.UserId);
            e.HasIndex(x => x.OrderItemId);
        });

        modelBuilder.Entity<Notification>(e =>
        {
            e.ToTable("notifications");
            e.HasKey(x => x.Id);
            e.Property(x => x.Id).ValueGeneratedNever();
            e.Property(x => x.Type).HasMaxLength(100);
            e.Property(x => x.Title).HasMaxLength(300);
            e.Property(x => x.Body).HasMaxLength(1000);
            e.Property(x => x.Route).HasMaxLength(500);
            e.Property(x => x.Data).HasColumnType("jsonb");
            e.Property(x => x.DedupeKey).HasMaxLength(200);

            // NULL dedupe keys never collide (PG default distinct-NULLs).
            e.HasIndex(x => new { x.UserId, x.DedupeKey }).IsUnique();
            e.HasIndex(x => new { x.UserId, x.CreatedAt, x.Id })
                .IsDescending(false, true, true)
                .HasDatabaseName("ix_notif_feed");
            e.HasIndex(x => x.UserId)
                .HasFilter("not is_read")
                .HasDatabaseName("ix_notif_unread");
        });
    }
}
