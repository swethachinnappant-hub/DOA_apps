import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';

enum BusinessType {
  jewellery,
  dress,
  electronics,
  grocery,
  footwear,
  furniture,
  cosmetics,
  custom,
}

class BusinessRules {
  final bool allowScreenshots;
  final bool allowDownload;
  final bool allowShare;
  final bool showWatermark;
  final bool showPrices;
  final bool showContactInfo;
  final bool allowPriceSharing;
  final bool showMOQ;

  const BusinessRules({
    this.allowScreenshots = true,
    this.allowDownload = true,
    this.allowShare = true,
    this.showWatermark = false,
    this.showPrices = true,
    this.showContactInfo = true,
    this.allowPriceSharing = true,
    this.showMOQ = true,
  });

  BusinessRules copyWith({
    bool? allowScreenshots,
    bool? allowDownload,
    bool? allowShare,
    bool? showWatermark,
    bool? showPrices,
    bool? showContactInfo,
    bool? allowPriceSharing,
    bool? showMOQ,
  }) {
    return BusinessRules(
      allowScreenshots: allowScreenshots ?? this.allowScreenshots,
      allowDownload: allowDownload ?? this.allowDownload,
      allowShare: allowShare ?? this.allowShare,
      showWatermark: showWatermark ?? this.showWatermark,
      showPrices: showPrices ?? this.showPrices,
      showContactInfo: showContactInfo ?? this.showContactInfo,
      allowPriceSharing: allowPriceSharing ?? this.allowPriceSharing,
      showMOQ: showMOQ ?? this.showMOQ,
    );
  }

  static const Map<String, String> ruleLabels = {
    'allowScreenshots': 'Allow Screenshots',
    'allowDownload': 'Allow Image Download',
    'allowShare': 'Allow Product Sharing',
    'showWatermark': 'Show Watermark on Images',
    'showPrices': 'Show Prices',
    'showContactInfo': 'Show Seller Contact Info',
    'allowPriceSharing': 'Allow Price List Sharing',
    'showMOQ': 'Show Minimum Order Quantity',
  };

  static const Map<String, String> ruleDescriptions = {
    'allowScreenshots': 'When disabled, screenshots of product pages are blocked',
    'allowDownload': 'When disabled, long-press to save images is blocked',
    'allowShare': 'When disabled, share buttons are hidden throughout the app',
    'showWatermark': 'Adds business watermark overlay on product images',
    'showPrices': 'When disabled, prices are hidden (show "Contact for Price")',
    'showContactInfo': 'When disabled, seller phone/address are hidden',
    'allowPriceSharing': 'When disabled, price list cannot be shared externally',
    'showMOQ': 'Show minimum order quantity on product pages',
  };

  static const Map<String, IconData> ruleIcons = {
    'allowScreenshots': Icons.screenshot,
    'allowDownload': Icons.download,
    'allowShare': Icons.share,
    'showWatermark': Icons.water_drop,
    'showPrices': Icons.attach_money,
    'showContactInfo': Icons.contact_phone,
    'allowPriceSharing': Icons.price_change,
    'showMOQ': Icons.shopping_bag,
  };
}

class ColorPaletteOption {
  final String name;
  final Color primary;
  final Color secondary;
  final Color accent;

  const ColorPaletteOption({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.accent,
  });
}

class BusinessConfig {
  final BusinessType type;
  final String name;
  final String tagline;
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final List<String> categories;
  final Map<String, String> categoryIcons;
  final List<String> productFields;
  final String searchHint;
  final String currency;
  final String currencySymbol;
  final BusinessRules rules;

  const BusinessConfig({
    required this.type,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.categories,
    required this.categoryIcons,
    required this.productFields,
    required this.searchHint,
    this.currency = 'INR',
    this.currencySymbol = '₹',
    this.rules = const BusinessRules(),
  });

