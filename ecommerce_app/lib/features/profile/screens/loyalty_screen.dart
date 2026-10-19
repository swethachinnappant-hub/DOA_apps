import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

/// Club Loyal Programme balance and ledger (§10.2).
class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  static const int balance = 1250;

  static const _ledger = [
    ('Order ORD-1042', '+120 pts', '26 Sep 2026'),
    ('Redeemed at checkout', '−300 pts', '12 Sep 2026'),
    ('Order ORD-1018', '+240 pts', '2 Sep 2026'),
    ('Welcome bonus', '+100 pts', '14 Aug 2026'),
  ];

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Loyalty Points')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: padding,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CLUB Loyal',
                      style: AppTypography.overline.copyWith(
                        color: Colors.white.withValues(alpha: .7),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '$balance points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Worth ₹$balance at checkout, up to 20% of your cart.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('RECENT ACTIVITY', style: AppTypography.overline),
              const SizedBox(height: AppSpacing.sm),
              for (final entry in _ledger)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      borderRadius: AppRadius.allSm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(entry.$1, style: AppTypography.body),
                        ),
                        Text(
                          entry.$2,
                          style: AppTypography.label.copyWith(
                            color: entry.$2.startsWith('+')
                                ? AppPalette.success
                                : AppPalette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(entry.$3, style: AppTypography.caption),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Points post after the return window closes and can be '
                'redeemed from the cart. See the CLP Terms for details.',
                style: AppTypography.caption.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
