import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class BankingScreen extends StatefulWidget {
  const BankingScreen({super.key});

  @override
  State<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends State<BankingScreen> {
  bool _isLoading = true;
  final List<Map<String, String>> _newTransactions = [];

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
          const SkeletonCard(height: 280),
          SizedBox(height: 16),
          const SkeletonGrid(itemCount: 4),
          SizedBox(height: 16),
          const SkeletonList(itemCount: 4),
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
          _buildBankSummary(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildQuickActions(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildRecentTransactions(),
        ],
      ),
    );
  }

  Widget _buildBankSummary() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Bank & Cash Summary'),
          const SizedBox(height: 16),
          _buildAccountRow('SBI Current A/c', '₹2,45,680.00', Colors.blue),
          const SizedBox(height: 12),
          _buildAccountRow('HDFC Bank A/c', '₹1,25,430.00', Colors.purple),
          const SizedBox(height: 12),
          _buildAccountRow('ICICI Bank A/c', '₹75,890.00', Colors.teal),
          const SizedBox(height: 12),
          _buildAccountRow('Axis Bank A/c', '₹1,10,250.00', Colors.orange),
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
                  child: Text(
                    'Total Bank Balance',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 14),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: Responsive.spacing(context, mobile: 8)),
                Flexible(
                  child: Text(
                    '₹5,57,250.00',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 16),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountRow(String name, String balance, Color color) {
    return Row(
      children: [
        Container(
          width: Responsive.spacing(context, mobile: 40),
          height: Responsive.spacing(context, mobile: 40),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.account_balance, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 14),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            balance,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 14),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.send, 'label': 'Bank Transfer', 'color': Colors.blue},
      {
        'icon': Icons.receipt_long,
        'label': 'Cheque Issue',
        'color': Colors.purple,
      },
      {'icon': Icons.receipt, 'label': 'Cheque Deposit', 'color': Colors.teal},
      {'icon': Icons.payments, 'label': 'Bank Payment', 'color': Colors.orange},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Quick Actions'),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: Responsive.isMobile(context) ? 4 : 8,
              childAspectRatio: Responsive.childAspectRatio(context),
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _createTransaction(action['label'] as String),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: Responsive.spacing(context, mobile: 48),
                      height: Responsive.spacing(context, mobile: 48),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 11),
                      ),
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

  Widget _buildRecentTransactions() {
    final transactions = [
      {
        'type': 'Cheque Issue',
        'party': 'Vendor A',
        'amount': '₹15,000',
        'status': 'Completed',
      },
      {
        'type': 'Bank Transfer',
        'party': 'Client B',
        'amount': '₹25,000',
        'status': 'Completed',
      },
      {
        'type': 'Cheque Deposit',
        'party': 'Client C',
        'amount': '₹32,000',
        'status': 'Pending',
      },
      {
        'type': 'Bank Payment',
        'party': 'Vendor D',
        'amount': '₹18,500',
        'status': 'Completed',
      },
    ];
    transactions.insertAll(0, _newTransactions);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Recent Transactions'),
          const SizedBox(height: 8),
          ...transactions.map(
            (t) => AmountListTile(
              title: t['type']!,
              subtitle: t['party'],
              amount: t['amount']!,
              status: t['status'],
              statusColor: t['status'] == 'Completed'
                  ? Colors.green
                  : Colors.orange,
              leading: Container(
                width: Responsive.spacing(context, mobile: 44),
                height: Responsive.spacing(context, mobile: 44),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createTransaction(String type) async {
    final party = TextEditingController();
    final amount = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(type),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: party,
                decoration: const InputDecoration(
                  labelText: 'Account or party',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter an account or party'
                    : null,
              ),
              TextFormField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (INR)'),
                validator: (value) =>
                    double.tryParse(value?.replaceAll(',', '') ?? '') == null
                    ? 'Enter a valid amount'
                    : null,
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
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      setState(
        () => _newTransactions.insert(0, {
          'type': type,
          'party': party.text.trim(),
          'amount': '\u20B9${amount.text.trim()}',
          'status': 'Pending',
        }),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Transaction added')));
    }
    party.dispose();
    amount.dispose();
  }
}