  BusinessConfig copyWith({
    BusinessRules? rules,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
  }) {
    return BusinessConfig(
      type: type,
      name: name,
      tagline: tagline,
      icon: icon,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      categories: categories,
      categoryIcons: categoryIcons,
      productFields: productFields,
      searchHint: searchHint,
      currency: currency,
      currencySymbol: currencySymbol,
      rules: rules ?? this.rules,
    );
  }

  BusinessConfig get defaults => BusinessConfig.configs[type]!;

  bool get hasCustomColors =>
      primaryColor != defaults.primaryColor ||
      secondaryColor != defaults.secondaryColor ||
      accentColor != defaults.accentColor;

  Color get onPrimaryColor =>
      primaryColor.computeLuminance() > 0.55 ? Colors.black : Colors.white;

  static const Map<BusinessType, BusinessConfig> configs = {
    BusinessType.jewellery: BusinessConfig(
      type: BusinessType.jewellery,
      name: 'Jewellery B2B',
      tagline: 'Private Wholesale Jewellery Platform',
      icon: Icons.diamond,
      primaryColor: Color(0xFF8B6914),
      secondaryColor: Color(0xFFD4A843),
      accentColor: Color(0xFFF5E6C8),
      categories: [
        'Gold Chains', 'Gold Rings', 'Gold Earrings', 'Gold Bangles',
        'Bracelets', 'Pendants', 'Necklaces', 'Bridal Jewellery',
        "Children's Jewellery", "Men's Jewellery",
      ],
      categoryIcons: {
        'Gold Chains': '\u{1F517}', 'Gold Rings': '\u{1F48D}', 'Gold Earrings': '\u{2728}',
        'Gold Bangles': '\u{2B55}', 'Bracelets': '\u{231A}', 'Pendants': '\u{1F3AF}',
        'Necklaces': '\u{1F4FF}', 'Bridal Jewellery': '\u{1F470}',
        "Children's Jewellery": '\u{1F476}', "Men's Jewellery": '\u{1F466}',
      },
      productFields: ['Gold Purity', 'Gross Weight', 'Net Weight', 'Stone Weight', 'Making Charge', 'Wastage'],
      searchHint: 'Search jewellery, SKU, category...',
      rules: BusinessRules(
        allowScreenshots: false,
        allowDownload: false,
        allowShare: false,
        showWatermark: true,
        showPrices: true,
        showContactInfo: false,
        allowPriceSharing: false,
        showMOQ: true,
      ),
    ),
    BusinessType.dress: BusinessConfig(
      type: BusinessType.dress,
      name: 'Fashion B2B',
      tagline: 'Premium Wholesale Fashion Platform',
      icon: Icons.checkroom,
      primaryColor: Color(0xFF6B2D5B),
      secondaryColor: Color(0xFFB84A9D),
      accentColor: Color(0xFFF5E0F0),
      categories: [
        'Sarees', 'Kurtis', 'Lehengas', 'Suits',
        'Western Wear', 'Ethnic Wear', 'Men Wear', 'Kids Wear',
        'Accessories', 'Fabrics',
      ],
      categoryIcons: {
        'Sarees': '\u{1F9E3}', 'Kurtis': '\u{1F457}', 'Lehengas': '\u{1F458}', 'Suits': '\u{1F935}',
        'Western Wear': '\u{1F45A}', 'Ethnic Wear': '\u{1FBF7}', 'Men Wear': '\u{1F454}', 'Kids Wear': '\u{1F9D2}',
        'Accessories': '\u{1F45C}', 'Fabrics': '\u{1F9F5}',
      },
      productFields: ['Fabric', 'Size', 'Color', 'Pattern', 'Material', 'Occasion'],
      searchHint: 'Search dresses, SKU, category...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: true,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: true,
        showMOQ: true,
      ),
    ),
    BusinessType.electronics: BusinessConfig(
      type: BusinessType.electronics,
      name: 'Electronics B2B',
      tagline: 'Wholesale Electronics Platform',
      icon: Icons.devices,
      primaryColor: Color(0xFF1565C0),
      secondaryColor: Color(0xFF42A5F5),
      accentColor: Color(0xFFE3F2FD),
      categories: [
        'Mobile Phones', 'Laptops', 'Tablets', 'Accessories',
        'Audio', 'Cameras', 'Wearables', 'Home Appliances',
        'Smart Devices', 'Components',
      ],
      categoryIcons: {
        'Mobile Phones': '\u{1F4F1}', 'Laptops': '\u{1F4BB}', 'Tablets': '\u{1F4DF}', 'Accessories': '\u{1F3A7}',
        'Audio': '\u{1F50A}', 'Cameras': '\u{1F4F7}', 'Wearables': '\u{231A}', 'Home Appliances': '\u{1F3E0}',
        'Smart Devices': '\u{1F916}', 'Components': '\u{1F527}',
      },
      productFields: ['Brand', 'Model', 'Warranty', 'RAM', 'Storage', 'Color'],
      searchHint: 'Search electronics, SKU, brand...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: false,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: false,
        showMOQ: true,
      ),
    ),
    BusinessType.grocery: BusinessConfig(
      type: BusinessType.grocery,
      name: 'Grocery B2B',
      tagline: 'Wholesale Grocery Platform',
      icon: Icons.shopping_basket,
      primaryColor: Color(0xFF2E7D32),
      secondaryColor: Color(0xFF66BB6A),
      accentColor: Color(0xFFE8F5E9),
      categories: [
        'Fresh Vegetables', 'Fresh Fruits', 'Dairy Products', 'Grains & Pulses',
        'Spices', 'Snacks', 'Beverages', 'Packaged Food',
        'Cleaning', 'Personal Care',
      ],
      categoryIcons: {
        'Fresh Vegetables': '\u{1F96C}', 'Fresh Fruits': '\u{1F34E}', 'Dairy Products': '\u{1F95B}',
        'Grains & Pulses': '\u{1F33E}', 'Spices': '\u{1F336}\uFE0F', 'Snacks': '\u{1F37F}',
        'Beverages': '\u{1F964}', 'Packaged Food': '\u{1F4E6}', 'Cleaning': '\u{1F9F9}',
        'Personal Care': '\u{1F9F4}',
      },
      productFields: ['Brand', 'Weight', 'Expiry Date', 'MRP', 'Pack Size', 'Unit'],
      searchHint: 'Search groceries, SKU, brand...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: true,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: true,
        showMOQ: true,
      ),
    ),
    BusinessType.footwear: BusinessConfig(
      type: BusinessType.footwear,
      name: 'Footwear B2B',
      tagline: 'Wholesale Footwear Platform',
      icon: Icons.shopping_bag,
      primaryColor: Color(0xFF5D4037),
      secondaryColor: Color(0xFFA1887F),
      accentColor: Color(0xFFEFEBE9),
      categories: [
        'Formal Shoes', 'Casual Shoes', 'Sports Shoes', 'Sandals',
        'Slippers', 'Boots', 'Heels', 'Flats',
        'Kids Footwear', 'Ethnic Footwear',
      ],
      categoryIcons: {
        'Formal Shoes': '\u{1F45E}', 'Casual Shoes': '\u{1F45F}', 'Sports Shoes': '\u{1F3C3}',
        'Sandals': '\u{1FA74}', 'Slippers': '\u{1FA74}', 'Boots': '\u{1F462}',
        'Heels': '\u{1F460}', 'Flats': '\u{1F461}', 'Kids Footwear': '\u{1F476}',
        'Ethnic Footwear': '\u{1FA7F}',
      },
      productFields: ['Brand', 'Size', 'Color', 'Material', 'Type', 'Sole'],
      searchHint: 'Search footwear, SKU, brand...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: true,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: true,
        showMOQ: false,
      ),
    ),
    BusinessType.furniture: BusinessConfig(
      type: BusinessType.furniture,
      name: 'Furniture B2B',
      tagline: 'Wholesale Furniture Platform',
      icon: Icons.chair,
      primaryColor: Color(0xFF795548),
      secondaryColor: Color(0xFFBCAAA4),
      accentColor: Color(0xFFEFEBE9),
      categories: [
        'Living Room', 'Bedroom', 'Dining', 'Office',
        'Outdoor', 'Storage', 'Decor', 'Lighting',
        'Kitchen', 'Bathroom',
      ],
      categoryIcons: {
        'Living Room': '\u{1F6CB}\uFE0F', 'Bedroom': '\u{1F6CF}\uFE0F', 'Dining': '\u{1F37D}\uFE0F', 'Office': '\u{1F4BC}',
        'Outdoor': '\u{1F333}', 'Storage': '\u{1F5C4}\uFE0F', 'Decor': '\u{1F3A8}', 'Lighting': '\u{1F4A1}',
        'Kitchen': '\u{1F468}\u200D\u{1F373}', 'Bathroom': '\u{1F6BF}',
      },
      productFields: ['Material', 'Dimensions', 'Weight', 'Color', 'Style', 'Assembly'],
      searchHint: 'Search furniture, SKU, style...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: false,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: true,
        showMOQ: true,
      ),
    ),
    BusinessType.cosmetics: BusinessConfig(
      type: BusinessType.cosmetics,
      name: 'Cosmetics B2B',
      tagline: 'Wholesale Cosmetics Platform',
      icon: Icons.face,
      primaryColor: Color(0xFFAD1457),
      secondaryColor: Color(0xFFEC407A),
      accentColor: Color(0xFFFCE4EC),
      categories: [
        'Skincare', 'Makeup', 'Haircare', 'Fragrances',
        'Nail Care', 'Body Care', 'Men Grooming', 'Tools',
        'Organic', 'Professional',
      ],
      categoryIcons: {
        'Skincare': '\u{1F9F4}', 'Makeup': '\u{1F484}', 'Haircare': '\u{1F487}', 'Fragrances': '\u{1F338}',
        'Nail Care': '\u{1F485}', 'Body Care': '\u{1FEF7}', 'Men Grooming': '\u{1F488}', 'Tools': '\u{1FAAE}',
        'Organic': '\u{1F33F}', 'Professional': '\u{2728}',
      },
      productFields: ['Brand', 'Volume', 'Skin Type', 'Ingredients', 'Shade', 'SPF'],
      searchHint: 'Search cosmetics, SKU, brand...',
      rules: BusinessRules(
        allowScreenshots: false,
        allowDownload: false,
        allowShare: true,
        showWatermark: true,
        showPrices: true,
        showContactInfo: false,
        allowPriceSharing: false,
        showMOQ: true,
      ),
    ),
    BusinessType.custom: BusinessConfig(
      type: BusinessType.custom,
      name: 'Custom B2B',
      tagline: 'Your Custom Wholesale Platform',
      icon: Icons.store,
      primaryColor: Color(0xFF1E3A5F),
      secondaryColor: Color(0xFF2196F3),
      accentColor: Color(0xFFE3F2FD),
      categories: ['Category 1', 'Category 2', 'Category 3', 'Category 4'],
      categoryIcons: {'Category 1': '\u{1F4E6}', 'Category 2': '\u{1F4E6}', 'Category 3': '\u{1F4E6}', 'Category 4': '\u{1F4E6}'},
      productFields: ['Field 1', 'Field 2', 'Field 3', 'Field 4'],
      searchHint: 'Search products...',
      rules: BusinessRules(
        allowScreenshots: true,
        allowDownload: true,
        allowShare: true,
        showWatermark: false,
        showPrices: true,
        showContactInfo: true,
        allowPriceSharing: true,
        showMOQ: true,
      ),
    ),
  };

  static BusinessConfig getConfig(BusinessType type) => configs[type]!;

  static List<BusinessType> get allTypes => BusinessType.values;

  /// Curated brand palettes.
  ///
  /// Chosen to feel expensive rather than garish: deep jewel tones for the
  /// primary, a lighter harmonious partner for secondary, and a tinted
  /// off-white accent used for image wells and soft surfaces. Every
  /// `primary` is dark enough to carry white text, so buttons and badges stay
  /// legible.
  static const List<ColorPaletteOption> colorOptions = [
    // Classic luxury
    ColorPaletteOption(name: 'Royal Gold', primary: Color(0xFF8B6914), secondary: Color(0xFFD4A843), accent: Color(0xFFF7EDD8)),
    ColorPaletteOption(name: 'Champagne', primary: Color(0xFF7A6432), secondary: Color(0xFFE0CDA0), accent: Color(0xFFFBF6EA)),
    ColorPaletteOption(name: 'Antique Bronze', primary: Color(0xFF6B4A2A), secondary: Color(0xFFBE8F5A), accent: Color(0xFFF6EDE2)),
    ColorPaletteOption(name: 'Midnight Navy', primary: Color(0xFF1E3A5F), secondary: Color(0xFF3B82F6), accent: Color(0xFFEBF1F9)),
    ColorPaletteOption(name: 'Sapphire', primary: Color(0xFF1D4ED8), secondary: Color(0xFF60A5FA), accent: Color(0xFFE8EFFE)),
    ColorPaletteOption(name: 'Deep Maroon', primary: Color(0xFF7F1D3A), secondary: Color(0xFFC2185B), accent: Color(0xFFFBE9EF)),
    ColorPaletteOption(name: 'Royal Purple', primary: Color(0xFF5B21B6), secondary: Color(0xFF8B5CF6), accent: Color(0xFFF0E9FD)),
    ColorPaletteOption(name: 'Plum Velvet', primary: Color(0xFF4A1942), secondary: Color(0xFF9B3E77), accent: Color(0xFFF7EAF2)),
    ColorPaletteOption(name: 'Emerald', primary: Color(0xFF065F46), secondary: Color(0xFF10B981), accent: Color(0xFFDCF2E9)),
    ColorPaletteOption(name: 'Teal', primary: Color(0xFF0F766E), secondary: Color(0xFF2DD4BF), accent: Color(0xFFDAF3F1)),
    ColorPaletteOption(name: 'Forest Ink', primary: Color(0xFF1F3A2E), secondary: Color(0xFF4F7A5F), accent: Color(0xFFEAF2EC)),
    ColorPaletteOption(name: 'Copper', primary: Color(0xFF9A3412), secondary: Color(0xFFF97316), accent: Color(0xFFFDEEE2)),
    ColorPaletteOption(name: 'Rose Quartz', primary: Color(0xFF9D174D), secondary: Color(0xFFF472B6), accent: Color(0xFFFCE8F2)),
    ColorPaletteOption(name: 'Blush', primary: Color(0xFF9F1239), secondary: Color(0xFFFDA4AF), accent: Color(0xFFFDEEF1)),
    // Modern neutrals
    ColorPaletteOption(name: 'Onyx', primary: Color(0xFF111827), secondary: Color(0xFF6B7280), accent: Color(0xFFEEF0F3)),
    ColorPaletteOption(name: 'Graphite', primary: Color(0xFF374151), secondary: Color(0xFF9CA3AF), accent: Color(0xFFF1F2F4)),
    ColorPaletteOption(name: 'Warm Taupe', primary: Color(0xFF57534E), secondary: Color(0xFFA8A29E), accent: Color(0xFFF5F2EF)),
    ColorPaletteOption(name: 'Ivory Gold', primary: Color(0xFF854D0E), secondary: Color(0xFFE7C766), accent: Color(0xFFFCF6E3)),
  ];

  ThemeData getTheme() {
    return AppTheme.buildTheme(
      primary: primaryColor,
      secondary: secondaryColor,
      accent: accentColor,
    );
  }
}
