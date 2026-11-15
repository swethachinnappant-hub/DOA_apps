using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Catalog.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "catalog");

            migrationBuilder.CreateTable(
                name: "brands",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_brands", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "categories",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    icon_emoji = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    display_order = table.Column<int>(type: "integer", nullable: false),
                    is_visible = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_categories", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "collections",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    slug = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    route = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    image_media_id = table.Column<Guid>(type: "uuid", nullable: true),
                    visible = table.Column<bool>(type: "boolean", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_collections", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "gold_rates",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    metal = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    karat = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    rate_per_gram_minor = table.Column<long>(type: "bigint", nullable: false),
                    source = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    effective_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    set_by = table.Column<Guid>(type: "uuid", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_gold_rates", x => x.id);
                    table.CheckConstraint("ck_gold_rates_metal", "metal in ('gold','silver','platinum')");
                    table.CheckConstraint("ck_gold_rates_rate", "rate_per_gram_minor > 0");
                    table.CheckConstraint("ck_gold_rates_source", "source in ('feed','manual')");
                });

            migrationBuilder.CreateTable(
                name: "stock_movements",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    on_hand_delta = table.Column<int>(type: "integer", nullable: false),
                    reserved_delta = table.Column<int>(type: "integer", nullable: false),
                    reason = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    order_id = table.Column<Guid>(type: "uuid", nullable: true),
                    actor_id = table.Column<Guid>(type: "uuid", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_stock_movements", x => x.id);
                    table.CheckConstraint("ck_stock_movements_reason", "reason in ('reserve','release','commit','restock','adjust','return','import')");
                });

            migrationBuilder.CreateTable(
                name: "taxonomy_terms",
                schema: "catalog",
                columns: table => new
                {
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    kind = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    value = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    label = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_taxonomy_terms", x => new { x.tenant_id, x.kind, x.value });
                    table.CheckConstraint("ck_taxonomy_terms_kind", "kind in ('metal','purity','family','style','audience','occasion')");
                });

            migrationBuilder.CreateTable(
                name: "products",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    seller_id = table.Column<Guid>(type: "uuid", nullable: false),
                    brand_id = table.Column<Guid>(type: "uuid", nullable: false),
                    category_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    slug = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    sku = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    seo_title = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    description = table.Column<string>(type: "text", nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    hsn_code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    pricing_mode = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    price_minor = table.Column<long>(type: "bigint", nullable: false),
                    mrp_minor = table.Column<long>(type: "bigint", nullable: false),
                    price_usd_minor = table.Column<long>(type: "bigint", nullable: false),
                    net_weight_mg = table.Column<int>(type: "integer", nullable: true),
                    gross_weight_mg = table.Column<int>(type: "integer", nullable: true),
                    stone_value_minor = table.Column<long>(type: "bigint", nullable: false),
                    making_charge_kind = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    making_charge_value = table.Column<long>(type: "bigint", nullable: true),
                    minimum_order_quantity = table.Column<int>(type: "integer", nullable: false),
                    delivery_days = table.Column<int>(type: "integer", nullable: false),
                    family = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    style = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    metal = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    purity = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    audience = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    occasions = table.Column<string[]>(type: "text[]", nullable: false),
                    highlights = table.Column<string[]>(type: "text[]", nullable: false),
                    discount_bps = table.Column<int>(type: "integer", nullable: false, computedColumnSql: "case when mrp_minor > price_minor then ((mrp_minor - price_minor) * 10000 / mrp_minor) else 0 end", stored: true),
                    rating_sum = table.Column<int>(type: "integer", nullable: false),
                    review_count = table.Column<int>(type: "integer", nullable: false),
                    search_text = table.Column<string>(type: "text", nullable: false),
                    deleted_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_products", x => x.id);
                    table.CheckConstraint("ck_products_making_charge_kind", "making_charge_kind is null or making_charge_kind in ('percent','per_gram','flat')");
                    table.CheckConstraint("ck_products_moq", "minimum_order_quantity >= 1");
                    table.CheckConstraint("ck_products_price", "price_minor >= 0 and mrp_minor >= 0");
                    table.CheckConstraint("ck_products_pricing_mode", "pricing_mode in ('fixed','weight_based')");
                    table.CheckConstraint("ck_products_status", "status in ('draft','active','archived')");
                    table.CheckConstraint("ck_products_weight_based_fields", "pricing_mode = 'fixed' or (net_weight_mg is not null and making_charge_kind is not null and making_charge_value is not null)");
                    table.CheckConstraint("ck_products_weights", "(net_weight_mg is null or net_weight_mg > 0) and (gross_weight_mg is null or gross_weight_mg > 0)");
                    table.ForeignKey(
                        name: "fk_products_brands_brand_id",
                        column: x => x.brand_id,
                        principalSchema: "catalog",
                        principalTable: "brands",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_products_categories_category_id",
                        column: x => x.category_id,
                        principalSchema: "catalog",
                        principalTable: "categories",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "collection_products",
                schema: "catalog",
                columns: table => new
                {
                    collection_id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_collection_products", x => new { x.collection_id, x.product_id });
                    table.ForeignKey(
                        name: "fk_collection_products_collections_collection_id",
                        column: x => x.collection_id,
                        principalSchema: "catalog",
                        principalTable: "collections",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "fk_collection_products_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "product_daily_stats",
                schema: "catalog",
                columns: table => new
                {
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    day = table.Column<DateOnly>(type: "date", nullable: false),
                    views = table.Column<int>(type: "integer", nullable: false),
                    wishlist_adds = table.Column<int>(type: "integer", nullable: false),
                    units_sold = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_product_daily_stats", x => new { x.product_id, x.day });
                    table.ForeignKey(
                        name: "fk_product_daily_stats_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "product_images",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    media_id = table.Column<Guid>(type: "uuid", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false),
                    alt = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_product_images", x => x.id);
                    table.ForeignKey(
                        name: "fk_product_images_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "product_specs",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    field_key = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    field_value = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_product_specs", x => x.id);
                    table.ForeignKey(
                        name: "fk_product_specs_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "product_variants",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    kind = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    swatch_hex = table.Column<string>(type: "text", nullable: true),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_product_variants", x => x.id);
                    table.CheckConstraint("ck_product_variants_kind", "kind in ('size','shade')");
                    table.ForeignKey(
                        name: "fk_product_variants_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "stock_levels",
                schema: "catalog",
                columns: table => new
                {
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    track_inventory = table.Column<bool>(type: "boolean", nullable: false),
                    on_hand = table.Column<int>(type: "integer", nullable: false),
                    reserved = table.Column<int>(type: "integer", nullable: false),
                    low_stock_threshold = table.Column<int>(type: "integer", nullable: false),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_stock_levels", x => x.product_id);
                    table.CheckConstraint("ck_stock_levels_on_hand", "on_hand >= 0");
                    table.CheckConstraint("ck_stock_levels_reserved", "reserved >= 0 and reserved <= on_hand");
                    table.ForeignKey(
                        name: "fk_stock_levels_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "wholesale_price_tiers",
                schema: "catalog",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    product_id = table.Column<Guid>(type: "uuid", nullable: false),
                    minimum_quantity = table.Column<int>(type: "integer", nullable: false),
                    unit_price_minor = table.Column<long>(type: "bigint", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_wholesale_price_tiers", x => x.id);
                    table.CheckConstraint("ck_wholesale_price_tiers_price", "unit_price_minor > 0");
                    table.CheckConstraint("ck_wholesale_price_tiers_qty", "minimum_quantity >= 2");
                    table.ForeignKey(
                        name: "fk_wholesale_price_tiers_products_product_id",
                        column: x => x.product_id,
                        principalSchema: "catalog",
                        principalTable: "products",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_brands_tenant_id_slug",
                schema: "catalog",
                table: "brands",
                columns: new[] { "tenant_id", "slug" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_categories_tenant_id_slug",
                schema: "catalog",
                table: "categories",
                columns: new[] { "tenant_id", "slug" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_collection_products_product_id",
                schema: "catalog",
                table: "collection_products",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "ix_collections_tenant_id_slug",
                schema: "catalog",
                table: "collections",
                columns: new[] { "tenant_id", "slug" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_gold_rates_tenant_id_metal_karat_effective_at",
                schema: "catalog",
                table: "gold_rates",
                columns: new[] { "tenant_id", "metal", "karat", "effective_at" },
                descending: new[] { false, false, false, true });

            migrationBuilder.CreateIndex(
                name: "ix_product_daily_stats_day",
                schema: "catalog",
                table: "product_daily_stats",
                column: "day");

            migrationBuilder.CreateIndex(
                name: "ix_product_images_media_id",
                schema: "catalog",
                table: "product_images",
                column: "media_id");

            migrationBuilder.CreateIndex(
                name: "ix_product_images_product_id_position",
                schema: "catalog",
                table: "product_images",
                columns: new[] { "product_id", "position" });

            migrationBuilder.CreateIndex(
                name: "ix_product_specs_product_id_field_key",
                schema: "catalog",
                table: "product_specs",
                columns: new[] { "product_id", "field_key" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_product_variants_product_id_kind_name",
                schema: "catalog",
                table: "product_variants",
                columns: new[] { "product_id", "kind", "name" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_products_brand",
                schema: "catalog",
                table: "products",
                column: "brand_id",
                filter: "deleted_at is null");

            migrationBuilder.CreateIndex(
                name: "ix_products_category_id",
                schema: "catalog",
                table: "products",
                column: "category_id");

            migrationBuilder.CreateIndex(
                name: "ix_products_discount",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "discount_bps", "id" },
                descending: new[] { false, true, true },
                filter: "deleted_at is null and status = 'active'");

            migrationBuilder.CreateIndex(
                name: "ix_products_metal",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "metal", "created_at", "id" },
                descending: new[] { false, false, true, true },
                filter: "deleted_at is null and status = 'active'");

            migrationBuilder.CreateIndex(
                name: "ix_products_name_trgm",
                schema: "catalog",
                table: "products",
                column: "name",
                filter: "deleted_at is null")
                .Annotation("Npgsql:IndexMethod", "gin")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ix_products_new",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "category_id", "created_at", "id" },
                descending: new[] { true, false, true, true },
                filter: "deleted_at is null and status = 'active'");

            migrationBuilder.CreateIndex(
                name: "ix_products_occasions",
                schema: "catalog",
                table: "products",
                column: "occasions")
                .Annotation("Npgsql:IndexMethod", "gin");

            migrationBuilder.CreateIndex(
                name: "ix_products_price",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "category_id", "price_minor", "id" },
                filter: "deleted_at is null and status = 'active'");

            migrationBuilder.CreateIndex(
                name: "ix_products_seller",
                schema: "catalog",
                table: "products",
                columns: new[] { "seller_id", "created_at", "id" },
                descending: new[] { false, true, true },
                filter: "deleted_at is null");

            migrationBuilder.CreateIndex(
                name: "ix_products_sku_trgm",
                schema: "catalog",
                table: "products",
                column: "sku",
                filter: "deleted_at is null")
                .Annotation("Npgsql:IndexMethod", "gin")
                .Annotation("Npgsql:IndexOperators", new[] { "gin_trgm_ops" });

            migrationBuilder.CreateIndex(
                name: "ux_products_sku",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "sku" },
                unique: true,
                filter: "deleted_at is null");

            migrationBuilder.CreateIndex(
                name: "ux_products_slug",
                schema: "catalog",
                table: "products",
                columns: new[] { "tenant_id", "slug" },
                unique: true,
                filter: "deleted_at is null");

            migrationBuilder.CreateIndex(
                name: "ix_stock_movements_order_id",
                schema: "catalog",
                table: "stock_movements",
                column: "order_id");

            migrationBuilder.CreateIndex(
                name: "ix_stock_movements_product",
                schema: "catalog",
                table: "stock_movements",
                columns: new[] { "product_id", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "ix_wholesale_price_tiers_product_id_minimum_quantity",
                schema: "catalog",
                table: "wholesale_price_tiers",
                columns: new[] { "product_id", "minimum_quantity" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "collection_products",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "gold_rates",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "product_daily_stats",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "product_images",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "product_specs",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "product_variants",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "stock_levels",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "stock_movements",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "taxonomy_terms",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "wholesale_price_tiers",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "collections",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "products",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "brands",
                schema: "catalog");

            migrationBuilder.DropTable(
                name: "categories",
                schema: "catalog");
        }
    }
}
