namespace Content.Data.Entities;

/// <summary>
/// Owner-editable store config (design §5.6): branding, rules (showPrices
/// 'all'|'hidden'|'approved_only', allowScreenshots, coupons, ...) and the
/// per-business product field spec; version feeds the /meta/store-config ETag.
/// </summary>
public class StoreSettings
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string Tagline { get; set; } = "";
    public string Currency { get; set; } = "INR";
    public string CurrencySymbol { get; set; } = "₹";
    public string PrimaryHex { get; set; } = null!;
    public string SecondaryHex { get; set; } = null!;
    public string AccentHex { get; set; } = null!;
    public string SearchHint { get; set; } = "";
    public string Rules { get; set; } = "{}"; // jsonb
    public string ProductFields { get; set; } = "[]"; // jsonb — BusinessConfig.productFields
    public int Version { get; set; } = 1;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class HeroSlide
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public int Position { get; set; }
    public string Title { get; set; } = null!;
    public string Subtitle { get; set; } = null!;
    public string Cta { get; set; } = null!;
    public string Location { get; set; } = null!; // client route
    public Guid? ImageMediaId { get; set; }
    public bool Enabled { get; set; } = true;
}

/// <summary>Header/drawer visibility per route — keyed (tenant, view, route) (design §5.6).</summary>
public class NavMenuState
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string View { get; set; } = null!; // header | drawer
    public string Route { get; set; } = null!;
    public string? Label { get; set; }
    public string? IconKey { get; set; } // semantic key, not a Flutter icon code point
    public bool Visible { get; set; } = true;
    public int Position { get; set; }
}

/// <summary>Home feed section visibility/order — keyed (tenant, section_id) (design §5.6).</summary>
public class HomeSectionState
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string SectionId { get; set; } = null!; // hero | trending | deals | ...
    public bool Visible { get; set; } = true;
    public int Position { get; set; }
}
