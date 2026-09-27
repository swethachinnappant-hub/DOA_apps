import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  bool _isLoading = true;
  String _query = '';
  String _statusFilter = 'All';
  final List<Map<String, String>> _addedClients = [];

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
        onPressed: _addClient,
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
            for (final option in ['All', 'Active', 'Inactive'])
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

  Future<void> _addClient() async {
    final name = TextEditingController();
    final gstin = TextEditingController();
    final key = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add client'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Client name'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a client name'
                    : null,
              ),
              TextFormField(
                controller: gstin,
                decoration: const InputDecoration(
                  labelText: 'GSTIN (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save client'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        // Kept in screen state until the accounting API is configured.
        _addedClients.insert(0, {
          'name': name.text.trim(),
          'gstin': gstin.text.trim().isEmpty
              ? 'Not provided'
              : gstin.text.trim(),
          'balance': '\u20B90',
          'status': 'Active',
        });
        _query = '';
        _statusFilter = 'All';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Client added')));
    }
    name.dispose();
    gstin.dispose();
  }

  Widget _buildClientsList() {
    final clients = [
      {
        'name': 'ABC Traders',
        'gstin': '06AAACR1234F1Z5',
        'balance': '₹3,25,000',
        'status': 'Active',
      },
      {
        'name': 'XYZ Enterprises',
        'gstin': '06BBCCE1234F1Z5',
        'balance': '₹1,25,000',
        'status': 'Active',
      },
      {
        'name': 'Suresh & Co.',
        'gstin': '06CCLRE1234F1Z5',
        'balance': '₹65,000',
        'status': 'Active',
      },
      {
        'name': 'Mahesh Traders',
        'gstin': '06DMDRE1234F1Z5',
        'balance': '₹1,10,000',
        'status': 'Inactive',
      },
      {
        'name': 'Pooja Enterprises',
        'gstin': '06EEPUR1234F1Z5',
        'balance': '₹50,500',
        'status': 'Active',
      },
    ];
    clients.insertAll(0, _addedClients);
    final visibleClients = clients.where((client) {
      final text = '${client['name']} ${client['gstin']}'.toLowerCase();
      return text.contains(_query) &&
          (_statusFilter == 'All' || client['status'] == _statusFilter);
    }).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'All Clients'),
          const SizedBox(height: 8),
          ...visibleClients.map(
            (c) => AppListTile(
              title: c['name']!,
              subtitle: 'GSTIN: ${c['gstin']}',
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.1),
                child: Text(
                  c['name']![0],
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    c['balance']!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c['status'] == 'Active'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      c['status']!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: c['status'] == 'Active'
                            ? Colors.green
                            : Colors.red,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text(c['name']!),
                  content: Text(
                    'GSTIN: ${c['gstin']}\nBalance: ${c['balance']}\nStatus: ${c['status']}',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (visibleClients.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No clients match this search.'),
            ),
        ],
      ),
    );
  }
}
