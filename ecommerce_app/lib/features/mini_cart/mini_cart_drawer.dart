import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/business_config.dart';
import '../../core/models/cart.dart';
import '../../core/models/cart_totals.dart';
import '../../core/pricing.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';
import 'coupon_tile.dart';

/// Opens the mini-cart: right drawer at ≥600 px, 90% bottom sheet below.
Future<void> showMiniCart(BuildContext context) {
  if (Responsive.isMobile(context)) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppPalette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.66,
        child: MiniCartBody(),
      ),
    );
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close mini cart',
    barrierColor: Colors.black54,
    pageBuilder: (dialogContext, _, _) => SafeArea(
      child: Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: AppPalette.surface,
          elevation: 16,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(20),
          ),
          child: SizedBox(
            width: 380,
            height: double.infinity,
            child: MiniCartBody(),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
  );
}

class MiniCartBody extends StatefulWidget {
  const MiniCartBody({super.key});

  @override
  State<MiniCartBody> createState() => _MiniCartBodyState();
}

class _MiniCartBodyState extends State<MiniCartBody> {
  bool _showAllCoupons = false;

  void _close() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  void _openRoute(String route) {
    final router = GoRouter.of(context);
    _close();
    router.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final config = context.watch<BusinessConfigProvider>().config;
    final rules = config.rules;
    final lines = store.cart;
    final totals = store.cartTotals;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Your Mini Cart',
                  style: AppTypography.subtitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '( ${store.cartCount} Item )',
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: _close,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (lines.isEmpty)
          Expanded(child: _emptyState(config))
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  for (final line in lines)
                    _line(
                      context,
                      store,
                      config,
                      line,
                      rules.showPrices,
                    ),
                  if (rules.coupons) ...[
                    const SizedBox(height: AppSpacing.lg),
                    _couponSection(store, store.cartSubtotal),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.md),
                  _summary(config, totals),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        if (lines.isNotEmpty)
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppPalette.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'View Cart',
                      type: AppButtonType.outlined,
                      onPressed: () => _openRoute('/cart'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: 'Quick Checkout',
                      onPressed: () => _openRoute('/checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _emptyState(BusinessConfig config) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 48,
              color: AppPalette.copperDark,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Your bag is empty', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Pieces you add will show up here.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Browse the catalogue',
              type: AppButtonType.outlined,
              onPressed: () {
                final router = GoRouter.of(context);
                _close();
                router.push('/catalogue');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    CommerceStore store,
    BusinessConfig config,
    CartItem line,
    bool showPrice,
  ) {
    final product = store.productFor(line);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: AppRadius.allSm,
            child: SizedBox(
              width: 52,
              height: 64,
              child: line.images.isEmpty
                  ? _fallback(product, config)
                  : Image.network(
                      line.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(product, config),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Qty : ${line.quantity}',
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  showPrice
                      ? 'Price ${Pricing.money(line.lineTotal, currencySymbol: config.currencySymbol)}'
                      : 'Contact for Price',
                  style: AppTypography.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.copperDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback(Product? product, BusinessConfig config) {
    return ColoredBox(
      color: AppPalette.surfaceMuted,
      child: Icon(
        product?.icon ?? config.icon,
        size: 24,
        color: AppPalette.copperDark,
      ),
    );
  }

  Widget _couponSection(CommerceStore store, int subtotal) {
    final coupons = store.coupons;
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
          subtotal: subtotal,
          isApplied: store.appliedCoupon?.code == featured.code,
          onApply: () {
            // §12.1: a successful coupon apply lands with a light impact.
            if (store.applyCoupon(featured.code)) {
              HapticFeedback.lightImpact();
            }
          },
          onRemove: store.removeCoupon,
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            onTap: () => setState(() => _showAllCoupons = !_showAllCoupons),
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
                    _showAllCoupons
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: AppPalette.copperDark,
                  ),
                ],
              ),
            ),
          ),
          if (_showAllCoupons)
            for (final coupon in others) ...[
              const SizedBox(height: AppSpacing.sm),
              CouponTile(
                coupon: coupon,
                subtotal: subtotal,
                isApplied: store.appliedCoupon?.code == coupon.code,
                onApply: () {
                  if (store.applyCoupon(coupon.code)) {
                    HapticFeedback.lightImpact();
                  }
                },
                onRemove: store.removeCoupon,
              ),
            ],
        ],
      ],
    );
  }

  Widget _summary(BusinessConfig config, CartTotals totals) {
    final showPrice = config.rules.showPrices;
    String value(int amount) => showPrice
        ? Pricing.money(amount, currencySymbol: config.currencySymbol)
        : 'Contact';

    return Column(
      children: [
        _summaryRow('Sub Total (before tax)', value(totals.subtotal)),
        if (totals.discount > 0)
          _summaryRow(
            'Coupon',
            '- ${value(totals.discount)}',
            color: AppPalette.success,
          ),
        _summaryRow('Tax', value(totals.tax)),
        if (totals.shipping > 0)
          _summaryRow(
            'Delivery',
            totals.shipping == 0 ? 'Free' : value(totals.shipping),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Grand Total', style: AppTypography.subtitle),
            Text(
              showPrice
                  ? Pricing.money(
                      totals.grandTotal,
                      currencySymbol: config.currencySymbol,
                    )
                  : 'Contact for Price',
              style: AppTypography.subtitle.copyWith(
                color: config.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
