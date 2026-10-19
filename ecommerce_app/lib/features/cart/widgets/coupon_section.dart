import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/store/commerce_store.dart';
import '../../mini_cart/coupon_tile.dart';

/// The §9.2 coupon block, lifted from the mini-cart so both surfaces gate,
/// show and apply the same codes the same way.
class CouponSection extends StatefulWidget {
  const CouponSection({
    super.key,
    required this.subtotal,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  final int subtotal;
  final String? appliedCode;
  final ValueChanged<String> onApply;
  final VoidCallback onRemove;

  @override
  State<CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends State<CouponSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final coupons = context.watch<CommerceStore>().coupons;
    if (coupons.isEmpty) return const SizedBox.shrink();
    final featured = coupons.first;
    final others = coupons.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COUPON',
          style: AppTypography.eyebrow.copyWith(
            color: AppPalette.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        CouponTile(
          coupon: featured,
          subtotal: widget.subtotal,
          isApplied: widget.appliedCode == featured.code,
          onApply: () => widget.onApply(featured.code),
          onRemove: widget.onRemove,
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => setState(() => _showAll = !_showAll),
            borderRadius: AppRadius.allXs,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Text(
                    'View all coupons',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppPalette.copperDark,
                    ),
                  ),
                  Icon(
                    _showAll ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppPalette.copperDark,
                  ),
                ],
              ),
            ),
          ),
          if (_showAll)
            for (final coupon in others) ...[
              const SizedBox(height: AppSpacing.sm),
              CouponTile(
                coupon: coupon,
                subtotal: widget.subtotal,
                isApplied: widget.appliedCode == coupon.code,
                onApply: () => widget.onApply(coupon.code),
                onRemove: widget.onRemove,
              ),
            ],
        ],
      ],
    );
  }
}
