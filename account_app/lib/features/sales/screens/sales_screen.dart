import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  bool _isLoading = true;

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
      onFilterPressed: () {},
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: InfoCard(title: "Today's Sales", value: '₹1,25,000', color: Colors.green, icon: Icons.trending_up)),
        const SizedBox(width: 12),
        Expanded(child: InfoCard(title: 'This Month', value: '₹12,45,000', color: Colors.blue, icon: Icons.calendar_month)),
        const SizedBox(width: 12),
        Expanded(child: InfoCard(title: 'Pending', value: '₹3,25,000', color: Colors.orange, icon: Icons.pending)),
      ],
    );
  }

  Widget _buildSalesList() {
    final sales = [
      {'invoiceNo': 'INV/24-25/001', 'customer': 'Client A', 'amount': '₹25,000', 'status': 'Paid', 'date': '11/07/2025'},
      {'invoiceNo': 'INV/24-25/002', 'customer': 'Client B', 'amount': '₹18,500', 'status': 'Pending', 'date': '10/07/2025'},
      {'invoiceNo': 'INV/24-25/003', 'customer': 'Client C', 'amount': '₹32,000', 'status': 'Paid', 'date': '09/07/2025'},
      {'invoiceNo': 'INV/24-25/004', 'customer': 'Client D', 'amount': '₹15,750', 'status': 'Pending', 'date': '08/07/2025'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Sales',
            trailing: TextButton(onPressed: () {}, child: const Text('View All')),
          ),
          const SizedBox(height: 8),
          ...sales.map((s) => AmountListTile(
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
                  child: Icon(Icons.receipt, color: Theme.of(context).primaryColor, size: 20),
                ),
                onTap: () {},
              )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': return Colors.green;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showAddSaleDialog() {
    AppDialog.bottomSheet(
      context,
      title: 'New Sales Entry',
      content: Column(
        children: [
          AppDropdown<String>(
            label: 'Customer',
            hint: 'Select Customer',
            items: const [],
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: AppTextField(label: 'Invoice No.', hint: 'INV-000123')),
              const SizedBox(width: 16),
              Expanded(child: AppTextField(label: 'Date', hint: '11/07/2025')),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(label: 'Items', hint: 'Add Items'),
          const SizedBox(height: 16),
          AppTextField(label: 'Total Amount', hint: '₹0.00'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: AppButton(text: 'Cancel', type: AppButtonType.outlined, onPressed: () => Navigator.pop(context))),
              const SizedBox(width: 16),
              Expanded(child: AppButton(text: 'Save & Submit', onPressed: () => Navigator.pop(context))),
            ],
          ),
        ],
      ),
    );
  }
}
