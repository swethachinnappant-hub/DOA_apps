import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double giant = 48;

  static const double screenH = 16;
  static const double screenV = 16;

  /// Section rhythm / grid gutters run tight — the storefront is image-first,
  /// so chrome spacing yields to photography (thin gutters, dense grids).
  /// §9.63: every helper below sits on the 4-point grid (most on 8).
  static const double sectionGap = 16;
  static const double headerToContent = 12;
  static const double gridCross = 4;
  static const double gridMain = 4;
  static const double cardPadding = 12;
  static const double listGap = 12;
  static const double chipGap = 8;

  // Section rhythm per device class (architecture §2.3, tightened).
  static const double sectionGapCompact = 16;
  static const double sectionGapMedium = 24;
  static const double sectionGapExpanded = 28;

  // Grid gutters per device class (architecture §3.1, tightened to thin gaps).
  static const double gutterCompact = 4;
  static const double gutterMedium = 8;
  static const double gutterExpanded = 12;

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 16,
  );
  static const EdgeInsets card = EdgeInsets.all(12);
  static const EdgeInsets section = EdgeInsets.fromLTRB(16, 0, 16, 24);
}

class AppRadius {
  const AppRadius._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double pill = 999;

  static const BorderRadius allXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius allSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius allMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius allLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius allXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius allXxl = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius allPill = BorderRadius.all(Radius.circular(pill));

  static const double circle = 999;
}

class AppPalette {
  const AppPalette._();

  /// Warm ivory page background (UI spec §9: `#FAF8F4`).
  static const Color background = Color(0xFFFAF8F4);
  /// Cards and inputs stay pure white so product photography reads cleanly.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF4EFE7);
  /// Primary text — near-black ink (UI spec §9: `#1C1B19`).
  static const Color textPrimary = Color(0xFF1C1B19);
  static const Color textSecondary = Color(0xFF666666);
  /// Hint text darkened from #888888 so small captions clear 4.5:1 AA on
  /// both white and the warm ivory background (UI spec §10.73).
  static const Color textHint = Color(0xFF707070);
  static const Color divider = Color(0xFFE8E2D8);
  static const Color border = Color(0xFFE5DFD5);
  static const Color skeleton = Color(0xFFF0EBE3);
  static const Color skeletonHighlight = Color(0xFFFAF8F4);
  static const Color success = Color(0xFF2D7D46);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF1E5F74);
  static const Color overlay = Color(0xCC171717);

  /// Accent gold (UI spec §9: `#B18A45`) — highlights, badges, active states.
  static const Color gold = Color(0xFFB18A45);

  /// Pale gold tint for selected chips and soft highlight surfaces.
  static const Color goldLight = Color(0xFFF2E8D5);

  /// Darkened gold that stays AA for small text on light backgrounds.
  static const Color goldDark = Color(0xFF8A6A33);

  /// Ink used on gold fills (5.3:1 against [gold]).
  static const Color onGold = Color(0xFF1C1B19);

  // --- Jewellery storefront brand (architecture §2.1) --------------------
  /// Monochrome primary retained under its legacy semantic name.
  static const Color copper = Color(0xFF171717);

  /// Secondary ink used for muted links and controls.
  static const Color copperDark = Color(0xFF333333);

  /// Pressed state for monochrome controls.
  static const Color copperPressed = Color(0xFF111111);

  /// Selected chips and subtle eligible-state surfaces.
  static const Color copperTint = Color(0xFFF1ECE3);

  /// Alternate warm section band.
  static const Color warm = Color(0xFFF5F1EA);

  /// Hairline dividers / card borders on warm surfaces.
  static const Color hairline = Color(0xFFEAE3DB);

  /// Architectural ink (headings/body) per spec.
  static const Color ink = Color(0xFF1C1B19);

  /// Supporting text per spec.
  static const Color textSupporting = Color(0xFF555555);

  /// Captions / strikethrough MRP per spec — AA on white and ivory (§10.73).
  static const Color textMuted = Color(0xFF6B6B6B);

  /// Mobile drawer / dark chrome surface (inferred from white icon set).
  static const Color drawerSurface = Color(0xFF1E1E1E);

  // Metal swatch colours (replace with brand swatch images when available).
  static const Color metalYellow = Color(0xFFE6C46A);
  static const Color metalWhite = Color(0xFFE5E5E8);
  static const Color metalRose = Color(0xFFE8B4A0);
}

class AppShadows {
  const AppShadows._();

  static const List<BoxShadow> none = [];

  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> raised = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Hover-lifted card / mega-menu panel elevation (architecture §2.3).
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 6)),
  ];

  static List<BoxShadow> primary(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTypography {
  const AppTypography._();

  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.0,
    height: 1.15,
    color: AppPalette.textPrimary,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppPalette.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppPalette.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
    color: AppPalette.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppPalette.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppPalette.textPrimary,
  );

  static const TextStyle bodyMuted = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppPalette.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppPalette.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
    color: AppPalette.textPrimary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    // UI spec §2.10: keep tracking tight on small text.
    letterSpacing: 0.4,
    height: 1.2,
    color: AppPalette.textSecondary,
  );

  static const TextStyle price = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppPalette.textPrimary,
  );

  static const TextStyle priceLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.15,
    color: AppPalette.textPrimary,
  );

  static const TextStyle priceStrike = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.2,
    color: AppPalette.textHint,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.2,
  );

  // --- Jewellery storefront additions (architecture §2.2) ----------------

  /// Top-nav label: UI sans, uppercase, tracked out. Uppercase the string
  /// at the call site (`label.toUpperCase()`).
  static const TextStyle navLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    // UI spec §2.10: keep tracking tight on small text.
    letterSpacing: 0.4,
    height: 1.2,
    color: AppPalette.textPrimary,
  );

  /// Primary button label: uppercase, tracked (§2.2).
  static const TextStyle buttonUppercase = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.2,
    color: Colors.white,
  );

  /// Hero / display headline for the expanded shell (§2.2: 48/56).
  static const TextStyle heroLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.2,
    height: 1.1,
    color: AppPalette.textPrimary,
  );

  /// Small muted eyebrow above section titles.
  static const TextStyle eyebrow = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    // UI spec §2.10: mild tracking, legible at 12 px.
    letterSpacing: 0.6,
    height: 1.3,
    color: AppPalette.goldDark,
  );

  /// Footer column heading (§5.8).
  static const TextStyle footerHeading = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
    color: AppPalette.textPrimary,
  );
}

class AppGrid {
  const AppGrid._();

  static SliverGridDelegateWithFixedCrossAxisCount product({
    required int crossAxisCount,
    double crossAxisSpacing = AppSpacing.gridCross,
    double mainAxisSpacing = AppSpacing.gridMain,
    double childAspectRatio = 0.68,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration carousel = Duration(milliseconds: 3000);
}
