using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Ordering.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "ordering");

            migrationBuilder.AlterDatabase()
                .Annotation("Npgsql:Enum:ordering.order_status", "placed,confirmed,packed,shipped,out_for_delivery,delivered,cancelled,returned")
                .Annotation("Npgsql:PostgresExtension:citext", ",,");

            migrationBuilder.CreateTable(
                name: "carts",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    coupon_code = table.Column<string>(type: "citext", nullable: true),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_carts", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "checkouts",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    customer_id = table.Column<Guid>(type: "uuid", nullable: false),
                    currency = table.Column<string>(type: "char(3)", nullable: false),
                    shipping_address = table.Column<string>(type: "jsonb", nullable: false),
                    billing_address = table.Column<string>(type: "jsonb", nullable: false),
                    buyer_gstin = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    coupon_code = table.Column<string>(type: "citext", nullable: true),
                    coupon_discount_minor = table.Column<long>(type: "bigint", nullable: false),
                    grand_total_minor = table.Column<long>(type: "bigint", nullable: false),
                    delivery_option = table.Column<string>(type: "text", nullable: false),
                    gift_wrap = table.Column<bool>(type: "boolean", nullable: false),
                    gift_note = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    payment_method = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    payment_status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    expires_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    placed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_checkouts", x => x.id);
                    table.CheckConstraint("ck_checkouts_delivery_option", "delivery_option in ('standard','express','priority')");
                    table.CheckConstraint("ck_checkouts_payment_status", "payment_status in ('pending','paid','failed','refunded','partially_refunded','on_credit')");
                });

            migrationBuilder.CreateTable(
                name: "tax_rules",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    hsn_code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    supply_kind = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    rate_bps = table.Column<int>(type: "integer", nullable: false),
                    effective_from = table.Column<DateOnly>(type: "date", nullable: false),
                    effective_to = table.Column<DateOnly>(type: "date", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_tax_rules", x => x.id);
                    table.CheckConstraint("ck_tax_rules_rate", "rate_bps >= 0");
                    table.CheckConstraint("ck_tax_rules_supply_kind", "supply_kind in ('goods','job_work')");
                });

            migrationBuilder.CreateTable(
                name: "cart_items",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    cart_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    quantity = table.Column<int>(type: "integer", nullable: false),
                    selected_size = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    selected_shade = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    added_unit_price_minor = table.Column<long>(type: "bigint", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_cart_items", x => x.id);
                    table.CheckConstraint("ck_cart_items_quantity", "quantity > 0");
                    table.ForeignKey(
                        name: "fk_cart_items_carts_cart_id",
                        column: x => x.cart_id,
                        principalSchema: "ordering",
                        principalTable: "carts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "orders",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_number = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    checkout_id = table.Column<Guid>(type: "uuid", nullable: false),
                    customer_id = table.Column<Guid>(type: "uuid", nullable: false),
                    seller_id = table.Column<Guid>(type: "uuid", nullable: false),
                    customer_name = table.Column<string>(type: "text", nullable: false),
                    seller_name = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    payment_status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    payment_method = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    delivery_option = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    currency = table.Column<string>(type: "char(3)", nullable: false),
                    subtotal_minor = table.Column<long>(type: "bigint", nullable: false),
                    coupon_discount_minor = table.Column<long>(type: "bigint", nullable: false),
                    taxable_minor = table.Column<long>(type: "bigint", nullable: false),
                    cgst_minor = table.Column<long>(type: "bigint", nullable: false),
                    sgst_minor = table.Column<long>(type: "bigint", nullable: false),
                    igst_minor = table.Column<long>(type: "bigint", nullable: false),
                    tax_minor = table.Column<long>(type: "bigint", nullable: false),
                    shipping_minor = table.Column<long>(type: "bigint", nullable: false),
                    round_off_minor = table.Column<long>(type: "bigint", nullable: false),
                    total_minor = table.Column<long>(type: "bigint", nullable: false),
                    cancelled_reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    placed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_orders", x => x.id);
                    table.CheckConstraint("ck_orders_payment_status", "payment_status in ('pending','paid','failed','refunded','partially_refunded','on_credit')");
                    table.CheckConstraint("ck_orders_tax_split", "tax_minor = cgst_minor + sgst_minor + igst_minor");
                    table.CheckConstraint("ck_orders_taxable", "taxable_minor = subtotal_minor - coupon_discount_minor");
                    table.CheckConstraint("ck_orders_total", "total_minor = taxable_minor + tax_minor + shipping_minor + round_off_minor");
                    table.ForeignKey(
                        name: "fk_orders_checkouts_checkout_id",
                        column: x => x.checkout_id,
                        principalSchema: "ordering",
                        principalTable: "checkouts",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "invoices",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    seller_id = table.Column<Guid>(type: "uuid", nullable: false),
                    financial_year = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    invoice_no = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    issued_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    seller_gstin = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    buyer_gstin = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    place_of_supply = table.Column<string>(type: "char(2)", nullable: false),
                    taxable_minor = table.Column<long>(type: "bigint", nullable: false),
                    cgst_minor = table.Column<long>(type: "bigint", nullable: false),
                    sgst_minor = table.Column<long>(type: "bigint", nullable: false),
                    igst_minor = table.Column<long>(type: "bigint", nullable: false),
                    round_off_minor = table.Column<long>(type: "bigint", nullable: false),
                    total_minor = table.Column<long>(type: "bigint", nullable: false),
                    pdf_media_id = table.Column<Guid>(type: "uuid", nullable: true),
                    irn = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_invoices", x => x.id);
                    table.ForeignKey(
                        name: "fk_invoices_orders_order_id",
                        column: x => x.order_id,
                        principalSchema: "ordering",
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "order_items",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    sku = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    name = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    brand = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    hsn_code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    image_key = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    selected_size = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    selected_shade = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    quantity = table.Column<int>(type: "integer", nullable: false),
                    unit_price_minor = table.Column<long>(type: "bigint", nullable: false),
                    line_net_minor = table.Column<long>(type: "bigint", nullable: false),
                    discount_minor = table.Column<long>(type: "bigint", nullable: false),
                    tax_rate_bps = table.Column<int>(type: "integer", nullable: false),
                    tax_minor = table.Column<long>(type: "bigint", nullable: false),
                    pricing_snapshot = table.Column<string>(type: "jsonb", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_order_items", x => x.id);
                    table.CheckConstraint("ck_order_items_line_net", "line_net_minor = unit_price_minor * quantity");
                    table.CheckConstraint("ck_order_items_quantity", "quantity > 0");
                    table.ForeignKey(
                        name: "fk_order_items_orders_order_id",
                        column: x => x.order_id,
                        principalSchema: "ordering",
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "order_status_history",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    from_status = table.Column<int>(type: "integer", nullable: true),
                    to_status = table.Column<int>(type: "integer", nullable: false),
                    changed_by = table.Column<Guid>(type: "uuid", nullable: true),
                    actor_role = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    changed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    note = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_order_status_history", x => x.id);
                    table.ForeignKey(
                        name: "fk_order_status_history_orders_order_id",
                        column: x => x.order_id,
                        principalSchema: "ordering",
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "shipments",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    carrier = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    awb = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    tracking_url = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    insured_value_minor = table.Column<long>(type: "bigint", nullable: false),
                    shipped_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    delivered_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_shipments", x => x.id);
                    table.ForeignKey(
                        name: "fk_shipments_orders_order_id",
                        column: x => x.order_id,
                        principalSchema: "ordering",
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "order_returns",
                schema: "ordering",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: false),
                    order_item_id = table.Column<Guid>(type: "uuid", nullable: false),
                    quantity = table.Column<int>(type: "integer", nullable: false),
                    reason = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    refund_minor = table.Column<long>(type: "bigint", nullable: false),
                    requested_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    resolved_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_order_returns", x => x.id);
                    table.CheckConstraint("ck_order_returns_quantity", "quantity > 0");
                    table.CheckConstraint("ck_order_returns_status", "status in ('requested','approved','rejected','received','refunded')");
                    table.ForeignKey(
                        name: "fk_order_returns_order_items_order_item_id",
                        column: x => x.order_item_id,
                        principalSchema: "ordering",
                        principalTable: "order_items",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_order_returns_orders_order_id",
                        column: x => x.order_id,
                        principalSchema: "ordering",
                        principalTable: "orders",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_cart_items_product_id",
                schema: "ordering",
                table: "cart_items",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ux_cart_items_line",
                schema: "ordering",
                table: "cart_items",
                columns: new[] { "cart_id", "product_id", "selected_size", "selected_shade" },
                unique: true)
                .Annotation("Npgsql:NullsDistinct", false);

            migrationBuilder.CreateIndex(
                name: "ix_carts_user_id",
                schema: "ordering",
                table: "carts",
                column: "user_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_checkouts_customer_id_placed_at",
                schema: "ordering",
                table: "checkouts",
                columns: new[] { "customer_id", "placed_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "ix_checkouts_expiring",
                schema: "ordering",
                table: "checkouts",
                column: "expires_at",
                filter: "payment_status = 'pending' and payment_method <> 'COD'");

            migrationBuilder.CreateIndex(
                name: "ix_invoices_order_id",
                schema: "ordering",
                table: "invoices",
                column: "order_id",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_invoices_seller_id_financial_year_invoice_no",
                schema: "ordering",
                table: "invoices",
                columns: new[] { "seller_id", "financial_year", "invoice_no" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_order_items_order_id",
                schema: "ordering",
                table: "order_items",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_order_items_product_id",
                schema: "ordering",
                table: "order_items",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_order_returns_order_id",
                schema: "ordering",
                table: "order_returns",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_order_returns_order_item_id",
                schema: "ordering",
                table: "order_returns",
                column: "order_item_id");

            migrationBuilder.CreateIndex(
                name: "ix_order_status_history_order_id_changed_at",
                schema: "ordering",
                table: "order_status_history",
                columns: new[] { "order_id", "changed_at" });

            migrationBuilder.CreateIndex(
                name: "ix_orders_checkout",
                schema: "ordering",
                table: "orders",
                column: "checkout_id");

            migrationBuilder.CreateIndex(
                name: "ix_orders_customer",
                schema: "ordering",
                table: "orders",
                columns: new[] { "customer_id", "placed_at", "id" },
                descending: new[] { false, true, true });

            migrationBuilder.CreateIndex(
                name: "ix_orders_order_number",
                schema: "ordering",
                table: "orders",
                column: "order_number",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_orders_seller",
                schema: "ordering",
                table: "orders",
                columns: new[] { "seller_id", "status", "placed_at", "id" },
                descending: new[] { false, false, true, true });

            migrationBuilder.CreateIndex(
                name: "ix_orders_tenant_id",
                schema: "ordering",
                table: "orders",
                column: "tenant_id");

            migrationBuilder.CreateIndex(
                name: "ix_shipments_order_id",
                schema: "ordering",
                table: "shipments",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_tax_rules_tenant_id_hsn_code_supply_kind_effective_from",
                schema: "ordering",
                table: "tax_rules",
                columns: new[] { "tenant_id", "hsn_code", "supply_kind", "effective_from" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "cart_items",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "invoices",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "order_returns",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "order_status_history",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "shipments",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "tax_rules",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "carts",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "order_items",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "orders",
                schema: "ordering");

            migrationBuilder.DropTable(
                name: "checkouts",
                schema: "ordering");
        }
    }
}
