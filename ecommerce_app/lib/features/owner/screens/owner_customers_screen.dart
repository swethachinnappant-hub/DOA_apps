import 'package:flutter/material.dart';

import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/models/cms.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';

/// SPEC-18 "Customers": everyone who has ordered (plus seeded accounts),
/// with loyalty-point adjustments recorded in a per-customer ledger.
class OwnerCustomersScreen extends StatefulWidget {
  const OwnerCustomersScreen({super.key});

  @override
  State<OwnerCustomersScreen> createState() => _OwnerCustomersScreenState();
}

class _OwnerCustomersScreenState extends State<OwnerCustomersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CommerceStore>();
    final query = _query.trim().toLowerCase();
    final customers = store.customers.where((customer) {
      if (query.isEmpty) return true;
      return customer.name.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: Column(
        children: [
          Padding(
            padding: Responsive.padding(context),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, phone or email',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: customers.isEmpty
                ? Center(
                    child: Text(
                      'No customers match “$_query”.',
                      style: AppTypography.bodyMuted,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final orderCount = store.allOrders
                          .where((order) =>
                              order.customerName == customer.name)
                          .length;
                      return Material(
                        color: AppPalette.surfaceMuted,
                        borderRadius: AppRadius.allMd,
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.allMd,
                          ),
                          onTap: () => _openCustomer(customer, orderCount),
                          leading: CircleAvatar(
                            backgroundColor: AppPalette.copperTint,
                            child: Text(
                              customer.name.isEmpty
                                  ? '?'
                                  : customer.name[0].toUpperCase(),
                              style: AppTypography.label.copyWith(
                                color: AppPalette.copperDark,
                              ),
                            ),
                          ),
                          title: Text(customer.name, style: AppTypography.label),
                          subtitle: Text(
                            [
                              if (customer.phone.isNotEmpty) customer.phone,
                              if (customer.email.isNotEmpty) customer.email,
                              if (customer.phone.isEmpty &&
                                  customer.email.isEmpty)
                                'No contact details',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_points(customer.points)} pts',
                                style: AppTypography.label.copyWith(
                                  color: AppPalette.goldDark,
                                ),
                              ),
                              Text(
                                '$orderCount order(s)',
                                style: AppTypography.caption.copyWith(
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _points(int value) => Pricing.money(value).replaceFirst('₹', '');

  Future<void> _openCustomer(ShopCustomer customer, int orderCount) async {
    final store = context.read<CommerceStore>();
    final deltaController = TextEditingController();
    final reasonController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void apply() {
          final delta = int.tryParse(deltaController.text.trim()) ?? 0;
          if (delta == 0) return;
          store.adjustLoyalty(customer.id, delta, reasonController.text);
          deltaController.clear();
          reasonController.clear();
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: AppTypography.display),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (customer.phone.isNotEmpty) customer.phone,
                      if (customer.email.isNotEmpty) customer.email,
                      '$orderCount order(s)',
                      'Joined ${_day(customer.joinedAt)}',
                    ].join(' · '),
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Consumer<CommerceStore>(
                    builder: (context, liveStore, _) {
                      final live = liveStore.customerById(customer.id) ??
                          customer;
                      final ledger =
                          liveStore.loyaltyLedgerFor(customer.id);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Loyalty points: ${_points(live.points)}',
                            style: AppTypography.subtitle,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: deltaController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    signed: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Adjustment (+100 / -50)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: TextField(
                                  controller: reasonController,
                                  decoration: const InputDecoration(
                                    labelText: 'Reason',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton.icon(
                            onPressed: apply,
                            icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                            label: const Text('Apply adjustment'),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text('History', style: AppTypography.eyebrow),
                          if (ledger.isEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: AppSpacing.sm),
                              child: Text(
                                'No adjustments yet.',
                                style: AppTypography.caption.copyWith(
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            )
                          else
                            for (final entry in ledger.take(6))
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.sm),
                                child: Text(
                                  '${entry.delta > 0 ? '+' : ''}'
                                  '${entry.delta} · ${entry.reason} · '
                                  '${_day(entry.at)}',
                                  style: AppTypography.caption,
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    deltaController.dispose();
    reasonController.dispose();
  }

  String _day(DateTime at) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(at.day)}/${two(at.month)}/${at.year}';
  }
}
