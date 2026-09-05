import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
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
    return _isLoading ? _buildSkeleton() : _buildContent();
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SkeletonGrid(itemCount: 8),
          const SizedBox(height: 16),
          const SkeletonList(itemCount: 6),
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
          _buildReportCategories(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildQuickReports(),
        ],
      ),
    );
  }

  Widget _buildReportCategories() {
    final categories = [
      {'title': 'Sales Register', 'icon': Icons.shopping_cart, 'color': Colors.green, 'desc': 'View all sales invoices'},
      {'title': 'Purchase Register', 'icon': Icons.shopping_bag, 'color': Colors.blue, 'desc': 'View all purchase bills'},
      {'title': 'GST Reports', 'icon': Icons.receipt, 'color': Colors.purple, 'desc': 'GSTR-1, GSTR-3B, etc.'},
      {'title': 'Ledger Summary', 'icon': Icons.book, 'color': Colors.teal, 'desc': 'Customer & Supplier Ledger'},
      {'title': 'Stock Summary', 'icon': Icons.inventory, 'color': Colors.orange, 'desc': 'Current Stock Report'},
      {'title': 'Outstanding', 'icon': Icons.people, 'color': Colors.red, 'desc': 'Receivables & Payables'},
      {'title': 'Profit & Loss', 'icon': Icons.trending_up, 'color': Colors.green, 'desc': 'P&L Statement Report'},
      {'title': 'Balance Sheet', 'icon': Icons.account_balance, 'color': Colors.blue, 'desc': 'Financial Position'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Report Categories'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.crossAxisCount(context),
              childAspectRatio: Responsive.childAspectRatio(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return AppCard(
                onTap: () {},
                padding: Responsive.padding(context, mobile: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: Responsive.spacing(context, mobile: 40), height: Responsive.spacing(context, mobile: 40),
                      decoration: BoxDecoration(
                        color: (cat['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat['icon'] as IconData, color: cat['color'] as Color, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Text(cat['title'] as String, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: Responsive.fontSize(context, mobile: 11)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReports() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Quick Reports'),
          const SizedBox(height: 8),
          _buildReportItem('Daily Sales Summary', Icons.shopping_cart),
          _buildReportItem('Daily Purchase Summary', Icons.shopping_bag),
          _buildReportItem('Cash Book', Icons.payments),
          _buildReportItem('Bank Book', Icons.account_balance),
          _buildReportItem('Journal Entry', Icons.book),
          _buildReportItem('Trial Balance', Icons.balance),
        ],
      ),
    );
  }

  Widget _buildReportItem(String title, IconData icon) {
    return AppListTile(
      title: title,
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {},
      showDivider: true,
    );
  }
}
