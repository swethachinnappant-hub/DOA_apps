import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../core/pricing.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';

/// The §9.3 landing after an order is placed: the check mark, the order id,
/// the arrival estimate and the two exits back into the shop.
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final order = store.orderById(orderId);
    final eta = (order?.placedAt ?? DateTime.now()).add(
      const Duration(days: 4),
    );
    final etaLabel =
        'Delivery by ${_weekdays[eta.weekday - 1]}, ${eta.day} ${_months[eta.month - 1]}';

    return Scaffold(
      appBar: AppBar(title: const Text('Order confirmed')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 72,
                color: AppPalette.success,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Order placed!',
                style: AppTypography.headline.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                order == null
                    ? orderId
                    : '${order.id} · ${order.itemCount} item(s)',
                style: AppTypography.subtitle.copyWith(
                  color: AppPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                etaLabel,
                style: AppTypography.caption.copyWith(
                  color: AppPalette.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (order != null && config.rules.showPrices) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${Pricing.money(order.total, currencySymbol: config.currencySymbol)} via ${order.paymentMethod}',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: 280,
                child: AppButton(
                  text: 'Track order',
                  isExpanded: true,
                  onPressed: () => context.push('/order/$orderId'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: 280,
                child: AppButton(
                  text: 'Continue shopping',
                  type: AppButtonType.outlined,
                  isExpanded: true,
                  onPressed: () => context.go('/app'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
