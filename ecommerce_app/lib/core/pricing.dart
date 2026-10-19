/// Single source of truth for the charges the checkout applies.
///
/// The home trust bar, the product delivery copy and the order summary all
/// quote these figures, so they are defined once here rather than repeated.
class Pricing {
  const Pricing._();

  static const int freeShippingThreshold = 999;
  static const int standardShipping = 79;
  static const double gstRate = 0.18;

  /// Making charge applied when a listing never filled in its own percentage.
  static const double defaultMakingRate = 0.08;

  /// Karats offered on the detail page's purity selector.
  static const List<int> purityKarats = [14, 18, 22];

  /// Price multipliers per metal tone. Yellow gold is the baseline every
  /// listing is priced at; the alloy tones carry a small premium.
  static const Map<String, double> metalFactors = {
    'Yellow Gold': 1.0,
    'Antique Gold': 1.03,
    'Rose Gold': 1.02,
    'White Gold': 1.04,
  };

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

  /// The karat a purity spec such as `22K Yellow Gold` declares, or `null`
  /// when the listing carries no parseable purity.
  static int? karatOf(String purity) {
    final match = RegExp(r'^(\d+)\s*K').firstMatch(purity.trim());
    return match == null ? null : int.parse(match.group(1)!);
  }

  static double shadeFactor(String? shade) =>
      shade == null ? 1.0 : (metalFactors[shade] ?? 1.0);

  /// Combined multiplier for the chosen metal tone and purity against the
  /// karat the listing is priced at. A product always sits at factor 1.0
  /// until the shopper deviates from either default.
  static double variantFactor({
    String? shade,
    int? baseKarat,
    int? purity,
  }) {
    var factor = shadeFactor(shade);
    if (purity != null && baseKarat != null && baseKarat > 0) {
      factor *= purity / baseKarat;
    }
    return factor;
  }

  static int scaled(int amount, double factor) => (amount * factor).round();

  /// Pure-gold share of a piece, as a fraction of 24K: 22K → 0.9167.
  static double karatFactor(int? karat) =>
      karat == null || karat <= 0 ? 1.0 : karat / 24;

  /// Forward price from a daily metal rate (SPEC-18 → SPEC-19):
  /// `rate × net weight × karat factor × (1 + making%) × (1 + GST)`.
  ///
  /// The owner's gold-rate screen previews this against a weight; jewellery
  /// GST defaults to 3% rather than the catalog-wide 18%.
  static int rateEstimate({
    required int rateInrPerGram,
    required double netGrams,
    double karatFactor = 1.0,
    double makingPercent = 10,
    double gstRate = 0.03,
  }) {
    final metal = rateInrPerGram * netGrams * karatFactor;
    final withMaking = metal * (1 + makingPercent / 100);
    return (withMaking * (1 + gstRate)).round();
  }

  /// Splits a displayed price into the rows the PDP breakup table shows.
  ///
  /// The displayed price already includes GST, so the pre-tax base is
  /// recovered first and then divided into making, diamond and gold shares
  /// using the listing's own specification rows. The rows always add back up
  /// to [total] exactly, whichever variant is selected.
  static PriceBreakup computeBreakup(
    int total, {
    Map<String, String> specs = const {},
  }) {
    if (total <= 0) {
      return const PriceBreakup(
        gold: 0,
        diamond: 0,
        making: 0,
        gst: 0,
        total: 0,
      );
    }
    final base = (total / (1 + gstRate)).round();
    final making = (base * _makingRate(specs)).round();
    final diamond = ((base - making) * _stoneRatio(specs)).round();
    final gold = base - making - diamond;
    return PriceBreakup(
      gold: gold,
      diamond: diamond,
      making: making,
      gst: total - base,
      total: total,
    );
  }

  static double _makingRate(Map<String, String> specs) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*%',
    ).firstMatch(specs['Making Charge'] ?? '');
    if (match == null) return defaultMakingRate;
    return double.parse(match.group(1)!) / 100;
  }

  static double _stoneRatio(Map<String, String> specs) {
    final net = gramsOf(specs['Net Weight']);
    final stone = gramsOf(specs['Stone Weight']);
    final denominator = net + stone;
    if (denominator <= 0) return 0;
    return stone / denominator;
  }

  /// Parses the first number in a weight spec such as `4.250 g`, or 0 when
  /// the row is missing or unparseable.
  static double gramsOf(String? value) {
    if (value == null) return 0;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(value);
    return match == null ? 0 : double.parse(match.group(1)!);
  }
}

/// One row per line of the PDP price breakup table. The five rows sum to
/// [total] exactly: `gold + diamond + making + gst == total`.
class PriceBreakup {
  final int gold;
  final int diamond;
  final int making;
  final int gst;
  final int total;

  const PriceBreakup({
    required this.gold,
    required this.diamond,
    required this.making,
    required this.gst,
    required this.total,
  });
}
