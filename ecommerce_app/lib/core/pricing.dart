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

  static int total(int subtotal) => subtotal + tax(subtotal) + shipping(subtotal);
}
