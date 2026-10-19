import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/coupon.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';

/// SPEC-18 "Coupons": CRUD discount codes — flat amount, minimum subtotal,
/// validity window and a total usage limit — plus live redemption counts.
class OwnerCouponsScreen extends StatefulWidget {
  const OwnerCouponsScreen({super.key});

  @override
  State<OwnerCouponsScreen> createState() => _OwnerCouponsScreenState();
}

class _OwnerCouponsScreenState extends State<OwnerCouponsScreen> {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final coupons = store.coupons;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
        actions: [
          IconButton(
            tooltip: 'New coupon',
            icon: const Icon(Icons.add),
            onPressed: _createCoupon,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createCoupon,
        icon: const Icon(Icons.add),
        label: const Text('New coupon'),
      ),
      body: coupons.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'No coupons yet — create a code shoppers can apply at '
                  'checkout.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMuted,
                ),
              ),
            )
          : ListView.separated(
              padding: Responsive.padding(context).copyWith(bottom: 96),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final coupon = coupons[index];
                return Material(
                  color: AppPalette.surfaceMuted,
                  borderRadius: AppRadius.allMd,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.allMd,
                    ),
                    title: Text(
                      coupon.code,
                      style: AppTypography.label.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      [
                        'Flat ${Pricing.money(coupon.flatOffInr)} off · '
                        'min ${Pricing.money(coupon.minSubtotal)}',
                        _validityLabel(coupon),
                        coupon.usageLimit > 0
                            ? '${coupon.usedCount}/${coupon.usageLimit} used'
                            : 'Unlimited uses',
                      ].join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (coupon.isExhausted)
                          const Chip(label: Text('Exhausted')),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editCoupon(coupon),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(coupon),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _validityLabel(Coupon coupon) {
    String day(DateTime at) =>
        '${at.year.toString().padLeft(4, '0')}-'
        '${at.month.toString().padLeft(2, '0')}-'
        '${at.day.toString().padLeft(2, '0')}';
    if (coupon.startsAt == null && coupon.endsAt == null) {
      return 'Always on';
    }
    final start = coupon.startsAt == null ? 'open' : day(coupon.startsAt!);
    final end = coupon.endsAt == null ? 'open' : day(coupon.endsAt!);
    return '$start → $end';
  }

  Future<void> _createCoupon() => _openEditor(null);

  Future<void> _editCoupon(Coupon coupon) => _openEditor(coupon);

  Future<void> _openEditor(Coupon? existing) async {
    final store = context.read<CommerceStore>();
    final codeController = TextEditingController(text: existing?.code);
    final flatController = TextEditingController(
      text: existing == null ? '' : '${existing.flatOffInr}',
    );
    final minController = TextEditingController(
      text: existing == null ? '' : '${existing.minSubtotal}',
    );
    final limitController = TextEditingController(
      text: existing == null ? '' : '${existing.usageLimit}',
    );
    final startsController = TextEditingController(
      text: existing?.startsAt == null ? '' : _isoDay(existing!.startsAt!),
    );
    final endsController = TextEditingController(
      text: existing?.endsAt == null ? '' : _isoDay(existing!.endsAt!),
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'New coupon' : 'Edit ${existing.code}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Code',
                    hintText: 'DIAMOND200',
                  ),
                ),
                TextField(
                  controller: flatController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Flat off (₹)'),
                ),
                TextField(
                  controller: minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min subtotal (₹)',
                  ),
                ),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit (0 = unlimited)',
                  ),
                ),
                TextField(
                  controller: startsController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Starts (YYYY-MM-DD)',
                    hintText: 'Leave empty to start immediately',
                  ),
                ),
                TextField(
                  controller: endsController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Ends (YYYY-MM-DD)',
                    hintText: 'Leave empty for no end date',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved ?? false) {
      final code = codeController.text.trim().toUpperCase();
      if (code.isNotEmpty) {
        store.upsertCoupon(
          Coupon(
            code: code,
            flatOffInr: int.tryParse(flatController.text.trim()) ?? 0,
            minSubtotal: int.tryParse(minController.text.trim()) ?? 0,
            description: existing?.description ?? '',
            usageLimit: int.tryParse(limitController.text.trim()) ?? 0,
            usedCount: existing?.usedCount ?? 0,
            startsAt: DateTime.tryParse(startsController.text.trim()),
            endsAt: _inclusiveEnd(endsController.text.trim()),
          ),
        );
      }
    }

    codeController.dispose();
    flatController.dispose();
    minController.dispose();
    limitController.dispose();
    startsController.dispose();
    endsController.dispose();
  }

  static String _isoDay(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  /// An end date typed as `YYYY-MM-DD` should cover that whole day, not
  /// expire at midnight at its start.
  static DateTime? _inclusiveEnd(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  }

  Future<void> _confirmDelete(Coupon coupon) async {
    final store = context.read<CommerceStore>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${coupon.code}?'),
        content: const Text('Shoppers can no longer apply this code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) store.removeCouponCode(coupon.code);
  }
}
