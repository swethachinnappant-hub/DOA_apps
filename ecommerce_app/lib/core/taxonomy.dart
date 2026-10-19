/// Merchandising vocabulary for the owner console (SPEC-18).
///
/// Curated option lists behind the product form's dropdowns and chips. They
/// are plain data so a future backend can replace them without touching the
/// form; empty values are always legal, meaning "the seller never chose one".
class Taxonomy {
  const Taxonomy._();

  static const List<String> families = [
    'Rings',
    'Earrings',
    'Necklaces',
    'Pendants',
    'Bracelets',
    'Bangles',
    'Chains',
    'Mangalsutra',
    'Nose pins',
    'Toe rings',
    'Coins & bars',
    'Jewellery sets',
  ];

  static const List<String> styles = [
    'Classic',
    'Contemporary',
    'Traditional',
    'Floral',
    'Minimal',
    'Statement',
    'Bridal',
    'Everyday',
  ];

  static const List<String> metals = [
    'Gold',
    'White Gold',
    'Rose Gold',
    'Diamond',
    'Platinum',
    'Silver',
    'Gemstone',
  ];

  static const List<String> purities = [
    '24K',
    '22K',
    '18K',
    '14K',
    'Platinum 950',
    'Sterling Silver',
  ];

  static const List<String> occasions = [
    'Daily wear',
    'Office wear',
    'Party wear',
    'Wedding',
    'Engagement',
    'Anniversary',
    'Birthday',
    'Festival',
    'Gifting',
  ];

  static const List<String> audiences = [
    'Women',
    'Men',
    'Unisex',
    'Kids',
    'Couples',
  ];

  /// Suggested spec keys for diamond paperwork, offered as one-tap chips in
  /// the product form. Values live in `Product.specs` like every other row.
  static const List<String> diamondSpecs = [
    'Diamond Weight',
    'Clarity',
    'Colour',
    'Cut',
    'Setting',
  ];
}
