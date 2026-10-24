import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/business_config.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';
import 'virtual_gate.dart';

/// §10.6: virtual try-on — a designed viewfinder stand-in with the selected
/// piece overlaid, capture and a share action. The live camera is not wired
/// up, so the mirror is faked on a warm placeholder stage.
class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({super.key});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  String? _selectedId;
  bool _captured = false;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final products = store.shopProducts;
    Product? selected;
    for (final product in products) {
      if (product.id == _selectedId) selected = product;
    }

    return VirtualGate(
      title: 'Virtual Try-On',
      copy:
          'Point your camera at yourself and see how a design sits before you '
          'book it. The live mirror is being polished — browse the catalogue '
          'and save the pieces you want to try first.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick a piece, hold it up to the mirror and capture the look.',
            style: AppTypography.bodyMuted.copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          _picker(products),
          const SizedBox(height: AppSpacing.lg),
          _viewfinder(selected),
          const SizedBox(height: AppSpacing.lg),
          _actions(config, selected),
        ],
      ),
    );
  }

  Widget _picker(List<Product> products) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final product in products.take(8))
          ChoiceChip(
            key: ValueKey('tryon-chip-${product.id}'),
            label: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
            selected: product.id == _selectedId,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedId = product.id;
                _captured = false;
              });
            },
            selectedColor: AppPalette.copperTint,
            side: const BorderSide(color: AppPalette.hairline),
          ),
      ],
    );
  }

  Widget _viewfinder(Product? selected) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppPalette.drawerSurface,
              Color.lerp(AppPalette.drawerSurface, AppPalette.copper, 0.35)!,
            ],
          ),
          borderRadius: AppRadius.allLg,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Icon(
                Icons.accessibility_new_outlined,
                size: 96,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            if (selected != null)
              Center(
                child: Container(
                  key: const ValueKey('tryon-overlay'),
                  constraints: const BoxConstraints(maxWidth: 220),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: AppRadius.allMd,
                    boxShadow: AppShadows.lift,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 200,
                          maxHeight: 200,
                        ),
                        child: ProductImageTile(
                          url: selected.images.isEmpty
                              ? ''
                              : selected.images.first,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        selected.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_captured)
              Positioned(
                top: AppSpacing.md,
                right: AppSpacing.md,
                child: Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppPalette.success,
                      borderRadius: AppRadius.allPill,
                    ),
                    child: Text(
                      'Look captured',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actions(BusinessConfig config, Product? selected) {
    final allowShare = config.rules.allowShare;
    final showPrices = config.rules.showPrices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected != null) ...[
          Text(
            showPrices
                ? Pricing.money(
                    selected.price,
                    currencySymbol: config.currencySymbol,
                  )
                : 'Contact for Price',
            style: AppTypography.price,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              key: const ValueKey('tryon-capture'),
              text: 'CAPTURE',
              icon: Icons.camera_alt_outlined,
              onPressed: selected == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      setState(() => _captured = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Look captured — demo capture only'),
                          duration: Duration(milliseconds: 1400),
                        ),
                      );
                    },
            ),
            if (_captured && allowShare)
              AppButton(
                key: const ValueKey('tryon-share'),
                text: 'SHARE LOOK',
                icon: Icons.share,
                type: AppButtonType.outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share sheet would open here'),
                      duration: Duration(milliseconds: 1400),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
