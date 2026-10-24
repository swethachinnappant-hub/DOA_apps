import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/models/user.dart';
import '../../../core/pricing.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../cart/widgets/order_summary.dart';

/// Checkout in the §9.3 five-step shape: sign in or guest, address, delivery,
/// payment, review. Compact viewports get a progress stepper with a
/// collapsible summary pinned on top; desktop keeps the stepper as an
/// accordion with a sticky ORDER SUMMARY beside it.
///
/// Every step reads from the cart and the store, so totals can never drift
/// from what is charged, and validation never clears what the shopper typed.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _titles = [
    'Sign in',
    'Address',
    'Delivery',
    'Payment',
    'Review',
  ];

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const _deliveries = <({String name, String note, int days})>[
    (name: 'Standard delivery', note: 'In 3-5 business days', days: 5),
    (name: 'Express delivery', note: 'In 2 business days', days: 2),
    (name: 'Priority delivery', note: 'By the next business day', days: 1),
  ];

  static const _payments = <({String name, IconData icon, String note})>[
    (name: 'UPI', icon: Icons.payment, note: 'PhonePe, GPay, Paytm'),
    (
      name: 'Credit/Debit Card',
      icon: Icons.credit_card,
      note: 'Visa, Mastercard, RuPay',
    ),
    (name: 'Net Banking', icon: Icons.account_balance, note: 'All banks'),
    (name: 'Cash on Delivery', icon: Icons.money, note: 'Pay when it arrives'),
  ];

  static const _cities = <String, String>{
    '560001': 'Bengaluru, Karnataka',
    '500081': 'Hyderabad, Telangana',
    '400001': 'Mumbai, Maharashtra',
    '110001': 'New Delhi, Delhi',
  };

  int _step = 0;
  int _selectedAddress = 0;
  int _deliveryOption = 0;
  String _paymentMethod = 'UPI';
  bool _addingAddress = false;
  String _addressType = 'Home';
  Map<String, String> _errors = const {};

  final _addresses = <({String label, String value})>[
    (label: 'Home', value: '14 MG Road, Bengaluru, Karnataka 560001'),
    (label: 'Office', value: 'Tower B, Tech Park, Hyderabad, Telangana 500081'),
  ];

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pincode = TextEditingController();
  final _address = TextEditingController();
  final _gst = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.maybeOf(context);
      if (router != null && context.read<CommerceStore>().cart.isEmpty) {
        router.go('/cart');
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pincode.dispose();
    _address.dispose();
    _gst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;

    if (store.cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 58,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text('Nothing to check out'),
                const SizedBox(height: 8),
                Text(
                  'Add a product to your bag first.',
                  style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
                ),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Browse products',
                  color: config.primaryColor,
                  onPressed: () => context.go('/app'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Responsive.isDesktop(context)
          ? _desktop(context, config, store, user)
          : _compact(context, config, store, user),
    );
  }

  // ------------------------------------------------------------- layouts

  Widget _compact(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
  ) {
    return Column(
      children: [
        _StepIndicator(current: _step),
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          title: Text(
            'Order summary',
            style: AppTypography.subtitle.copyWith(fontSize: 15),
          ),
          subtitle: Text(
            '${store.cartCount} item(s)',
            style: AppTypography.caption.copyWith(
              color: AppPalette.textSecondary,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: _summaryBody(context, config, store),
            ),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            key: ValueKey(_step),
            padding: Responsive.padding(context),
            child: _stepBody(context, config, store, user, _step),
          ),
        ),
        _bottomBar(context, config, store, user),
      ],
    );
  }

  Widget _desktop(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < _titles.length; i++)
                      _accordionStep(context, config, store, user, i),
                  ],
                ),
              ),
            ),
          ),
        ),
        Container(
          width: 400,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORDER SUMMARY',
                  style: AppTypography.eyebrow.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _summaryBody(context, config, store),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryBody(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
  ) {
    final showPrice = config.rules.showPrices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in store.cart)
          _LineSummary(
            name: line.name,
            qty: line.quantity,
            amount: line.lineTotal,
            showPrice: showPrice,
            currency: config.currencySymbol,
          ),
        const SizedBox(height: AppSpacing.sm),
        const Divider(height: 1),
        const SizedBox(height: AppSpacing.sm),
        OrderSummary(
          totals: store.cartTotals,
          showPrice: showPrice,
          currency: config.currencySymbol,
          primary: config.primaryColor,
        ),
      ],
    );
  }

  Widget _bottomBar(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
  ) {
    final showPrice = config.rules.showPrices;
    final label = _step == _titles.length - 1
        ? (showPrice
              ? 'Place order · ${Pricing.money(store.cartTotals.grandTotal, currencySymbol: config.currencySymbol)}'
              : 'Place order')
        : 'Continue';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0) ...[
              SizedBox(
                width: 110,
                child: AppButton(
                  text: 'Back',
                  type: AppButtonType.outlined,
                  onPressed: () => setState(() => _step -= 1),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: AppButton(
                text: label,
                onPressed: () => _advance(context, config, store, user),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _accordionStep(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
    int index,
  ) {
    final done = index < _step;
    final current = index == _step;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        onTap: done ? () => setState(() => _step = index) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done || current
                        ? config.primaryColor
                        : Theme.of(context).dividerColor,
                  ),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: done || current
                                ? Colors.white
                                : AppPalette.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titles[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (done && _doneSummary(index, store, user) != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _doneSummary(index, store, user)!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (done)
                  Text(
                    'Edit',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: config.primaryColor,
                    ),
                  ),
              ],
            ),
            if (current) ...[
              const SizedBox(height: AppSpacing.md),
              _stepBody(context, config, store, user, index),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (index > 0) ...[
                    AppButton(
                      text: 'Back',
                      type: AppButtonType.outlined,
                      onPressed: () => setState(() => _step -= 1),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  const Spacer(),
                  AppButton(
                    text: index == _titles.length - 1
                        ? (config.rules.showPrices
                              ? 'Place order · ${Pricing.money(store.cartTotals.grandTotal, currencySymbol: config.currencySymbol)}'
                              : 'Place order')
                        : 'Continue',
                    onPressed: () => _advance(context, config, store, user),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- steps

  Widget _stepBody(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
    int step,
  ) {
    return switch (step) {
      0 => _signInStep(context, user),
      1 => _addressStep(context, config),
      2 => _deliveryStep(context, config),
      3 => _paymentStep(context, config),
      _ => _reviewStep(context, config, store),
    };
  }

  Widget _signInStep(BuildContext context, AppUser? user) {
    if (user != null) {
      return AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppPalette.copperTint,
              child: Text(
                user.initials,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPalette.copperDark,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue as guest', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Your order will be placed without an account. '
            'Sign in any time to track it across devices.',
            style: AppTypography.caption.copyWith(
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Sign in',
            type: AppButtonType.outlined,
            isExpanded: true,
            onPressed: () => context.push('/login'),
          ),
        ],
      ),
    );
  }

  Widget _addressStep(BuildContext context, BusinessConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Delivery address',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        RadioGroup<int>(
          groupValue: _selectedAddress,
          onChanged: (value) =>
              setState(() => _selectedAddress = value ?? 0),
          child: Column(
            children: [
              for (var i = 0; i < _addresses.length; i++)
                _AddressCard(
                  label: _addresses[i].label,
                  address: _addresses[i].value,
                  selected: i == _selectedAddress,
                  accent: config.primaryColor,
                  value: i,
                ),
            ],
          ),
        ),
        if (!_addingAddress) ...[
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            text: 'Add new address',
            type: AppButtonType.outlined,
            icon: Icons.add,
            isExpanded: true,
            onPressed: () => setState(() {
              _addingAddress = true;
              _errors = const {};
            }),
          ),
        ],
        if (_addingAddress) ...[
          const SizedBox(height: AppSpacing.sm),
          _addressForm(context, config),
        ],
      ],
    );
  }

  Widget _addressForm(BuildContext context, BusinessConfig config) {
    InputDecoration decoration(String hint, String? error) => InputDecoration(
      hintText: hint,
      errorText: error,
      isDense: true,
      border: const OutlineInputBorder(),
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('New address', style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _name,
            decoration: decoration('Full name', _errors['name']),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: decoration('Phone (10 digits)', _errors['phone']),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _pincode,
            keyboardType: TextInputType.number,
            decoration: decoration('Pincode (6 digits)', _errors['pincode']),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _address,
            maxLines: 2,
            minLines: 1,
            decoration: decoration('Flat, street, area', _errors['address']),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _gst,
            decoration: decoration('GST number (optional)', null),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Save as',
            style: AppTypography.caption.copyWith(
              color: AppPalette.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Home'),
                selected: _addressType == 'Home',
                onSelected: (_) => setState(() => _addressType = 'Home'),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: const Text('Work'),
                selected: _addressType == 'Work',
                onSelected: (_) => setState(() => _addressType = 'Work'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Cancel',
                  type: AppButtonType.outlined,
                  onPressed: () => setState(() {
                    _addingAddress = false;
                    _errors = const {};
                  }),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(text: 'Save address', onPressed: _saveAddress),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _saveAddress() {
    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) errors['name'] = 'Enter your name';
    if (!RegExp(r'^\d{10}$').hasMatch(_phone.text.trim())) {
      errors['phone'] = 'Enter a 10-digit phone number';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(_pincode.text.trim())) {
      errors['pincode'] = 'Enter a 6-digit pincode';
    }
    if (_address.text.trim().isEmpty) errors['address'] = 'Enter your address';

    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final city = _cities[_pincode.text.trim()] ?? 'India';
    setState(() {
      _addresses.add((
        label: _addressType,
        value:
            '${_address.text.trim()}, $city ${_pincode.text.trim()}',
      ));
      _selectedAddress = _addresses.length - 1;
      _addingAddress = false;
      _errors = const {};
    });
    _name.clear();
    _phone.clear();
    _pincode.clear();
    _address.clear();
    _gst.clear();
    _addressType = 'Home';
  }

  Widget _deliveryStep(BuildContext context, BusinessConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Delivery option',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        RadioGroup<int>(
          groupValue: _deliveryOption,
          onChanged: (value) => setState(() => _deliveryOption = value ?? 0),
          child: Column(
            children: [
              for (var i = 0; i < _deliveries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: RadioListTile<int>(
                      value: i,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: config.primaryColor,
                      title: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            size: 19,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              _deliveries[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${_deliveries[i].note} · ${_etaLabel(_deliveries[i].days)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppPalette.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentStep(BuildContext context, BusinessConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Payment method',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        RadioGroup<String>(
          groupValue: _paymentMethod,
          onChanged: (value) => setState(() => _paymentMethod = value ?? 'UPI'),
          child: Column(
            children: [
              for (final option in _payments)
                _PaymentCard(
                  name: option.name,
                  icon: option.icon,
                  note: option.note,
                  selected: option.name == _paymentMethod,
                  accent: config.primaryColor,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewStep(BuildContext context, BusinessConfig config, CommerceStore store) {
    final showPrice = config.rules.showPrices;
    final address = _addresses[_selectedAddress];
    final delivery = _deliveries[_deliveryOption];
    final payment = _payments.firstWhere((option) => option.name == _paymentMethod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Items',
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in store.cart)
                _LineSummary(
                  name: line.name,
                  qty: line.quantity,
                  amount: line.lineTotal,
                  showPrice: showPrice,
                  currency: config.currencySymbol,
                ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Ship to',
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
        ),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address.value,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: AppPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Delivery',
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
        ),
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${delivery.note} · ${_etaLabel(delivery.days)}',
                      style: TextStyle(fontSize: 12.5, color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionHeader(
          title: 'Payment',
          padding: const EdgeInsets.only(
            top: AppSpacing.md,
            bottom: AppSpacing.sm,
          ),
        ),
        AppCard(
          child: Row(
            children: [
              Icon(payment.icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      payment.note,
                      style: TextStyle(fontSize: 12.5, color: AppPalette.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: OrderSummary(
            totals: store.cartTotals,
            showPrice: showPrice,
            currency: config.currencySymbol,
            primary: config.primaryColor,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  // ------------------------------------------------------------ flow

  void _advance(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
  ) {
    if (_step < _titles.length - 1) {
      setState(() => _step += 1);
      return;
    }
    _placeOrder(config, store, user);
  }

  void _placeOrder(
    BusinessConfig config,
    CommerceStore store,
    AppUser? user,
  ) {
    final order = store.placeOrder(
      customerId: user?.id ?? 'guest',
      customerName: user?.displayName ?? 'Guest',
      deliveryAddress: _addresses[_selectedAddress].value,
      paymentMethod: _paymentMethod,
    );
    if (order == null || !mounted) return;

    final router = GoRouter.maybeOf(context);
    router?.go('/order-success/${order.id}');
  }

  String? _doneSummary(int index, CommerceStore store, AppUser? user) {
    return switch (index) {
      0 => user?.displayName ?? 'Guest checkout',
      1 => _addresses[_selectedAddress].value,
      2 => _deliveries[_deliveryOption].name,
      3 => _paymentMethod,
      _ => null,
    };
  }

  String _etaLabel(int days) {
    final eta = DateTime.now().add(Duration(days: days));
    return 'Delivery by ${_weekdays[eta.weekday - 1]}, '
        '${eta.day} ${_months[eta.month - 1]}';
  }
}

/// Compact progress stepper: five numbered stops with check marks behind the
/// shopper and a connector line to the next one.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  static const _labels = [
    'Sign in',
    'Address',
    'Delivery',
    'Payment',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current
                        ? AppPalette.copper
                        : AppPalette.surfaceMuted,
                    border: i <= current
                        ? null
                        : Border.all(color: AppPalette.divider),
                  ),
                  child: i < current
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i <= current
                                ? Colors.white
                                : AppPalette.textSecondary,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == current
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i <= current
                        ? AppPalette.textPrimary
                        : AppPalette.textMuted,
                  ),
                ),
              ],
            ),
            if (i < _labels.length - 1)
              Container(
                width: 20,
                height: 1,
                margin: const EdgeInsets.only(bottom: 16),
                color: i < current ? AppPalette.copper : AppPalette.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.label,
    required this.address,
    required this.selected,
    required this.accent,
    required this.value,
  });

  final String label;
  final String address;
  final bool selected;
  final Color accent;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            Radio<int>(value: value, activeColor: accent),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12.5),
                      color: selected ? null : AppPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.name,
    required this.icon,
    required this.note,
    required this.selected,
    required this.accent,
  });

  final String name;
  final IconData icon;
  final String note;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: RadioListTile<String>(
          value: name,
          dense: true,
          contentPadding: EdgeInsets.zero,
          activeColor: accent,
          title: Row(
            children: [
              Icon(icon, size: 19),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          subtitle: Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: AppPalette.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _LineSummary extends StatelessWidget {
  const _LineSummary({
    required this.name,
    required this.qty,
    required this.amount,
    required this.showPrice,
    required this.currency,
  });

  final String name;
  final int qty;
  final int amount;
  final bool showPrice;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$name × $qty',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            showPrice
                ? Pricing.money(amount, currencySymbol: currency)
                : 'Contact',
            style: TextStyle(
              fontSize: Responsive.fontSize(context, mobile: 13),
              fontWeight: FontWeight.w600,
              color: showPrice ? null : AppPalette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
