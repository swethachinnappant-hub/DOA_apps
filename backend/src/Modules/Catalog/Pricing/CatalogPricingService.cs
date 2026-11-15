using System.Text.Json;
using BuildingBlocks.Data;
using BuildingBlocks.Data.Platform;
using BuildingBlocks.Security;
using BuildingBlocks.Storage;
using Catalog.Contracts;
using Catalog.Data;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Pricing;

/// <summary>Batch-shaped read port used by Ordering; keeps module table access inside Catalog.</summary>
public sealed class CatalogPricingService(
    CatalogDbContext catalog,
    PlatformDbContext platform,
    ITenantContext tenant,
    IObjectStorage storage) : ICatalogPricing
{
    public async Task<IReadOnlyDictionary<Guid, ProductQuote>> GetQuotesAsync(
        IReadOnlyCollection<Guid> productIds, CancellationToken cancellationToken = default)
    {
        if (productIds.Count == 0) return new Dictionary<Guid, ProductQuote>();
        var ids = productIds.Distinct().ToArray();
        var products = await catalog.Products.AsNoTracking()
            .Where(p => ids.Contains(p.Id) && p.Status == "active" && p.DeletedAt == null)
            .Include(p => p.Brand)
            .Include(p => p.Stock)
            .Include(p => p.Variants)
            .Include(p => p.WholesalePriceTiers)
            .Include(p => p.Images)
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        var imageIds = products.Select(p => p.Images.OrderBy(i => i.Position).Select(i => (Guid?)i.MediaId).FirstOrDefault())
            .Where(id => id.HasValue).Select(id => id!.Value).Distinct().ToArray();
        var media = await platform.MediaAssets.AsNoTracking()
            .Where(m => imageIds.Contains(m.Id) && m.TenantId == tenant.TenantId && !m.IsPrivate && m.Status == "ready")
            .Select(m => new { m.Id, m.StorageKey, m.Variants })
            .ToListAsync(cancellationToken);
        var imageUrls = new Dictionary<Guid, string>();
        foreach (var asset in media)
        {
            try
            {
                using var json = JsonDocument.Parse(asset.Variants);
                imageUrls[asset.Id] = json.RootElement.TryGetProperty("medium", out var medium) && medium.ValueKind == JsonValueKind.String
                    ? medium.GetString()!
                    : storage.GetPublicUrl(asset.StorageKey);
            }
            catch (JsonException)
            {
                imageUrls[asset.Id] = storage.GetPublicUrl(asset.StorageKey);
            }
        }

        return products.ToDictionary(p => p.Id, p => new ProductQuote(
            p.Id,
            p.TenantId,
            p.SellerId,
            p.Name,
            p.Brand?.Name ?? "",
            p.Sku,
            p.HsnCode,
            p.PricingMode,
            p.PriceMinor,
            p.MrpMinor,
            p.MinimumOrderQuantity,
            p.DeliveryDays,
            p.Stock?.Available ?? 0,
            p.Stock?.TrackInventory ?? false,
            p.WholesalePriceTiers.OrderBy(t => t.MinimumQuantity)
                .Select(t => new WholesalePriceQuote(t.MinimumQuantity, t.UnitPriceMinor)).ToArray(),
            p.Variants.Where(v => v.Kind == "size").Select(v => v.Name).ToArray(),
            p.Variants.Where(v => v.Kind == "shade").Select(v => v.Name).ToArray(),
            p.NetWeightMg,
            p.StoneValueMinor,
            p.MakingChargeKind,
            p.MakingChargeValue,
            p.Metal,
            p.Purity,
            p.Images.OrderBy(i => i.Position).Select(i => imageUrls.GetValueOrDefault(i.MediaId)).FirstOrDefault()));
    }
}
