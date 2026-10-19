import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/models/coupon.dart';
import '../../core/pricing.dart';

class CouponTile extends StatelessWidget {
  const CouponTile({
    super.key,
    required this.coupon,
    required this.subtotal,
    required this.isApplied,
    this.onApply,
    this.onRemove,
  });

  final Coupon coupon;
  final int subtotal;
  final bool isApplied;
  final VoidCallback? onApply;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final status = couponStatusOf(
      coupon: coupon,
      subtotal: subtotal,
      isApplied: isApplied,
    );
    final applied = status == CouponStatus.applied;

    final flat = Pricing.money(coupon.flatOffInr);
    final message = switch (status) {
      CouponStatus.needsMore =>
        'Add ${Pricing.money(coupon.missingFor(subtotal))} more to get a flat $flat off on this order.',
      CouponStatus.eligible =>
        'You\'ve unlocked a flat $flat off on this order!',
      CouponStatus.applied => 'You\'ve saved $flat on this order.',
    };

    final background = applied
        ? AppPalette.success.withValues(alpha: 0.08)
        : AppPalette.copperTint;
    final borderColor = applied
        ? AppPalette.success.withValues(alpha: 0.5)
        : AppPalette.copper.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coupon.code,
                  style: AppTypography.eyebrow.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: applied
                        ? AppPalette.success
                        : AppPalette.copperDark,
                  ),
                ),
              ),
              if (applied)
                SizedBox(
                  height: 32,
                  child: AppButton(
                    text: 'Remove',
                    type: AppButtonType.text,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textColor: AppPalette.success,
                    onPressed: onRemove,
                  ),
                )
              else
                SizedBox(
                  height: 32,
                  child: AppButton(
                    text: 'Apply',
                    type: AppButtonType.outlined,
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    onPressed: status == CouponStatus.eligible
                        ? onApply
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          // §11.5: screen readers hear the coupon state flip (eligible →
          // applied) without hunting for the tile again.
          Semantics(
            container: true,
            liveRegion: true,
            label: message,
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                fontSize: 12.5,
                color: applied ? AppPalette.success : AppPalette.textSecondary,
                fontWeight: applied ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          if (status == CouponStatus.needsMore) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.allPill,
              child: LinearProgressIndicator(
                value: coupon.minSubtotal <= 0
                    ? 1
                    : (subtotal / coupon.minSubtotal).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppPalette.surface,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppPalette.copper,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
