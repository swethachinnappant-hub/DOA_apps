import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/models/cart.dart';
import '../../../core/pricing.dart';
import '../../../core/product.dart';
import '../../../core/store/commerce_store.dart';
import '../../config/providers/business_config_provider.dart';
import '../../home/home_sections.dart';
import '../widgets/coupon_section.dart';
import '../widgets/order_summary.dart';

/// The shopper's bag in the §9.2 shape: line items on the left, a sticky
/// ORDER SUMMARY on the right at desktop widths, and the coupon block wired
/// to the same store the mini-cart uses.
///
/// Quantity controls are real: plus/minus change state, totals recompute, and
/// removing the last unit drops the line.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _giftWrap = false;
  final _giftNote = TextEditingController();

  @override
  void dispose() {
    _giftNote.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final lines = store.cart;
    final desktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lines.isEmpty
              ? 'Shopping Cart'
              : 'Shopping Cart (${store.cartCount})',
        ),
        actions: [
          if (lines.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, store),
            ),
        ],
      ),
      body: lines.isEmpty
          ? _empty(context, config, store)
          : desktop
          ? _desktop(context, config, store)
          : _compact(context, config, store),
      bottomNavigationBar:
          lines.isNotEmpty && !desktop
              ? _stickyCta(context, config)
              : null,
    );
  }

  Widget _desktop(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
  ) {
    final lines = store.cart;
    final totals = store.cartTotals;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: Responsive.padding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: Responsive.spacing(context, mobile: 12),
                    ),
                    child: _line(context, config, store, lines[i]),
                  ),
                SizedBox(height: Responsive.spacing(context, mobile: 8)),
                _giftWrapCard(context, config),
                SizedBox(height: Responsive.spacing(context, mobile: 16)),
                AppCard(child: _CartPincode(accent: config.accentColor)),
              ],
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
                OrderSummary(
                  totals: totals,
                  showPrice: config.rules.showPrices,
                  currency: config.currencySymbol,
                  primary: config.primaryColor,
                  onCheckout: () => context.push('/checkout'),
                ),
                if (config.rules.coupons) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.sm),
                  CouponSection(
                    subtotal: store.cartSubtotal,
                    appliedCode: store.appliedCoupon?.code,
                    onApply: store.applyCoupon,
                    onRemove: store.removeCoupon,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _compact(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
  ) {
    final lines = store.cart;
    final totals = store.cartTotals;

    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Padding(
              padding: EdgeInsets.only(
                bottom: Responsive.spacing(context, mobile: 12),
              ),
              child: _line(context, config, store, line),
            ),
          _giftWrapCard(context, config),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          AppCard(child: _CartPincode(accent: config.accentColor)),
          if (config.rules.coupons) ...[
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            CouponSection(
              subtotal: store.cartSubtotal,
              appliedCode: store.appliedCoupon?.code,
              onApply: store.applyCoupon,
              onRemove: store.removeCoupon,
            ),
          ],
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          const Divider(height: 1),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          OrderSummary(
            totals: totals,
            showPrice: config.rules.showPrices,
            currency: config.currencySymbol,
            primary: config.primaryColor,
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 8)),
        ],
      ),
    );
  }

  Widget _stickyCta(BuildContext context, BusinessConfig config) {
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
        child: AppButton(
          text: 'Proceed to checkout',
          isExpanded: true,
          onPressed: () => context.push('/checkout'),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
    CartItem line,
  ) {
    final product = store.productFor(line);
    final available = product?.stock ?? 0;
    final atLimit =
        product != null && product.ownerId.isNotEmpty && line.quantity >= available;

    return _CartLine(
      line: line,
      product: product,
      accent: config.accentColor,
      brandColor: config.primaryColor,
      fallbackIcon: config.icon,
      showPrice: config.rules.showPrices,
      currency: config.currencySymbol,
      atLimit: atLimit,
      onIncrement: atLimit ? null : () => store.incrementCart(line.lineKey),
      onDecrement: () => store.decrementCart(line.lineKey),
      onRemove: () => store.removeFromCart(line.lineKey),
      onMove: () => _moveToWishlist(context, store, line),
    );
  }

  void _moveToWishlist(BuildContext context, CommerceStore store, CartItem line) {
    store.removeFromCart(line.lineKey);
    if (!store.isWishlisted(line.productId)) store.toggleWishlist(line.productId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Moved to wishlist'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _giftWrapCard(BuildContext context, BusinessConfig config) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: _giftWrap,
                activeColor: config.primaryColor,
                visualDensity: VisualDensity.compact,
                onChanged: (value) =>
                    setState(() => _giftWrap = value ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Gift wrap this order',
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 14),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.card_giftcard,
                size: 18,
                color: config.accentColor,
              ),
            ],
          ),
          if (_giftWrap) ...[
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _giftNote,
              maxLines: 2,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Add a gift note (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, CommerceStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty the cart?'),
        content: const Text('Everything in your bag will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep items'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Empty cart'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.clearCart();
  }

  Widget _empty(
    BuildContext context,
    BusinessConfig config,
    CommerceStore store,
  ) {
    // The rail carries its own 16px inset, so the wrapper must not add a
    // second one — the header and the first card now share one left edge.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: _EmptyCart(brand: config.primaryColor, icon: config.icon),
          ),
          SectionHeader(
            title: 'Recommended for you',
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          const SizedBox(height: 6),
          ProductRail(
            products: store.shopProducts.take(6).toList(),
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({
    required this.line,
    required this.product,
    required this.accent,
    required this.brandColor,
    required this.fallbackIcon,
    required this.showPrice,
    required this.currency,
    required this.atLimit,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onMove,
  });

  final CartItem line;
  final Product? product;
  final Color accent;
  final Color brandColor;
  final IconData fallbackIcon;
  final bool showPrice;
  final String currency;
  final bool atLimit;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final images = product?.images ?? line.images;
    final name = line.name;
    final qty = line.quantity;
    final lineTotal = line.lineTotal;
    final variant = line.variantLabel;
    final sku = product?.sku;

    final chips = <String>[
      if (sku != null && sku.isNotEmpty) sku,
      if (variant.isNotEmpty) ...variant.split(' · '),
    ];

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 62,
              height: 78,
              child: images.isEmpty
                  ? ColoredBox(
                      color: accent,
                      child: Icon(
                        fallbackIcon,
                        size: 26,
                        color: brandColor.withValues(alpha: 0.5),
                      ),
                    )
                  : ProductImageTile(
                      url: images.first,
                      fit: BoxFit.cover,
                      placeholderIcon: fallbackIcon,
                      placeholderColor: accent,
                      placeholderAccent: brandColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showPrice
                          ? Pricing.money(lineTotal, currencySymbol: currency)
                          : 'Contact',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 14),
                        fontWeight: FontWeight.bold,
                        color: brandColor,
                      ),
                    ),
                  ],
                ),
                if (chips.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final chip in chips)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .scaffoldBackgroundColor,
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            chip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(
                                context,
                                mobile: 11,
                              ),
                              color: AppPalette.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Stepper(
                      qty: qty,
                      atLimit: atLimit,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Move to wishlist',
                      visualDensity: VisualDensity.compact,
                      onPressed: onMove,
                      icon: Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
                if (atLimit) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Only $qty left in stock',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 11),
                      color: Colors.orange[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.qty,
    required this.atLimit,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int qty;
  final bool atLimit;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap, String tooltip) {
      final enabled = onTap != null;
      return SizedBox(
        width: 30,
        height: 30,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: 16,
          onPressed: onTap,
          icon: Icon(icon, color: enabled ? null : Colors.grey[400]),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove, onDecrement, 'Decrease quantity'),
          SizedBox(
            width: 34,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          button(
            Icons.add,
            atLimit ? null : onIncrement,
            atLimit ? 'Maximum in stock' : 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

/// Pincode delivery check for the bag, same six-digit answer as the detail
/// page: a valid code gives the arrival date, anything else is called out.
class _CartPincode extends StatefulWidget {
  const _CartPincode({required this.accent});

  final Color accent;

  @override
  State<_CartPincode> createState() => _CartPincodeState();
}

class _CartPincodeState extends State<_CartPincode> {
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

  final _controller = TextEditingController();
  String? _error;
  String? _deliveryBy;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final value = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      setState(() {
        _error = 'Enter a 6-digit pincode';
        _deliveryBy = null;
      });
      return;
    }
    final eta = DateTime.now().add(const Duration(days: 4));
    setState(() {
      _error = null;
      _deliveryBy =
          'Delivery by ${_weekdays[eta.weekday - 1]}, ${eta.day} ${_months[eta.month - 1]}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Check delivery', style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                onSubmitted: (_) => _check(),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Enter 6-digit pincode',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton(text: 'Check', onPressed: _check),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _error!,
            style: AppTypography.caption.copyWith(color: AppPalette.error),
          ),
        ],
        if (_deliveryBy != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 15,
                color: widget.accent,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _deliveryBy!,
                  style: AppTypography.caption.copyWith(
                    color: AppPalette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.brand, required this.icon});

  final Color brand;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Your bag is empty',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 16),
                fontWeight: FontWeight.w600,
                color: AppPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add something you love and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppPalette.textMuted),
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Start shopping',
              icon: Icons.shopping_bag_outlined,
              color: brand,
              onPressed: () => context.go('/app'),
            ),
          ],
        ),
      ),
    );
  }
}
