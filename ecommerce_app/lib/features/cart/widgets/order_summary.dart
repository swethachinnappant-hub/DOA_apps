import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/cart_totals.dart';
import '../../../core/pricing.dart';

/// The ORDER SUMMARY rows, shared by the cart page (§9.2) and the checkout
/// review step (§9.3) so every surface quotes the same grand total.
class OrderSummary extends StatelessWidget {
  const OrderSummary({
    super.key,
    required this.totals,
    required this.showPrice,
    required this.currency,
    required this.primary,
    this.onCheckout,
    this.checkoutLabel = 'Proceed to checkout',
  });

  final CartTotals totals;
  final bool showPrice;
  final String currency;
  final Color primary;
  final VoidCallback? onCheckout;
  final String checkoutLabel;

  @override
  Widget build(BuildContext context) {
    String value(int amount) => showPrice
        ? Pricing.money(amount, currencySymbol: currency)
        : 'Contact';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Sub Total (before tax)', value(totals.subtotal)),
        if (totals.discount > 0)
          _row('Coupon', '- ${value(totals.discount)}', color: AppPalette.success),
        _row('Tax', value(totals.tax)),
        if (totals.shipping > 0) _row('Delivery', value(totals.shipping)),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'Grand Total',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subtitle,
              ),
            ),
            Flexible(
              child: Text(
                showPrice
                    ? Pricing.money(
                        totals.grandTotal,
                        currencySymbol: currency,
                      )
                    : 'Contact for Price',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.subtitle.copyWith(color: primary),
              ),
            ),
          ],
        ),
        if (onCheckout != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AppButton(text: checkoutLabel, isExpanded: true, onPressed: onCheckout),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
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
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
