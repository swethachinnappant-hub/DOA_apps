import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class SavedAddress {
  const SavedAddress(this.label, this.name, this.phone, this.line);

  final String label;
  final String name;
  final String phone;
  final String line;

  SavedAddress copyWith({String? label, String? name, String? phone, String? line}) =>
      SavedAddress(
        label ?? this.label,
        name ?? this.name,
        phone ?? this.phone,
        line ?? this.line,
      );
}

/// Saved delivery addresses (§10.2 menu item): list + add dialog.
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _addresses = <SavedAddress>[
    const SavedAddress(
      'Home',
      'Priya Sharma',
      '+91 98765 43210',
      '14 MG Road, Bengaluru, Karnataka 560001',
    ),
    const SavedAddress(
      'Work',
      'Priya Sharma',
      '+91 98765 43210',
      'Prestige Tower, 5th Floor, Indiranagar, Bengaluru 560038',
    ),
  ];

  Future<void> _addAddress() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final lineController = TextEditingController();
    var label = 'Home';

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add address'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final option in const ['Home', 'Work', 'Other'])
                      ChoiceChip(
                        label: Text(option),
                        selected: label == option,
                        onSelected: (_) =>
                            setDialogState(() => label = option),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: lineController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
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
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (added == true && lineController.text.trim().isNotEmpty) {
      setState(() {
        _addresses.add(
          SavedAddress(
            label,
            nameController.text.trim().isEmpty
                ? 'Saved contact'
                : nameController.text.trim(),
            phoneController.text.trim(),
            lineController.text.trim(),
          ),
        );
      });
    }

    nameController.dispose();
    phoneController.dispose();
    lineController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.padding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Addresses')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: padding,
            children: [
              for (final address in _addresses)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.allMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.label, style: AppTypography.subtitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${address.name} · ${address.phone}',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          address.line,
                          style: AppTypography.bodyMuted.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _addAddress,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add address'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
