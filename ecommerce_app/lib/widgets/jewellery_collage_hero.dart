import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

import '../core/navigation/nav_helpers.dart';
import '../core/product.dart';

/// A compact, image-first editorial triptych shared by home and catalogue.
class JewelleryCollageHero extends StatelessWidget {
  const JewelleryCollageHero({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final picks = <Product>[];
    final usedImages = <String>{};
    for (final product in products) {
      if (product.images.isEmpty || !usedImages.add(product.images.first)) {
        continue;
      }
      picks.add(product);
      if (picks.length == 3) break;
    }
    if (picks.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('THE DETAILS', style: AppTypography.eyebrow),
                    const SizedBox(height: 3),
                    Text('Made to be noticed', style: AppTypography.subtitle),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => navTo(context, '/catalogue'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.only(left: 8),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Explore'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 218,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: _CollageTile(product: picks[0], lead: true),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Expanded(child: _CollageTile(product: picks[1])),
                      const SizedBox(height: 4),
                      Expanded(child: _CollageTile(product: picks[2])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollageTile extends StatelessWidget {
  const _CollageTile({required this.product, this.lead = false});

  final Product product;

  /// The wide tile carries the full multi-image gallery (swipe + dots),
  /// Tanishq-style; the two stacked tiles show their lead shot full-bleed.
  final bool lead;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPalette.surface,
      clipBehavior: Clip.antiAlias,
      borderRadius: AppRadius.allSm,
      child: InkWell(
        onTap: () => navTo(context, '/product/${product.id}'),
        child: lead && product.images.length > 1
            ? ProductImageCarousel(
                images: product.images,
                fit: BoxFit.cover,
                showDots: true,
                autoSlide: true,
                borderRadius: AppRadius.allSm,
              )
            : SizedBox.expand(
                child: Image(
                  image: product.images.first.startsWith('assets/')
                      ? AssetImage(product.images.first)
                      : NetworkImage(product.images.first) as ImageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.auto_awesome_outlined),
                ),
              ),
      ),
    );
  }
}
