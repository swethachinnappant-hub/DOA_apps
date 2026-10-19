import 'package:ecommerce_app/core/pricing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pricing.karatOf', () {
    test('parses the karat out of a purity spec', () {
      expect(Pricing.karatOf('22K Yellow Gold'), 22);
      expect(Pricing.karatOf('18K Yellow Gold'), 18);
      expect(Pricing.karatOf('14K'), 14);
      expect(Pricing.karatOf('  18 K white '), 18);
    });

    test('returns null when nothing parses', () {
      expect(Pricing.karatOf(''), isNull);
      expect(Pricing.karatOf('pure gold'), isNull);
      expect(Pricing.karatOf('Gold'), isNull);
    });
  });

  group('Pricing.variantFactor', () {
    test('an untouched variant sits at exactly 1.0', () {
      expect(Pricing.variantFactor(), 1.0);
      expect(
        Pricing.variantFactor(shade: 'Yellow Gold', baseKarat: 18, purity: 18),
        1.0,
      );
      expect(Pricing.variantFactor(shade: null), 1.0);
      expect(Pricing.variantFactor(shade: 'Not A Metal'), 1.0);
    });

    test('premium metal tones multiply the price', () {
      expect(Pricing.variantFactor(shade: 'Rose Gold'), 1.02);
      expect(Pricing.variantFactor(shade: 'White Gold'), 1.04);
      expect(Pricing.variantFactor(shade: 'Antique Gold'), 1.03);
    });

    test('purity scales against the karat the listing is priced at', () {
      expect(
        Pricing.variantFactor(baseKarat: 18, purity: 14),
        closeTo(14 / 18, 0.0001),
      );
      expect(
        Pricing.variantFactor(baseKarat: 22, purity: 22),
        1.0,
      );
      expect(
        Pricing.variantFactor(shade: 'Rose Gold', baseKarat: 18, purity: 14),
        closeTo(1.02 * 14 / 18, 0.0001),
      );
    });
  });

  group('Pricing.scaled', () {
    test('rounds to whole rupees', () {
      expect(Pricing.scaled(1299, 1.0), 1299);
      expect(Pricing.scaled(1000, 1.02), 1020);
      expect(Pricing.scaled(999, 1.5), 1499);
    });
  });

  group('Pricing.computeBreakup', () {
    test('rows add back up to the displayed total exactly', () {
      for (final total in const [1200, 4599, 45900, 149900, 999999]) {
        final breakup = Pricing.computeBreakup(total);
        expect(
          breakup.gold + breakup.diamond + breakup.making + breakup.gst,
          total,
          reason: 'rows must reconcile for $total',
        );
        expect(breakup.total, total);
      }
    });

    test('GST is the included portion of a tax-inclusive price', () {
      for (final total in const [1200, 45900, 149900]) {
        final breakup = Pricing.computeBreakup(total);
        expect(breakup.gst, total - (total / (1 + Pricing.gstRate)).round());
        expect(breakup.gst, greaterThan(0));
      }
    });

    test('falls back to the default making rate without specs', () {
      const total = 10000;
      final breakup = Pricing.computeBreakup(total);
      final base = (total / (1 + Pricing.gstRate)).round();
      expect(breakup.making, (base * Pricing.defaultMakingRate).round());
      expect(breakup.diamond, 0, reason: 'no weights means no stone share');
      expect(breakup.gold, base - breakup.making);
    });

    test('splits using the listing making percentage and stone weight', () {
      const specs = {
        'Making Charge': 'Demo 9% (confirm with jeweller)',
        'Net Weight': '8.600 g',
        'Stone Weight': '1.400 g',
      };
      const total = 10000;
      final breakup = Pricing.computeBreakup(total, specs: specs);

      final base = (total / (1 + Pricing.gstRate)).round();
      expect(breakup.making, (base * 0.09).round());
      final stoneRatio = 1.4 / (8.6 + 1.4);
      expect(
        breakup.diamond,
        ((base - breakup.making) * stoneRatio).round(),
      );
      expect(
        breakup.gold + breakup.diamond + breakup.making + breakup.gst,
        total,
      );
    });

    test('a zero or negative price collapses to an empty breakup', () {
      final breakup = Pricing.computeBreakup(0);
      expect(breakup.total, 0);
      expect(breakup.gold, 0);
      expect(breakup.gst, 0);
    });
  });

  group('Pricing.gramsOf', () {
    test('parses the first number of a weight row', () {
      expect(Pricing.gramsOf('4.250 g'), closeTo(4.25, 0.0001));
      expect(Pricing.gramsOf('12 g'), closeTo(12, 0.0001));
      expect(Pricing.gramsOf('0.000 g'), 0);
      expect(Pricing.gramsOf(null), 0);
      expect(Pricing.gramsOf('n/a'), 0);
    });
  });
}
