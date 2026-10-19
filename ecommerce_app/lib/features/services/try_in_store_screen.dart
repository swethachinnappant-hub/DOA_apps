import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

class StoreLocation {
  const StoreLocation(this.name, this.address, this.hours, this.phone);

  final String name;
  final String address;
  final String hours;
  final String phone;
}

const _stores = <StoreLocation>[
  StoreLocation(
    'Kirtilals — Jayanagar',
    '42, 11th Main, 4th Block, Jayanagar, Bengaluru 560011',
    'Mon–Sat 10:30 AM – 8 PM · Sun 11 AM – 6 PM',
    '080 4123 4567',
  ),
  StoreLocation(
    'Kirtilals — Anna Nagar',
    '2nd Avenue, Anna Nagar, Chennai 600040',
    'Mon–Sat 10:30 AM – 8 PM · Sun closed',
    '044 2621 8899',
  ),
  StoreLocation(
    'Kirtilals — Bandra',
    'Linking Road, Bandra West, Mumbai 400050',
    'Daily 11 AM – 9 PM',
    '022 2640 1122',
  ),
];

const _slots = ['10 AM', '12 PM', '3 PM', '5 PM'];

/// Our Store / Try in Store (§10.4): boutique list + map panel and the
/// "book appointment" form with its confirmation state.
class TryInStoreScreen extends StatefulWidget {
  const TryInStoreScreen({super.key});

  @override
  State<TryInStoreScreen> createState() => _TryInStoreScreenState();
}

class _TryInStoreScreenState extends State<TryInStoreScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _productsController = TextEditingController();

  int _selectedStore = 0;
  String? _slot;
  bool _showMap = false;
  bool _booked = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dateController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.pageInset(context);
    final wide = Responsive.width(context) >= 900;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, AppSpacing.xxl, padding, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Our Store', style: AppTypography.overline),
              const SizedBox(height: AppSpacing.sm),
              Text('FIND A STORE', style: AppTypography.display),
              const SizedBox(height: AppSpacing.lg),
              Container(height: 2, width: 64, color: AppPalette.copper),
              const SizedBox(height: AppSpacing.xl),
              if (!wide) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('List'),
                      icon: Icon(Icons.storefront_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Map'),
                      icon: Icon(Icons.map_outlined),
                    ),
                  ],
                  selected: {_showMap},
                  onSelectionChanged: (value) =>
                      setState(() => _showMap = value.first),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (!wide && !_showMap) _storeList(),
              if (wide) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: _storeList()),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(flex: 7, child: _mapPanel()),
                  ],
                ),
              ] else if (_showMap) ...[
                _mapPanel(),
              ],
              const SizedBox(height: AppSpacing.xxxl),
              _bookForm(),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storeList() {
    return Column(
      children: [
        for (var i = 0; i < _stores.length; i++) ...[
          _StoreCard(
            store: _stores[i],
            selected: i == _selectedStore,
            onTap: () => setState(() => _selectedStore = i),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _mapPanel() {
    final store = _stores[_selectedStore];

    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: AppRadius.allMd,
        border: Border.all(color: AppPalette.border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 44,
              color: AppPalette.copper,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(store.name, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text('Map view opens in the store app', style: AppTypography.caption),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content:
                        Text('Directions to ${store.name} — ${store.address}'),
                  ),
                ),
              icon: const Icon(Icons.directions_outlined, size: 17),
              label: const Text('Directions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookForm() {
    if (_booked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APPOINTMENT', style: AppTypography.eyebrow),
          const SizedBox(height: AppSpacing.sm),
          Text('See you soon', style: AppTypography.display),
          const SizedBox(height: AppSpacing.lg),
          Container(height: 2, width: 64, color: AppPalette.copper),
          const SizedBox(height: AppSpacing.xl),
          const Icon(
            Icons.check_circle_outline,
            size: 44,
            color: AppPalette.success,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Your visit to ${_stores[_selectedStore].name} is booked for '
            '${_dateController.text.isEmpty ? 'the date you chose' : _dateController.text} '
            'at ${_slot ?? 'your slot'}. Our team will confirm on call.',
            style: AppTypography.bodyMuted.copyWith(height: 1.7),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            text: 'BOOK ANOTHER',
            type: AppButtonType.outlined,
            onPressed: () => setState(() {
              _booked = false;
              _slot = null;
              _nameController.clear();
              _phoneController.clear();
              _dateController.clear();
              _productsController.clear();
            }),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('APPOINTMENT', style: AppTypography.eyebrow),
        const SizedBox(height: AppSpacing.sm),
        Text('Book a visit', style: AppTypography.display),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 2, width: 64, color: AppPalette.copper),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Your name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _dateController,
          decoration: const InputDecoration(
            labelText: 'Date',
            hintText: 'e.g. 25 Oct 2026',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Time slot', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final slot in _slots)
              ChoiceChip(
                label: Text(slot),
                selected: _slot == slot,
                onSelected: (selected) =>
                    setState(() => _slot = selected ? slot : null),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _productsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Designs you want to try',
            hintText: 'e.g. Temple necklace, 22K jhumkas…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'BOOK APPOINTMENT',
            type: AppButtonType.filled,
            onPressed: () => setState(() => _booked = true),
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.selected,
    required this.onTap,
  });

  final StoreLocation store;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppPalette.warm : AppPalette.surface,
      borderRadius: AppRadius.allMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.allMd,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadius.allMd,
            border: Border.all(
              color: selected ? AppPalette.copper : AppPalette.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(store.name, style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  store.address,
                  style: AppTypography.bodyMuted.copyWith(height: 1.55),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(store.hours, style: AppTypography.caption),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('Calling ${store.phone}')),
                        ),
                      icon: const Icon(Icons.call_outlined, size: 16),
                      label: Text(store.phone),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.textPrimary,
                        side: const BorderSide(color: AppPalette.border),
                        textStyle: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text('Directions to ${store.name}')),
                        ),
                      icon: const Icon(Icons.directions_outlined, size: 16),
                      label: const Text('Directions'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
