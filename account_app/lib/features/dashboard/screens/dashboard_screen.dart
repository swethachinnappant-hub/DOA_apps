import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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
    if (_isLoading) return const SkeletonDashboard();
    return _buildContent();
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildStatsGrid(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildChartsSection(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return GradientCard(
      gradient: LinearGradient(
        colors: [
          Theme.of(context).primaryColor,
          Theme.of(context).primaryColor.withValues(alpha: 0.8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Here\'s what\'s happening today',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 11, tablet: 12),
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Online',
              style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      {'title': 'Total Sales', 'value': '₹12,45,000', 'icon': Icons.trending_up, 'color': Colors.green, 'change': '+12.5%', 'isPositive': true},
      {'title': 'Total Purchases', 'value': '₹8,75,000', 'icon': Icons.shopping_bag, 'color': Colors.blue, 'change': '+8.2%', 'isPositive': true},
      {'title': 'Bank Balance', 'value': '₹2,15,000', 'icon': Icons.account_balance, 'color': Colors.purple, 'change': '+5.1%', 'isPositive': true},
      {'title': 'Cash in Hand', 'value': '₹1,35,000', 'icon': Icons.payments, 'color': Colors.teal, 'change': '+3.8%', 'isPositive': true},
      {'title': 'Debtors', 'value': '₹3,25,000', 'icon': Icons.people, 'color': Colors.orange, 'change': '-2.3%', 'isPositive': false},
      {'title': 'Creditors', 'value': '₹2,45,000', 'icon': Icons.people_outline, 'color': Colors.red, 'change': '+1.5%', 'isPositive': true},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.crossAxisCount(context),
        childAspectRatio: Responsive.childAspectRatio(context),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return StatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          change: stat['change'] as String,
          isPositiveChange: stat['isPositive'] as bool,
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Responsive.isMobile(context)
        ? Column(
            children: [
              _buildSalesChart(),
              const SizedBox(height: 16),
              _buildTopItems(),
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildSalesChart()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopItemsList()),
            ],
          );
  }

  Widget _buildSalesChart() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Sales Trend'),
          SizedBox(
            height: Responsive.maxValue(context, mobile: 200, tablet: 250, desktop: 300),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 4),
                      FlSpot(3, 7), FlSpot(4, 6), FlSpot(5, 8), FlSpot(6, 9),
                    ],
                    isCurved: true,
                    color: Theme.of(context).primaryColor,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItems() {
    if (Responsive.isMobile(context)) return _buildTopItemsList();
    return const SizedBox.shrink();
  }

  Widget _buildTopItemsList() {
    final items = [
      {'name': 'Steel Pipe 20mm', 'amount': '₹2,45,000'},
      {'name': 'Cement 50kg', 'amount': '₹1,95,000'},
      {'name': 'Paint Bucket 20L', 'amount': '₹1,45,500'},
      {'name': 'Nut Bolt M10', 'amount': '₹85,000'},
      {'name': 'Wall Putty 40kg', 'amount': '₹75,000'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Top 5 Items Sold'),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value['name']!,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 13, tablet: 14),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      entry.value['amount']!,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 13, tablet: 14),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final transactions = [
      {'type': 'Sales', 'party': 'Client A', 'amount': '₹25,000', 'status': 'Paid', 'date': '11/07/2025'},
      {'type': 'Purchase', 'party': 'Vendor B', 'amount': '₹18,500', 'status': 'Pending', 'date': '10/07/2025'},
      {'type': 'Sales', 'party': 'Client C', 'amount': '₹32,000', 'status': 'Paid', 'date': '09/07/2025'},
      {'type': 'Bank', 'party': 'Cheque Issue', 'amount': '₹15,000', 'status': 'Completed', 'date': '09/07/2025'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Recent Transactions',
            trailing: TextButton(onPressed: () {}, child: const Text('View All')),
          ),
          const SizedBox(height: 12),
          ...transactions.map((t) => AmountListTile(
                title: t['party']!,
                subtitle: '${t['type']} • ${t['date']}',
                amount: t['amount']!,
                status: t['status'],
                statusColor: _getStatusColor(t['status']!),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _getStatusColor(t['status']!).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getTransactionIcon(t['type']!), color: _getStatusColor(t['status']!), size: 20),
                ),
              )),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid': case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sales': return Icons.trending_up;
      case 'purchase': return Icons.shopping_bag;
      case 'bank': return Icons.account_balance;
      default: return Icons.receipt;
    }
  }
}
