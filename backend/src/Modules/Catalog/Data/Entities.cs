namespace Catalog.Data.Entities;

public class Category
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string? IconEmoji { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsVisible { get; set; } = true;
}

public class Brand
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
}

/// <summary>Source of truth for metals/purities/families/styles/audiences/occasions (design §5.2).</summary>
public class TaxonomyTerm
{
    public Guid TenantId { get; set; }
    public string Kind { get; set; } = null!; // metal|purity|family|style|audience|occasion
    public string Value { get; set; } = null!;
    public string Label { get; set; } = null!;
    public int Position { get; set; }
    public bool IsActive { get; set; } = true;
}

public class Product
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public Guid SellerId { get; set; }
    public Guid BrandId { get; set; }
    public Guid CategoryId { get; set; }

    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string Sku { get; set; } = null!;
    public string SeoTitle { get; set; } = "";
    public string Description { get; set; } = "";
    public string Status { get; set; } = "draft"; // draft | active | archived
    public string HsnCode { get; set; } = "7113";

    // Pricing (design §6.1) — all money in minor units (paise).
    public string PricingMode { get; set; } = "fixed"; // fixed | weight_based
    public long PriceMinor { get; set; }
    public long MrpMinor { get; set; }
    public long PriceUsdMinor { get; set; }
    public int? NetWeightMg { get; set; }
    public int? GrossWeightMg { get; set; }
    public long StoneValueMinor { get; set; }
    public string? MakingChargeKind { get; set; }  // percent | per_gram | flat
    public long? MakingChargeValue { get; set; }   // bps or minor units

    public int MinimumOrderQuantity { get; set; } = 1;
    public int DeliveryDays { get; set; } = 3;
    public string Family { get; set; } = "";
    public string Style { get; set; } = "";
    public string Metal { get; set; } = "";
    public string Purity { get; set; } = "";
    public string Audience { get; set; } = "";
    public string[] Occasions { get; set; } = [];
    public string[] Highlights { get; set; } = [];

    /// <summary>Generated stored column (design §5.2) — powers the `discount` sort + % OFF badge.</summary>
    public int DiscountBps { get; set; }

    public int RatingSum { get; set; }
    public int ReviewCount { get; set; }
    public string SearchText { get; set; } = "";

    public DateTime? DeletedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>xmin optimistic concurrency token (design §5.0) — owner PUT returns/sends it.</summary>
    public uint Xmin { get; set; }

    public Brand? Brand { get; set; }
    public Category? Category { get; set; }
    public StockLevel? Stock { get; set; }
    public List<ProductImage> Images { get; set; } = [];
    public List<ProductVariant> Variants { get; set; } = [];
    public List<WholesalePriceTier> WholesalePriceTiers { get; set; } = [];
    public List<ProductSpec> Specs { get; set; } = [];

    public bool IsDeleted => DeletedAt is not null;
}

public class StockLevel
{
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public bool TrackInventory { get; set; } = true;
    public int OnHand { get; set; }
    public int Reserved { get; set; }
    public int LowStockThreshold { get; set; } = 5;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public int Available => OnHand - Reserved;
}

/// <summary>Append-only stock ledger (design §5.2) — never update stock without a row here.</summary>
public class StockMovement
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public int OnHandDelta { get; set; }
    public int ReservedDelta { get; set; }
    public string Reason { get; set; } = null!; // reserve|release|commit|restock|adjust|return|import
    public Guid? OrderId { get; set; }
    public Guid? ActorId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ProductImage
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public Guid MediaId { get; set; }
    public int Position { get; set; }
    public string Alt { get; set; } = "";
}

public class ProductVariant
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public string Kind { get; set; } = null!; // size | shade
    public string Name { get; set; } = null!;
    public string? SwatchHex { get; set; }
    public int Position { get; set; }
}

/// <summary>Tier prices strictly decrease as minimum_quantity increases (handler rule — §5.2).</summary>
public class WholesalePriceTier
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public int MinimumQuantity { get; set; }
    public long UnitPriceMinor { get; set; }
}

/// <summary>Display specs ('Gold Purity', 'Gross Weight') — never parsed for computation (§5.2).</summary>
public class ProductSpec
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public string FieldKey { get; set; } = null!;
    public string FieldValue { get; set; } = null!;
    public int Position { get; set; }
}

public class Collection
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Name { get; set; } = null!;
    public string Slug { get; set; } = null!;
    public string Route { get; set; } = "";
    public Guid? ImageMediaId { get; set; }
    public bool Visible { get; set; } = true;
    public int Position { get; set; }
    public List<CollectionProduct> Products { get; set; } = [];
}

public class CollectionProduct
{
    public Guid CollectionId { get; set; }
    public Collection? Collection { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public int Position { get; set; }
}

/// <summary>Counters accumulated in Redis and flushed here by the Worker (design §5.2).</summary>
public class ProductDailyStat
{
    public Guid ProductId { get; set; }
    public DateOnly Day { get; set; }
    public int Views { get; set; }
    public int WishlistAdds { get; set; }
    public int UnitsSold { get; set; }
}

/// <summary>Append-only; current rate = latest row per (metal, karat) (design §5.2, §7.5).</summary>
public class GoldRate
{
    public Guid Id { get; set; }
    public Guid TenantId { get; set; }
    public string Metal { get; set; } = "gold"; // gold | silver | platinum
    public string Karat { get; set; } = null!;   // 24K | 22K | 18K | 925
    public long RatePerGramMinor { get; set; }
    public string Source { get; set; } = null!;  // feed | manual
    public DateTime EffectiveAt { get; set; } = DateTime.UtcNow;
    public Guid? SetBy { get; set; }
}
