namespace Catalog.Contracts;

public sealed record ProductVariantDto(string Kind, string Name, string? SwatchHex);
public sealed record WholesaleTierDto(int MinimumQuantity, long UnitPrice);

/// <summary>Public catalogue contract. Money values are whole rupees to match the Flutter client.</summary>
public sealed record ProductDto(
    Guid Id,
    string Name,
    string Brand,
    string Category,
    string Sku,
    long Price,
    long Mrp,
    double Rating,
    int ReviewCount,
    IReadOnlyList<string> Images,
    IReadOnlyList<ProductVariantDto> Sizes,
    IReadOnlyList<ProductVariantDto> Shades,
    IReadOnlyList<WholesaleTierDto> WholesalePriceTiers,
    IReadOnlyDictionary<string, string> Specs,
    string Description,
    int MinimumOrderQuantity,
    int DeliveryDays,
    string OwnerId,
    int Stock,
    bool InStock,
    int PriceUsd,
    string Family,
    string Style,
    string Metal,
    string Purity,
    string Audience,
    IReadOnlyList<string> Occasions,
    IReadOnlyList<string> Highlights,
    IReadOnlyList<string> Badges,
    int DiscountPercent,
    string Slug,
    string SeoTitle,
    IReadOnlyList<string> CollectionIds,
    bool IsVerifiedSupplier,
    uint Version,
    DateTime CreatedAt);

public sealed record ProductPageDto(IReadOnlyList<ProductDto> Products, string? NextCursor);
public sealed record OwnerProductSummaryDto(
    Guid Id, string Name, string Sku, long Price, long Mrp, string Status,
    int Stock, int Reserved, int MinimumOrderQuantity, uint Version, DateTime UpdatedAt);
public sealed record OwnerProductPageDto(IReadOnlyList<OwnerProductSummaryDto> Products, string? NextCursor);
public sealed record CategoryDto(Guid Id, string Name, string Slug, string? IconEmoji, int Position, string? ImageUrl);
public sealed record CollectionDto(Guid Id, string Name, string Slug, string Route, int Position, string? ImageUrl);
public sealed record SearchResponseDto(
    IReadOnlyList<ProductDto> Products,
    IReadOnlyList<CategoryDto> Categories,
    IReadOnlyList<string> Suggestions);

public sealed record WholesalePriceQuote(int MinimumQuantity, long UnitPriceMinor);
public sealed record ProductQuote(
    Guid Id, Guid TenantId, Guid SellerId, string Name, string Brand, string Sku,
    string HsnCode, string PricingMode, long PriceMinor, long MrpMinor,
    int MinimumOrderQuantity, int DeliveryDays, int AvailableStock, bool TrackInventory,
    IReadOnlyList<WholesalePriceQuote> Tiers,
    IReadOnlyList<string> Sizes, IReadOnlyList<string> Shades,
    int? NetWeightMg, long StoneValueMinor, string? MakingChargeKind, long? MakingChargeValue,
    string Metal, string Purity, string? ImageUrl);

public interface ICatalogPricing
{
    Task<IReadOnlyDictionary<Guid, ProductQuote>> GetQuotesAsync(
        IReadOnlyCollection<Guid> productIds, CancellationToken cancellationToken = default);
}
