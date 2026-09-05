import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class GstScreen extends StatefulWidget {
  const GstScreen({super.key});

  @override
  State<GstScreen> createState() => _GstScreenState();
}

class _GstScreenState extends State<GstScreen> {
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
          const SkeletonCard(height: 300),
          SizedBox(height: 16),
          const SkeletonList(itemCount: 3),
          SizedBox(height: 16),
          const SkeletonCard(height: 200),
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
          _buildGstSummary(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildGstReturns(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildReconciliation(),
        ],
      ),
    );
  }

  Widget _buildGstSummary() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'GST Summary'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Output Tax (CGST)', '₹1,25,000', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem('Output Tax (SGST)', '₹1,25,000', Colors.purple)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Input Tax (CGST)', '₹85,000', Colors.teal)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryItem('Input Tax (SGST)', '₹85,000', Colors.orange)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Text('Net GST Payable', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('₹80,000', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 10), color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.bold, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildGstReturns() {
    final returns = [
      {'title': 'GSTR-1', 'desc': 'Outward Supplies', 'status': 'Filed', 'due': '11/07/2025', 'color': Colors.green},
      {'title': 'GSTR-3B', 'desc': 'Summary Return', 'status': 'Pending', 'due': '20/07/2025', 'color': Colors.orange},
      {'title': 'GSTR-2B', 'desc': 'Auto-drafted ITC', 'status': 'Available', 'due': 'N/A', 'color': Colors.blue},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'GST Returns'),
          const SizedBox(height: 8),
          ...returns.map((r) => AppListTile(
                title: r['title']! as String,
                subtitle: '${r['desc']} • Due: ${r['due']}',
                leading: Container(
                  width: Responsive.spacing(context, mobile: 44), height: Responsive.spacing(context, mobile: 44),
                  decoration: BoxDecoration(
                    color: (r['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.receipt, color: r['color'] as Color, size: 20),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (r['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                   child: Text(r['status'] as String, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), fontWeight: FontWeight.w600, color: r['color'] as Color), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildReconciliation() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'ITC Reconciliation'),
          const SizedBox(height: 16),
          _buildReconItem('Matched', '85%', Colors.green),
          const SizedBox(height: 8),
          _buildReconItem('Mismatched', '10%', Colors.orange),
          const SizedBox(height: 8),
          _buildReconItem('Pending', '5%', Colors.red),
        ],
      ),
    );
  }

  Widget _buildReconItem(String label, String percentage, Color color) {
    return Row(
      children: [
        Container(width: Responsive.spacing(context, mobile: 12), height: Responsive.spacing(context, mobile: 12), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: Responsive.spacing(context, mobile: 12)),
        Expanded(child: Text(label, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14)), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Flexible(child: Text(percentage, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
