import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _isLoading = true;
  String _query = '';
  String _statusFilter = 'All';
  final List<Map<String, String>> _addedSales = [];

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
        text: 'New Sale',
        icon: Icons.add,
        onPressed: () => _showAddSaleDialog(),
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
          _buildSalesList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppSearchField(
      hint: 'Search by invoice number, customer...',
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

  void _showSaleDetails(Map<String, dynamic> sale) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(sale['invoiceNo'] as String),
        content: Text(
          'Customer: ${sale['customer']}\nDate: ${sale['date']}\nAmount: ${sale['amount']}\nStatus: ${sale['status']}',
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
            title: "Today's Sales",
            value: '₹1,25,000',
            color: Colors.green,
            icon: Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: 'This Month',
            value: '₹12,45,000',
            color: Colors.blue,
            icon: Icons.calendar_month,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InfoCard(
            title: 'Pending',
            value: '₹3,25,000',
            color: Colors.orange,
            icon: Icons.pending,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesList() {
    final sales = [
      {
        'invoiceNo': 'INV/24-25/001',
        'customer': 'Client A',
        'amount': '₹25,000',
        'status': 'Paid',
        'date': '11/07/2025',
      },
      {
        'invoiceNo': 'INV/24-25/002',
        'customer': 'Client B',
        'amount': '₹18,500',
        'status': 'Pending',
        'date': '10/07/2025',
      },
      {
        'invoiceNo': 'INV/24-25/003',
        'customer': 'Client C',
        'amount': '₹32,000',
        'status': 'Paid',
        'date': '09/07/2025',
      },
      {
        'invoiceNo': 'INV/24-25/004',
        'customer': 'Client D',
        'amount': '₹15,750',
        'status': 'Pending',
        'date': '08/07/2025',
      },
    ];
    sales.insertAll(0, _addedSales);
    final visibleSales = sales
        .where(
          (sale) =>
              '${sale['invoiceNo']} ${sale['customer']}'.toLowerCase().contains(
                _query,
              ) &&
              (_statusFilter == 'All' || sale['status'] == _statusFilter),
        )
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Recent Sales'),
          const SizedBox(height: 8),
          ...visibleSales.map(
            (s) => AmountListTile(
              title: s['invoiceNo']!,
              subtitle: '${s['customer']} • ${s['date']}',
              amount: s['amount']!,
              status: s['status'],
              statusColor: _getStatusColor(s['status']!),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.receipt,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              onTap: () => _showSaleDetails(s),
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

  Future<void> _showAddSaleDialog() async {
    final customer = TextEditingController();
    final invoice = TextEditingController();
    final date = TextEditingController(
      text: MaterialLocalizations.of(context).formatShortDate(DateTime.now()),
    );
    final amount = TextEditingController();
    await AppDialog.bottomSheet(
      context,
      title: 'New Sales Entry',
      content: Column(
        children: [
          AppTextField(
            label: 'Customer',
            hint: 'Customer name',
            controller: customer,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Invoice No.',
                  hint: 'INV-000123',
                  controller: invoice,
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
          AppTextField(
            label: 'Total Amount',
            hint: 'Amount in INR',
            controller: amount,
            keyboardType: TextInputType.number,
          ),
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
                    if (customer.text.trim().isEmpty ||
                        invoice.text.trim().isEmpty ||
                        value == null ||
                        value <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a customer, invoice number and valid amount',
                          ),
                        ),
                      );
                      return;
                    }
                    setState(
                      () => _addedSales.insert(0, {
                        'invoiceNo': invoice.text.trim(),
                        'customer': customer.text.trim(),
                        'amount': '\u20B9${value.toStringAsFixed(2)}',
                        'status': 'Pending',
                        'date': date.text.trim(),
                      }),
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Sale saved')));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
    customer.dispose();
    invoice.dispose();
    date.dispose();
    amount.dispose();
  }
}
