import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';

/// SPEC-18 "Gold rate": the daily gold, silver and platinum rates per gram,
/// with a live estimate that recomputes the moment a new rate is saved — the
/// input side of SPEC-19's dynamic pricing. Saved rates board on the
/// storefront's rate strip (every layout, every shell page).
class OwnerGoldRateScreen extends StatefulWidget {
  const OwnerGoldRateScreen({super.key});

  @override
  State<OwnerGoldRateScreen> createState() => _OwnerGoldRateScreenState();
}

class _OwnerGoldRateScreenState extends State<OwnerGoldRateScreen> {
  late final TextEditingController _goldController;
  late final TextEditingController _silverController;
  late final TextEditingController _platinumController;
  late final TextEditingController _gramsController;
  late final TextEditingController _makingController;

  int _karat = 22;

  @override
  void initState() {
    super.initState();
    final store = context.read<CommerceStore>();
    _goldController = TextEditingController(
      text: store.goldRateInrPerGram?.toString() ?? '',
    );
    _silverController = TextEditingController(
      text: store.silverRateInrPerGram?.toString() ?? '',
    );
    _platinumController = TextEditingController(
      text: store.platinumRateInrPerGram?.toString() ?? '',
    );
    _gramsController = TextEditingController(text: '10');
    _makingController = TextEditingController(text: '10');
  }

  @override
  void dispose() {
    _goldController.dispose();
    _silverController.dispose();
    _platinumController.dispose();
    _gramsController.dispose();
    _makingController.dispose();
    super.dispose();
  }

  void _save() {
    final store = context.read<CommerceStore>();
    store.setRates(
      goldPerGram: int.tryParse(_goldController.text.trim()) ?? 0,
      silverPerGram: int.tryParse(_silverController.text.trim()) ?? 0,
      platinumPerGram: int.tryParse(_platinumController.text.trim()) ?? 0,
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Rates saved for today.')));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final grams = double.tryParse(_gramsController.text.trim()) ?? 0;
    final making = double.tryParse(_makingController.text.trim()) ?? 0;
    final goldRate = store.goldRateInrPerGram;
    final estimate = goldRate == null
        ? null
        : Pricing.rateEstimate(
            rateInrPerGram: goldRate,
            netGrams: grams,
            karatFactor: Pricing.karatFactor(_karat),
            makingPercent: making,
          );

    return Scaffold(
      appBar: AppBar(title: const Text('Gold rate')),
      body: ListView(
        padding: Responsive.padding(context),
        children: [
          Text(
            'Set today’s rates per gram. Saved rates drive the estimate '
            'below the moment you save.',
            style: AppTypography.bodyMuted.copyWith(height: 1.6),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _goldController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gold (₹ per gram)',
                    hintText: 'e.g. 7250',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _silverController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Silver (₹ per gram)',
                    hintText: 'e.g. 89',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _platinumController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Platinum (₹ per gram)',
                    hintText: 'e.g. 3100',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save today’s rate'),
                    ),
                    if (store.ratesUpdatedAt != null)
                      Text(
                        'Last updated ${_stamp(store.ratesUpdatedAt!)}',
                        style: AppTypography.caption.copyWith(
                          color: AppPalette.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Rate estimator', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'What today’s gold rate means for a piece, before GST.',
            style: AppTypography.caption.copyWith(color: AppPalette.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _gramsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Net weight (g)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Flexible width: a dropdown inside a Row gets unbounded
                    // main-axis constraints, which InputDecorator rejects.
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _karat,
                        decoration: const InputDecoration(labelText: 'Purity'),
                        items: [
                          for (final karat in const [24, 22, 18, 14])
                            DropdownMenuItem(
                              value: karat,
                              child: Text('${karat}K'),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _karat = value ?? 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _makingController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Making charge (%)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceMuted,
                    borderRadius: AppRadius.allMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated price',
                        style: AppTypography.caption.copyWith(
                          color: AppPalette.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estimate == null
                            ? 'Save a gold rate to estimate.'
                            : '${Pricing.money(estimate)} '
                                  '· ${_karat}K · ${grams.toStringAsFixed(2)} g',
                        style: AppTypography.display.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _stamp(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year} '
        '${two(at.hour)}:${two(at.minute)}';
  }
}
