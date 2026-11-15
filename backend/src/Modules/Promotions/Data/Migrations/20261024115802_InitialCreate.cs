using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Promotions.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "promotions");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:PostgresExtension:citext", ",,");

            migrationBuilder.CreateTable(
                name: "coupons",
                schema: "promotions",
                columns: table => new
                {
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    code = table.Column<string>(type: "citext", maxLength: 50, nullable: false),
                    seller_id = table.Column<Guid>(type: "uuid", nullable: true),
                    flat_off_minor = table.Column<long>(type: "bigint", nullable: false),
                    min_subtotal_minor = table.Column<long>(type: "bigint", nullable: false),
                    description = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    starts_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ends_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    usage_limit = table.Column<int>(type: "integer", nullable: false),
                    per_user_limit = table.Column<int>(type: "integer", nullable: false),
                    used_count = table.Column<int>(type: "integer", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_coupons", x => new { x.tenant_id, x.code });
                    table.CheckConstraint("ck_coupons_flat_off", "flat_off_minor > 0");
                    table.CheckConstraint("ck_coupons_limits", "usage_limit >= 0 and per_user_limit >= 0 and used_count >= 0");
                    table.CheckConstraint("ck_coupons_min_subtotal", "min_subtotal_minor >= 0");
                });

            migrationBuilder.CreateTable(
                name: "loyalty_accounts",
                schema: "promotions",
                columns: table => new
                {
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    points = table.Column<int>(type: "integer", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_loyalty_accounts", x => x.user_id);
                    table.CheckConstraint("ck_loyalty_points", "points >= 0");
                });

            migrationBuilder.CreateTable(
                name: "loyalty_ledger",
                schema: "promotions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    delta = table.Column<int>(type: "integer", nullable: false),
                    balance_after = table.Column<int>(type: "integer", nullable: false),
                    reason = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_loyalty_ledger", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "coupon_redemptions",
                schema: "promotions",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    coupon_code = table.Column<string>(type: "citext", maxLength: 50, nullable: false),
                    checkout_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    discount_minor = table.Column<long>(type: "bigint", nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    reversed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_coupon_redemptions", x => x.id);
                    table.CheckConstraint("ck_redemptions_status", "status in ('applied','reversed')");
                    table.ForeignKey(
                        name: "fk_coupon_redemptions_coupons_tenant_id_coupon_code",
                        columns: x => new { x.tenant_id, x.coupon_code },
                        principalSchema: "promotions",
                        principalTable: "coupons",
                        principalColumns: new[] { "tenant_id", "code" },
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_coupon_redemptions_checkout_id",
                schema: "promotions",
                table: "coupon_redemptions",
                column: "checkout_id");

            migrationBuilder.CreateIndex(
                name: "ix_coupon_redemptions_tenant_id_coupon_code_checkout_id",
                schema: "promotions",
                table: "coupon_redemptions",
                columns: new[] { "tenant_id", "coupon_code", "checkout_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_coupon_redemptions_user_id_coupon_code",
                schema: "promotions",
                table: "coupon_redemptions",
                columns: new[] { "user_id", "coupon_code" });

            migrationBuilder.CreateIndex(
                name: "ix_coupons_seller_id",
                schema: "promotions",
                table: "coupons",
                column: "seller_id");

            migrationBuilder.CreateIndex(
                name: "ix_loyalty_ledger_order_id",
                schema: "promotions",
                table: "loyalty_ledger",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_loyalty_ledger_user_id_created_at",
                schema: "promotions",
                table: "loyalty_ledger",
                columns: new[] { "user_id", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "ux_loyalty_once",
                schema: "promotions",
                table: "loyalty_ledger",
                columns: new[] { "order_id", "reason" },
                unique: true,
                filter: "order_id is not null");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "coupon_redemptions",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "loyalty_accounts",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "loyalty_ledger",
                schema: "promotions");

            migrationBuilder.DropTable(
                name: "coupons",
                schema: "promotions");
        }
    }
}
