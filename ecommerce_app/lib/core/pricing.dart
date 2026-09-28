/// Single source of truth for the charges the checkout applies.
///
/// The home trust bar, the product delivery copy and the order summary all
/// quote these figures, so they are defined once here rather than repeated.
class Pricing {
  const Pricing._();

  static const int freeShippingThreshold = 999;
  static const int standardShipping = 79;
  static const double gstRate = 0.18;

  static int tax(int subtotal) => (subtotal * gstRate).round();

  static int shipping(int subtotal) =>
      subtotal >= freeShippingThreshold ? 0 : standardShipping;

  static int total(int subtotal) =>
      subtotal + tax(subtotal) + shipping(subtotal);

  /// Formats whole-rupee prices consistently across catalogue, bag and orders.
  /// Indian digit grouping keeps large jewellery prices easy to scan.
  static String money(int amount, {String currencySymbol = '₹'}) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    if (digits.length <= 3) {
      return '${negative ? '-' : ''}$currencySymbol$digits';
    }

    final lastThree = digits.substring(digits.length - 3);
    var prefix = digits.substring(0, digits.length - 3);
    final groups = <String>[];
    while (prefix.length > 2) {
      groups.insert(0, prefix.substring(prefix.length - 2));
      prefix = prefix.substring(0, prefix.length - 2);
    }
    groups.insert(0, prefix);
    return '${negative ? '-' : ''}$currencySymbol${groups.join(',')},$lastThree';
  }
}
