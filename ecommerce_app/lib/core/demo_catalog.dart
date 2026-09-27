import 'package:flutter/material.dart';

import 'product.dart';

/// Demo catalogue used until a real backend is wired up.
///
/// Each product gets several distinct image URLs so the multi-image carousel
/// has something real to scroll through. The `picsum.photos` seeds are stable,
/// so a given product always shows the same set of photos.
class DemoCatalog {
  const DemoCatalog._();

  static const List<String> _brands = [
    'Aurelia',
    'Nuvira',
    'Chandni',
    'Rangrez',
    'Silk Route',
    'Maison Claire',
    'Vanya',
    'The Edit',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'necklaces': Icons.diamond_outlined,
    'earrings': Icons.blur_circular_outlined,
    'rings': Icons.radio_button_unchecked,
    'bridal': Icons.favorite_outline,
    'gold chains': Icons.link,
    'silver': Icons.brightness_2_outlined,
    'watches': Icons.watch_outlined,
    'home decor': Icons.chair_outlined,
  };

  static const List<List<ProductVariant>> _sizeSets = [
    [],
    [ProductVariant('S'), ProductVariant('M'), ProductVariant('L')],
    [ProductVariant('Free Size')],
  ];

  static const List<List<ProductVariant>> _shadeSets = [
    [],
    [
      ProductVariant('Rose Gold', swatch: Color(0xFFB76E79)),
      ProductVariant('Champagne', swatch: Color(0xFFD9C7A3)),
      ProductVariant('Antique Gold', swatch: Color(0xFFC9A227)),
      ProductVariant('Silver', swatch: Color(0xFFC0C0C0)),
    ],
  ];

  static const List<List<String>> _highlightSets = [
    [
      'Hallmarked 14K gold plating',
      'Skin friendly, nickel free',
      'Includes premium packaging box',
    ],
    [
      'Anti-tarnish coating',
      'Lightweight everyday wear',
      ' Comes with authenticity certificate',
    ],
  ];

  static String _image(String seed, int index) =>
      'https://picsum.photos/seed/${seed}_$index/640/800';

  /// Builds [count] demo products for the supplied category list.
  static List<Product> build(List<String> categories, {int count = 14}) {
    if (categories.isEmpty) return const [];

    return List.generate(count, (i) {
      final category = categories[i % categories.length];
      final brand = _brands[i % _brands.length];
      final icon = _categoryIcons[category.toLowerCase()] ?? Icons.shopping_bag_outlined;
      final seed = '${category}_${brand}_$i'.replaceAll(' ', '_');

      final imageCount = 3 + (i % 3); // 3, 4 or 5 angles per product
      final mrp = 1200 + (i * 640) % 9000;
      final price = mrp - ((mrp * (18 + (i % 5) * 9)) ~/ 100);
      final deliveryDays = 2 + (i % 5);
      final shades = _shadeSets[i % _shadeSets.length];
      final shadeNames = shades.map((s) => s.name).join(', ');

      return Product(
        id: 'p$i',
        name: '$brand $category ${['Pendant', 'Set', 'Duo', 'Edition'][i % 4]}',
        brand: brand,
        category: category,
        sku: 'SKU-${(i + 1).toString().padLeft(4, '0')}',
        price: price,
        mrp: mrp,
        rating: 3.6 + ((i * 7) % 14) / 10,
        reviewCount: 24 + (i * 137) % 4200,
        images: List.generate(imageCount, (n) => _image(seed, n)),
        icon: icon,
        sizes: _sizeSets[i % _sizeSets.length],
        shades: shades,
        highlights: _highlightSets[i % _highlightSets.length],
        description: 'From the $brand $category collection.'
            '${shadeNames.isEmpty ? '' : ' Offered in $shadeNames.'}'
            ' Dispatched within $deliveryDays days.',
        specs: _specs(i),
        badges: switch (i % 4) {
          0 => const ['Bestseller'],
          1 => const ['New In'],
          2 => const ['Limited Edition'],
          _ => const [],
        },
        inStock: i % 11 != 0,
        deliveryDays: deliveryDays,
        createdAt: DateTime.now().subtract(Duration(hours: i)),
      );
    });
  }

  static const List<String> _purities = [
    '18K Yellow Gold',
    '22K Yellow Gold',
    '18K Rose Gold',
    'Platinum 950',
  ];

  /// Specification rows keyed by the labels the jewellery business declares in
  /// `productFields`, so the detail page renders a filled spec table for a
  /// jewellery store and simply ignores them for any other business type.
  static Map<String, String> _specs(int i) {
    final gross = 4 + (i % 7);
    final stone = (i % 3) == 0 ? 0.0 : 0.4 + ((i % 5) * 0.25);
    final net = gross - stone;
    return {
      'Gold Purity': _purities[i % _purities.length],
      'Gross Weight': '${gross.toStringAsFixed(3)} g',
      'Net Weight': '${net.toStringAsFixed(3)} g',
      'Stone Weight': '${stone.toStringAsFixed(3)} g',
      'Making Charge': '${8 + (i % 6)}% of gold value',
      'Wastage': '${1 + (i % 3)}%',
    };
  }

  /// Deterministic lookup so a tapped card can open its own detail page.
  ///
  /// Returns `null` for an unknown id instead of silently falling back to an
  /// unrelated product, so a bad route shows a "not found" state rather than
  /// the wrong item.
  static Product? byId(List<Product> products, String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }
}
