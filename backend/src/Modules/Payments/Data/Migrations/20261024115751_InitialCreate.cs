using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Payments.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "payments");

            migrationBuilder.CreateTable(
                name: "payments",
                schema: "payments",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    checkout_id = table.Column<Guid>(type: "uuid", nullable: false),
                    provider = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    provider_order_id = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    provider_payment_id = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    method = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: true),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    amount_minor = table.Column<long>(type: "bigint", nullable: false),
                    currency = table.Column<string>(type: "char(3)", nullable: false),
                    failure_code = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_payments", x => x.id);
                    table.CheckConstraint("ck_payments_amount", "amount_minor > 0");
                    table.CheckConstraint("ck_payments_status", "status in ('created','authorized','captured','failed','cancelled')");
                });

            migrationBuilder.CreateTable(
                name: "webhook_events",
                schema: "payments",
                columns: table => new
                {
                    provider = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    event_id = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    payload = table.Column<string>(type: "jsonb", nullable: false),
                    received_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    processed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_webhook_events", x => new { x.provider, x.event_id });
                });

            migrationBuilder.CreateTable(
                name: "refunds",
                schema: "payments",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    payment_id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    amount_minor = table.Column<long>(type: "bigint", nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    provider_refund_id = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    processed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_refunds", x => x.id);
                    table.CheckConstraint("ck_refunds_amount", "amount_minor > 0");
                    table.CheckConstraint("ck_refunds_status", "status in ('pending','processed','failed')");
                    table.ForeignKey(
                        name: "fk_refunds_payments_payment_id",
                        column: x => x.payment_id,
                        principalSchema: "payments",
                        principalTable: "payments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_payments_checkout_id",
                schema: "payments",
                table: "payments",
                column: "checkout_id");

            migrationBuilder.CreateIndex(
                name: "ix_payments_provider_provider_payment_id",
                schema: "payments",
                table: "payments",
                columns: new[] { "provider", "provider_payment_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_payments_tenant_id",
                schema: "payments",
                table: "payments",
                column: "tenant_id");

            migrationBuilder.CreateIndex(
                name: "ux_payments_provider_order",
                schema: "payments",
                table: "payments",
                columns: new[] { "provider", "provider_order_id" },
                unique: true,
                filter: "provider_order_id is not null");

            migrationBuilder.CreateIndex(
                name: "ix_refunds_order_id",
                schema: "payments",
                table: "refunds",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_refunds_payment_id",
                schema: "payments",
                table: "refunds",
                column: "payment_id");

            migrationBuilder.CreateIndex(
                name: "ix_refunds_provider_refund_id",
                schema: "payments",
                table: "refunds",
                column: "provider_refund_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "refunds",
                schema: "payments");

            migrationBuilder.DropTable(
                name: "webhook_events",
                schema: "payments");

            migrationBuilder.DropTable(
                name: "payments",
                schema: "payments");
        }
    }
}
