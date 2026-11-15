namespace DatabaseMigrator;

/// <summary>
/// Idempotent bootstrap SQL for objects EF migrations don't own (design §3.5,
/// §5.2, §11). Everything here is safe to re-run.
/// </summary>
public static class BootstrapSql
{
    /// <summary>Before migrations: extensions the schemas depend on.</summary>
    public const string Extensions =
        """
        create extension if not exists citext;
        create extension if not exists pg_trgm;
        """;

    /// <summary>Optional (§3.5/§14): fails unless shared_preload_libraries is set — skipped on error.</summary>
    public const string PgStatStatements =
        """
        create extension if not exists pg_stat_statements;
        """;

    /// <summary>
    /// After migrations: unmapped generated column + indexes (search), HOT-update
    /// tuning on stock, and the trending materialized view the Worker refreshes.
    /// </summary>
    public const string AfterMigrations =
        """
        alter table catalog.products
            add column if not exists search_vector tsvector generated always as (
                setweight(to_tsvector('simple', name), 'A') ||
                setweight(to_tsvector('simple', sku), 'A') ||
                setweight(to_tsvector('simple', search_text), 'B') ||
                setweight(to_tsvector('simple', description), 'D')
            ) stored;

        create index if not exists ix_products_fts on catalog.products using gin (search_vector);

        alter table catalog.stock_levels set (fillfactor = 70);

        create materialized view if not exists catalog.mv_trending_30d as
            select p.tenant_id, s.product_id, sum(s.units_sold) as units_30d
            from catalog.product_daily_stats s
            join catalog.products p on p.id = s.product_id
            where s.day >= current_date - 30 and p.deleted_at is null and p.status = 'active'
            group by p.tenant_id, s.product_id;

        create unique index if not exists mv_trending_30d_key
            on catalog.mv_trending_30d (tenant_id, product_id);
        create index if not exists mv_trending_30d_units
            on catalog.mv_trending_30d (tenant_id, units_30d desc);
        """;
}
