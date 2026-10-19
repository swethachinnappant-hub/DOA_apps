import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/coupon.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';

/// The account's coupon wallet (§10.2): every store coupon with the same
/// eligible / needs-more / applied states the mini-cart shows.
class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final padding = Responsive.padding(context);
    final subtotal = store.cartSubtotal;

    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: padding,
            children: [
              Text(
                'Coupons apply to your bag total. States update live with '
                'what is currently in your cart.',
                style: AppTypography.bodyMuted.copyWith(height: 1.6),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final coupon in store.coupons) ...[
                _CouponCard(
                  coupon: coupon,
                  status: couponStatusOf(
                    coupon: coupon,
                    subtotal: subtotal,
                    isApplied: store.appliedCoupon?.code == coupon.code,
                  ),
                  currency: config.currencySymbol,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.status,
    required this.currency,
  });

  final Coupon coupon;
  final CouponStatus status;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      CouponStatus.applied => ('Applied', AppPalette.success),
      CouponStatus.eligible => ('Eligible', AppPalette.copper),
      CouponStatus.needsMore => (
        'Add ${Pricing.money(coupon.missingFor(context.read<CommerceStore>().cartSubtotal), currencySymbol: currency)} more',
        AppPalette.textSecondary,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.allMd,
        border: Border.all(
          color: status == CouponStatus.applied
              ? AppPalette.success
              : AppPalette.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.code,
                  style: AppTypography.subtitle.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  coupon.description,
                  style: AppTypography.caption.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.allPill,
            ),
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
