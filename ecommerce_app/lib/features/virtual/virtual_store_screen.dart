import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/nav_helpers.dart';
import '../../core/store/commerce_store.dart';
import 'virtual_gate.dart';

class StoreHotspot {
  const StoreHotspot(this.label, this.blurb, this.icon);

  final String label;
  final String blurb;
  final IconData icon;
}

const _hotspots = <StoreHotspot>[
  StoreHotspot(
    'Welcome desk',
    'Greeted by a bridal stylist, with the day’s metal rate on display.',
    Icons.waving_hand_outlined,
  ),
  StoreHotspot(
    'Bridal vault',
    'The Bandhan and real-bride collections, shown by appointment.',
    Icons.diamond_outlined,
  ),
  StoreHotspot(
    'Gold gallery',
    'Chains, bangles and pendants in 14K, 18K and 22K yellow gold.',
    Icons.brightness_6_outlined,
  ),
  StoreHotspot(
    'Try-on lounge',
    'Sit-down mirrors with the virtual try-on screen built into the counter.',
    Icons.chair_outlined,
  ),
];

/// §10.6: virtual store — a hotspot panorama of the flagship boutique.
/// Tapping a pin opens that corner's note and the path to a real visit.
class VirtualStoreScreen extends StatefulWidget {
  const VirtualStoreScreen({super.key});

  @override
  State<VirtualStoreScreen> createState() => _VirtualStoreScreenState();
}

class _VirtualStoreScreenState extends State<VirtualStoreScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final productCount = store.shopProducts.length;

    return VirtualGate(
      title: 'Virtual Store',
      copy:
          'A 360° walkthrough of the flagship boutique, coming to this screen '
          'soon. Until then, book a real appointment through Try in Store.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap a marker to look around the boutique. Every corner is a '
            'doorway to the same pieces you find in the catalogue.',
            style: AppTypography.bodyMuted.copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          _panorama(productCount),
          const SizedBox(height: AppSpacing.lg),
          _hotspotChips(),
          const SizedBox(height: AppSpacing.lg),
          _hotspotNote(),
        ],
      ),
    );
  }

  Widget _panorama(int productCount) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppPalette.drawerSurface,
              AppPalette.copperDark,
              AppPalette.metalYellow,
            ],
          ),
          borderRadius: AppRadius.allLg,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.view_in_ar_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '360° FLAGSHIP WALKTHROUGH',
                    style: AppTypography.eyebrow.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$productCount designs on the floor right now',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _hotspots.length; i++)
              Align(
                alignment: _hotspotAlignments[i],
                child: Semantics(
                  button: true,
                  label: _hotspots[i].label,
                  child: GestureDetector(
                    key: ValueKey('store-hotspot-$i'),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selected = i);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: i == _selected
                            ? AppPalette.copper
                            : Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: AppShadows.raised,
                      ),
                      child: Icon(
                        _hotspots[i].icon,
                        size: 20,
                        color: i == _selected
                            ? Colors.white
                            : AppPalette.copperDark,
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

  static const _hotspotAlignments = <Alignment>[
    Alignment(-0.7, 0.5),
    Alignment(0.55, -0.45),
    Alignment(0.15, 0.55),
    Alignment(-0.35, -0.5),
  ];

  Widget _hotspotChips() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < _hotspots.length; i++)
          ChoiceChip(
            key: ValueKey('store-chip-$i'),
            label: Text(
              _hotspots[i].label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption,
            ),
            selected: i == _selected,
            onSelected: (_) {
              HapticFeedback.selectionClick();
              setState(() => _selected = i);
            },
            selectedColor: AppPalette.copperTint,
            side: const BorderSide(color: AppPalette.hairline),
          ),
      ],
    );
  }

  Widget _hotspotNote() {
    final hotspot = _hotspots[_selected];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppPalette.warm,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hotspot.label.toUpperCase(),
            style: AppTypography.eyebrow,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hotspot.blurb,
            style: AppTypography.bodyMuted.copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppButton(
                key: const ValueKey('store-book'),
                text: 'BOOK APPOINTMENT',
                icon: Icons.event_outlined,
                onPressed: () => navTo(context, '/tryinstore'),
              ),
              TextButton(
                onPressed: () => navTo(context, '/catalogue'),
                child: const Text('Browse the catalogue'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
