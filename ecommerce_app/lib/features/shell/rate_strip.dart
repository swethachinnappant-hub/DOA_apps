import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/pricing.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';

/// Today's board as two side-by-side rate boxes, the way Thangamayil and
/// other jewellers board it: a warm gold-tinted box on the left, a cool
/// silver-tinted box on the right, each with the per-gram rate, plus the
/// "last updated" stamp underneath once the owner has saved. Capped at
/// 680 px and centred on wide screens. Only renders when the owner has
/// turned on the `showMetalRates` business rule (off by default).
class RateStrip extends StatelessWidget {
  const RateStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final showRates = context
        .watch<BusinessConfigProvider>()
        .config
        .rules
        .showMetalRates;
    if (!showRates) {
      return const SizedBox.shrink();
    }

    final store = context.watch<CommerceStore>();
    final gold = store.goldRateInrPerGram;
    final silver = store.silverRateInrPerGram;
    if (gold == null && silver == null) {
      return const SizedBox.shrink();
    }

    final summary = [
      if (gold != null) 'Gold ${Pricing.money(gold)} per gram',
      if (silver != null) 'Silver ${Pricing.money(silver)} per gram',
    ].join(', ');
    final stamp = store.ratesUpdatedAt;

    return Semantics(
      label: 'Today\u2019s metal rates: $summary',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.sm,
          AppSpacing.screenH,
          AppSpacing.sm,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (gold != null)
                      Expanded(
                        child: _RateBox(
                          key: const Key('rate-box-gold'),
                          label: 'GOLD RATE',
                          rate: gold,
                          accent: AppPalette.goldDark,
                          background: AppPalette.warm,
                          border: AppPalette.goldLight,
                        ),
                      ),
                    if (gold != null && silver != null)
                      const SizedBox(width: AppSpacing.sm),
                    if (silver != null)
                      Expanded(
                        child: _RateBox(
                          key: const Key('rate-box-silver'),
                          label: 'SILVER RATE',
                          rate: silver,
                          accent: AppPalette.textSecondary,
                          background: AppPalette.metalWhite,
                          border: AppPalette.divider,
                        ),
                      ),
                  ],
                ),
                if (stamp != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Last updated ${_stamp(stamp)}',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _stamp(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} '
        '${two(at.hour)}:${two(at.minute)}';
  }
}

/// One board tile: uppercase metal label with its accent bead, then the big
/// per-gram rate.
class _RateBox extends StatelessWidget {
  const _RateBox({
    super.key,
    required this.label,
    required this.rate,
    required this.accent,
    required this.background,
    required this.border,
  });

  final String label;
  final int rate;
  final Color accent;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both rows scale down rather than overflow on 320 px phones.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTypography.buttonSmall.copyWith(
                    color: accent,
                    fontSize: 10.5,
                    // §2.10: keep small-text tracking tight.
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Pricing.money(rate),
                  style: AppTypography.display.copyWith(
                    fontSize: 17,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '/ gram',
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textMuted,
                      fontSize: 10.5,
                    ),
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
