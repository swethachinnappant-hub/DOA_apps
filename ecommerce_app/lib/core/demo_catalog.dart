import 'package:flutter/material.dart';

import 'product.dart';

/// Demo catalogue used until a real backend is wired up.
///
/// Demo products use bundled, gold-jewellery-only photos so the catalogue is
/// reliable offline and never shows unrelated random imagery.
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
    'gold earrings': Icons.blur_circular_outlined,
    'gold rings': Icons.radio_button_unchecked,
    'bridal jewellery': Icons.favorite_outline,
    'gold chains': Icons.link,
    'gold bangles': Icons.circle_outlined,
    'bracelets': Icons.circle_outlined,
    'pendants': Icons.diamond_outlined,
  };

  static const List<List<ProductVariant>> _sizeSets = [
    [],
    [ProductVariant('S'), ProductVariant('M'), ProductVariant('L')],
    [ProductVariant('Free Size')],
  ];

  static const List<List<ProductVariant>> _shadeSets = [
    [],
    [
      ProductVariant('Yellow Gold', swatch: Color(0xFFD4A843)),
      ProductVariant('Antique Gold', swatch: Color(0xFFC9A227)),
      ProductVariant('Rose Gold', swatch: Color(0xFFB76E79)),
      // White Gold so the Shop by Metal chip always has real stock to land on.
      ProductVariant('White Gold', swatch: Color(0xFFD9DDE3)),
    ],
  ];

  static const List<List<String>> _highlightSets = [
    [
      'Demo sample image and listing',
      'Confirm hallmark and purity with the jeweller',
      'Final price depends on live gold rate and weight',
    ],
    [
      'Traditional Indian gold design',
      'Confirm weight and making charges before purchase',
      'Illustrative listing for store demonstration',
    ],
  ];

  static const String _ring = 'assets/demo_jewellery/ring_unsplash.jpg';
  static const String _earrings = 'assets/demo_jewellery/earrings_unsplash.jpg';
  static const String _bangles = 'assets/demo_jewellery/bracelet_unsplash.jpg';
  static const String _pendant = 'assets/demo_jewellery/pendant_unsplash.jpg';
  static const String _necklace = 'assets/demo_jewellery/necklace_unsplash.jpg';
  static const String _bridalSet = 'assets/demo_jewellery/bridal_set.jpg';

  /// Demo pieces include the full product image plus two close-up detail
  /// views, so every seeded listing can demonstrate a real multi-image flow.
  static List<String> imagesForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('bridal')) {
      return const [
        _bridalSet,
        _necklace,
        'assets/demo_jewellery/bridal_set_detail_necklace.jpg',
        'assets/demo_jewellery/bridal_set_detail_earrings.jpg',
      ];
    }
    if (value.contains('ring')) {
      return const [
        _ring,
        'assets/demo_jewellery/gold_ring.jpg',
        'assets/demo_jewellery/gold_ring_detail_stone.jpg',
        'assets/demo_jewellery/gold_ring_detail_band.jpg',
      ];
    }
    if (value.contains('earring')) {
      return const [
        _earrings,
        'assets/demo_jewellery/gold_earrings.jpg',
        'assets/demo_jewellery/gold_earrings_detail_left.jpg',
        'assets/demo_jewellery/gold_earrings_detail_right.jpg',
      ];
    }
    if (value.contains('bangle') || value.contains('bracelet')) {
      return const [
        _bangles,
        'assets/demo_jewellery/gold_bangles.jpg',
        'assets/demo_jewellery/gold_bangles_detail_left.jpg',
        'assets/demo_jewellery/gold_bangles_detail_right.jpg',
      ];
    }
    if (value.contains('pendant') ||
        value.contains('chain') ||
        value.contains('children') ||
        value.contains('men')) {
      return const [
        _pendant,
        'assets/demo_jewellery/gold_pendant.jpg',
        'assets/demo_jewellery/gold_pendant_detail.jpg',
        'assets/demo_jewellery/gold_pendant_chain_detail.jpg',
      ];
    }
    return const [
      _necklace,
      _bridalSet,
      'assets/demo_jewellery/bridal_necklace_detail_pendant.jpg',
      'assets/demo_jewellery/bridal_necklace_detail_motif.jpg',
    ];
  }

  /// Uses a photo that matches the item's jewellery category.
  static String imageForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('bridal')) return _bridalSet;
    if (value.contains('ring')) return _ring;
    if (value.contains('earring')) return _earrings;
    if (value.contains('bangle') || value.contains('bracelet')) return _bangles;
    if (value.contains('pendant') || value.contains('chain')) return _pendant;
    if (value.contains('children') || value.contains('men')) return _pendant;
    return _necklace;
  }

  static String _nameForCategory(String category, int index) {
    final value = category.toLowerCase();
    if (value.contains('bridal')) return 'Bridal Temple Gold Necklace Set';
    if (value.contains('ring')) return 'Floral Engraved Gold Ring';
    if (value.contains('earring')) return 'Traditional Gold Jhumka Earrings';
    if (value.contains('bangle')) return 'Engraved Gold Bangles';
    if (value.contains('bracelet')) return 'Classic Gold Link Bracelet';
    if (value.contains('pendant')) return 'Floral Gold Pendant';
    if (value.contains('chain')) return 'Classic Gold Chain';
    if (value.contains('necklace')) return 'Temple Motif Gold Necklace';
    if (value.contains("children")) return "Children's Gold Chain";
    if (value.contains("men")) return "Men's Gold Chain";
    return 'Gold Jewellery Sample ${index + 1}';
  }

  static String _imageFamilyForCategory(String category) {
    final value = category.toLowerCase();
    if (value.contains('bridal')) return 'bridal';
    if (value.contains('ring')) return 'ring';
    if (value.contains('earring')) return 'earring';
    if (value.contains('bangle') || value.contains('bracelet')) return 'bangle';
    if (value.contains('pendant') ||
        value.contains('chain') ||
        value.contains('children') ||
        value.contains('men')) {
      return 'chain-pendant';
    }
    return 'necklace';
  }

  /// Builds [count] demo products for the supplied category list. The
  /// default covers every configured category twice over for the first six
  /// (14 was too thin — ten of twelve categories held a single design), while
  /// staying at 18: tests rely on there being no second Necklaces design and
  /// no LOAD MORE page past 24.
  static List<Product> build(List<String> categories, {int count = 18}) {
    if (categories.isEmpty) return const [];

    final familyUsage = <String, int>{};
    return List.generate(count, (i) {
      final category = categories[i % categories.length];
      final brand = _brands[i % _brands.length];
      final icon =
          _categoryIcons[category.toLowerCase()] ?? Icons.shopping_bag_outlined;
      final mrp = 1200 + (i * 640) % 9000;
      final price = mrp - ((mrp * (18 + (i % 5) * 9)) ~/ 100);
      final deliveryDays = 2 + (i % 5);
      final shades = _shadeSets[i % _shadeSets.length];
      final shadeNames = shades.map((s) => s.name).join(', ');
      final categoryImages = imagesForCategory(category);
      final family = _imageFamilyForCategory(category);
      final imageOffset = familyUsage.update(
        family,
        (count) => count + 1,
        ifAbsent: () => 0,
      ) % categoryImages.length;
      final productImages = [
        ...categoryImages.skip(imageOffset),
        ...categoryImages.take(imageOffset),
      ];

      return Product(
        id: 'p$i',
        name: _nameForCategory(category, i),
        brand: brand,
        category: category,
        sku: 'SKU-${(i + 1).toString().padLeft(4, '0')}',
        price: price,
        mrp: mrp,
        rating: 3.6 + ((i * 7) % 14) / 10,
        reviewCount: 24 + (i * 137) % 4200,
        images: productImages,
        icon: icon,
        sizes: _sizeSets[i % _sizeSets.length],
        shades: shades,
        highlights: _highlightSets[i % _highlightSets.length],
        description:
            'From the $brand $category collection.'
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
        wholesalePriceTiers: [
          WholesalePriceTier(minimumQuantity: 6, unitPrice: price * 95 ~/ 100),
          WholesalePriceTier(minimumQuantity: 12, unitPrice: price * 90 ~/ 100),
        ],
        occasions: category.toLowerCase().contains('bridal')
            ? const ['Wedding', 'Festive']
            : (i.isEven
                  ? const ['Daily wear', 'Festive']
                  : const ['Daily wear']),
        // Structured metal family so the Shop by Metal filter matches on data
        // (the tone itself lives in the shades, which the chips also match).
        // 'Gold' keeps the value inside the owner console's Taxonomy.metals.
        metal: 'Gold',
        // Seeded platform stock ships verified (§6.40); owner listings
        // start unverified.
        isVerifiedSupplier: true,
      );
    });
  }

  static const List<String> _purities = ['22K Yellow Gold', '18K Yellow Gold'];

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
      'Making Charge': 'Demo ${8 + (i % 6)}% (confirm with jeweller)',
      'Wastage': 'Demo ${1 + (i % 3)}% (confirm with jeweller)',
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
