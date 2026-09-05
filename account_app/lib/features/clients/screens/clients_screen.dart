import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
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
        text: 'Add Client',
        icon: Icons.person_add,
        onPressed: () {},
      ),
      body: _isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SkeletonCard(height: 60),
          SizedBox(height: 16),
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
          _buildSearchBar(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildClientsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return AppSearchField(
      hint: 'Search clients...',
      onFilterPressed: () {},
    );
  }

  Widget _buildClientsList() {
    final clients = [
      {'name': 'ABC Traders', 'gstin': '06AAACR1234F1Z5', 'balance': '₹3,25,000', 'status': 'Active'},
      {'name': 'XYZ Enterprises', 'gstin': '06BBCCE1234F1Z5', 'balance': '₹1,25,000', 'status': 'Active'},
      {'name': 'Suresh & Co.', 'gstin': '06CCLRE1234F1Z5', 'balance': '₹65,000', 'status': 'Active'},
      {'name': 'Mahesh Traders', 'gstin': '06DMDRE1234F1Z5', 'balance': '₹1,10,000', 'status': 'Inactive'},
      {'name': 'Pooja Enterprises', 'gstin': '06EEPUR1234F1Z5', 'balance': '₹50,500', 'status': 'Active'},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'All Clients',
            trailing: TextButton(onPressed: () {}, child: const Text('View All')),
          ),
          const SizedBox(height: 8),
          ...clients.map((c) => AppListTile(
                title: c['name']!,
                subtitle: 'GSTIN: ${c['gstin']}',
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    c['name']![0],
                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(c['balance']!, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c['status'] == 'Active' ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c['status']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: c['status'] == 'Active' ? Colors.green : Colors.red,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                onTap: () {},
              )),
        ],
      ),
    );
  }
}
