using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Engagement.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "engagement");

            migrationBuilder.CreateTable(
                name: "notifications",
                schema: "engagement",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    title = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    body = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    route = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    data = table.Column<string>(type: "jsonb", nullable: true),
                    dedupe_key = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    is_read = table.Column<bool>(type: "boolean", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_notifications", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "reviews",
                schema: "engagement",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_item_id = table.Column<Guid>(type: "uuid", nullable: true),
                    rating = table.Column<short>(type: "smallint", nullable: false),
                    title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    body = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_reviews", x => x.id);
                    table.CheckConstraint("ck_reviews_rating", "rating between 1 and 5");
                    table.CheckConstraint("ck_reviews_status", "status in ('pending','published','rejected')");
                });

            migrationBuilder.CreateTable(
                name: "wishlists",
                schema: "engagement",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_wishlists", x => new { x.user_id, x.product_id });
                });

            migrationBuilder.CreateIndex(
                name: "ix_notif_feed",
                schema: "engagement",
                table: "notifications",
                columns: new[] { "user_id", "created_at", "id" },
                descending: new[] { false, true, true });

            migrationBuilder.CreateIndex(
                name: "ix_notif_unread",
                schema: "engagement",
                table: "notifications",
                column: "user_id",
                filter: "not is_read");

            migrationBuilder.CreateIndex(
                name: "ix_notifications_user_id_dedupe_key",
                schema: "engagement",
                table: "notifications",
                columns: new[] { "user_id", "dedupe_key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_reviews_order_item_id",
                schema: "engagement",
                table: "reviews",
                column: "order_item_id");

            migrationBuilder.CreateIndex(
                name: "ix_reviews_product_id_status_created_at",
                schema: "engagement",
                table: "reviews",
                columns: new[] { "product_id", "status", "created_at" },
                descending: new[] { false, false, true });

            migrationBuilder.CreateIndex(
                name: "ix_reviews_product_id_user_id",
                schema: "engagement",
                table: "reviews",
                columns: new[] { "product_id", "user_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_reviews_user_id",
                schema: "engagement",
                table: "reviews",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "ix_wishlists_product_id",
                schema: "engagement",
                table: "wishlists",
                column: "product_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "notifications",
                schema: "engagement");

            migrationBuilder.DropTable(
                name: "reviews",
                schema: "engagement");

            migrationBuilder.DropTable(
                name: "wishlists",
                schema: "engagement");
        }
    }
}
