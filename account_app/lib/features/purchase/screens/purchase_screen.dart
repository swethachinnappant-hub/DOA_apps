import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  bool _isLoading = true;
  String _query = '';
  String _statusFilter = 'All';
  final List<Map<String, String>> _addedPurchases = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AppButton(
        text: 'New Purchase',
        icon: Icons.add,
        onPressed: () => _showAddPurchaseDialog(),
      ),
      body: _isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SkeletonGrid(itemCount: 4),
          const SizedBox(height: 16),
          const SkeletonList(itemCount: 5),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildStatsRow(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildPurchaseList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppSearchField(
      hint: 'Search by bill number, supplier...',
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      onFilterPressed: _chooseStatus,
    );
  }

  Future<void> _chooseStatus() async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ['All', 'Paid', 'Pending'])
              ListTile(
                title: Text(option),
                trailing: option == _statusFilter
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
          ],
        ),
      ),
    );
    if (status != null) setState(() => _statusFilter = status);
  }

  void _showPurchaseDetails(Map<String, dynamic> purchase) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(purchase['billNo'] as String),
        content: Text(
          'Supplier: ${purchase['supplier']}\nDate: ${purchase['date']}\nAmount: ${purchase['amount']}\nStatus: ${purchase['status']}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: "Today's Purchases",
            value: '₹85,000',
            color: Colors.blue,
            icon: Icons.shopping_bag,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: 'This Month',
            value: '₹8,75,000',
            color: Colors.purple,
            icon: Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: 'Pending',
            value: '₹2,45,000',
            color: Colors.orange,
            icon: Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildPurchaseList() {
    final purchases = [
      {
        'billNo': 'BILL/24-25/001',
        'supplier': 'Vendor A',
        'amount': '₹18,500',
        'status': 'Paid',
        'date': '11/07/2025',
      },
      {
        'billNo': 'BILL/24-25/002',
        'supplier': 'Vendor B',
        'amount': '₹32,000',
        'status': 'Pending',
        'date': '10/07/2025',
      },
      {
        'billNo': 'BILL/24-25/003',
        'supplier': 'Vendor C',
        'amount': '₹15,750',
        'status': 'Paid',
        'date': '09/07/2025',
      },
      {
        'billNo': 'BILL/24-25/004',
        'supplier': 'Vendor D',
        'amount': '₹45,000',
        'status': 'Pending',
        'date': '08/07/2025',
      },
    ];
    purchases.insertAll(0, _addedPurchases);
    final visiblePurchases = purchases
        .where(
          (purchase) =>
              '${purchase['billNo']} ${purchase['supplier']}'
                  .toLowerCase()
                  .contains(_query) &&
              (_statusFilter == 'All' || purchase['status'] == _statusFilter),
        )
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Recent Purchases'),
          const SizedBox(height: 8),
          ...visiblePurchases.map(
            (p) => AmountListTile(
              title: p['billNo']!,
              subtitle: '${p['supplier']} • ${p['date']}',
              amount: p['amount']!,
              status: p['status'],
              statusColor: _getStatusColor(p['status']!),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              onTap: () => _showPurchaseDetails(p),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showAddPurchaseDialog() async {
    final supplier = TextEditingController();
    final bill = TextEditingController();
    final date = TextEditingController(
      text: MaterialLocalizations.of(context).formatShortDate(DateTime.now()),
    );
    final amount = TextEditingController();
    await AppDialog.bottomSheet(
      context,
      title: 'New Purchase Entry',
      content: Column(
        children: [
          AppTextField(
            label: 'Supplier',
            hint: 'Supplier name',
            controller: supplier,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Bill No.',
                  hint: 'BILL-000123',
                  controller: bill,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  label: 'Date',
                  hint: '11/07/2025',
                  controller: date,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Items', hint: 'Item description'),
          const SizedBox(height: 16),
          AppTextField(label: 'Total Amount', hint: '₹0.00'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  type: AppButtonType.outlined,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Save & Submit',
                  onPressed: () {
                    final value = double.tryParse(
                      amount.text.replaceAll(',', '').trim(),
                    );
                    if (supplier.text.trim().isEmpty ||
                        bill.text.trim().isEmpty ||
                        value == null ||
                        value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a supplier, bill number and valid amount',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(
                      () => _addedPurchases.insert(0, {
                        'billNo': bill.text.trim(),
                        'supplier': supplier.text.trim(),
                        'amount': '\u20B9${value.toStringAsFixed(2)}',
                        'status': 'Pending',
                        'date': date.text.trim(),
                      }),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Purchase saved')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
    supplier.dispose();
    bill.dispose();
    date.dispose();
    amount.dispose();
  }
}
