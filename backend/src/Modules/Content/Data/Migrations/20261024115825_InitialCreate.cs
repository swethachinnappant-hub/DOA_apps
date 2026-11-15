using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Content.Data.Migrations
{
    /// <inheritdoc />
    public partial class InitialCreate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "content");

            migrationBuilder.CreateTable(
                name: "hero_slides",
                schema: "content",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false),
                    title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    subtitle = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: false),
                    cta = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    location = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    image_media_id = table.Column<Guid>(type: "uuid", nullable: true),
                    enabled = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_hero_slides", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "home_section_states",
                schema: "content",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    section_id = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    visible = table.Column<bool>(type: "boolean", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_home_section_states", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "nav_menu_states",
                schema: "content",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    view = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    route = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    label = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    icon_key = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    visible = table.Column<bool>(type: "boolean", nullable: false),
                    position = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_nav_menu_states", x => x.id);
                    table.CheckConstraint("ck_nav_menu_view", "view in ('header','drawer')");
                });

            migrationBuilder.CreateTable(
                name: "store_settings",
                schema: "content",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    tenant_id = table.Column<Guid>(type: "uuid", nullable: false),
                    name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    tagline = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    currency = table.Column<string>(type: "character varying(10)", maxLength: 10, nullable: false),
                    currency_symbol = table.Column<string>(type: "character varying(5)", maxLength: 5, nullable: false),
                    primary_hex = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    secondary_hex = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    accent_hex = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    search_hint = table.Column<string>(type: "text", nullable: false, defaultValue: ""),
                    rules = table.Column<string>(type: "jsonb", nullable: false, defaultValue: "{}"),
                    product_fields = table.Column<string>(type: "jsonb", nullable: false, defaultValue: "[]"),
                    version = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    updated_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_store_settings", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "ix_hero_slides_image_media_id",
                schema: "content",
                table: "hero_slides",
                column: "image_media_id");

            migrationBuilder.CreateIndex(
                name: "ix_hero_slides_tenant_id_position",
                schema: "content",
                table: "hero_slides",
                columns: new[] { "tenant_id", "position" });

            migrationBuilder.CreateIndex(
                name: "ix_home_section_states_tenant_id_section_id",
                schema: "content",
                table: "home_section_states",
                columns: new[] { "tenant_id", "section_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_nav_menu_states_tenant_id_view_route",
                schema: "content",
                table: "nav_menu_states",
                columns: new[] { "tenant_id", "view", "route" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "ix_store_settings_tenant_id",
                schema: "content",
                table: "store_settings",
                column: "tenant_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "hero_slides",
                schema: "content");

            migrationBuilder.DropTable(
                name: "home_section_states",
                schema: "content");

            migrationBuilder.DropTable(
                name: "nav_menu_states",
                schema: "content");

            migrationBuilder.DropTable(
                name: "store_settings",
                schema: "content");
        }
    }
}
