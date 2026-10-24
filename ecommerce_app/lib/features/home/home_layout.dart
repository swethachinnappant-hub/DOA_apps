import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store/commerce_store.dart';
import '../../widgets/jewellery_collage_hero.dart';
import '../shell/site_footer.dart';
import 'home_sections.dart';

/// One slot in the ordered home stack (§6.1): a stable id for keys/reordering
/// plus the builder that draws the section.
class HomeSection {
  const HomeSection(this.id, this.build);

  /// Stable identifier, e.g. `hero` — used as the widget key and the unit of
  /// reordering.
  final String id;
  final WidgetBuilder build;
}

/// The home page as an ordered list of sections (§6.1 / §16.2), so sections
/// can be reordered or hidden without redesigning the page.
class HomeLayout {
  const HomeLayout(this.sections);

  final List<HomeSection> sections;

  /// The buyer journey follows the homepage spec order: promotional hero,
  /// discovery rails, wholesale deals, bridal, collections, recently viewed,
  /// then the editorial collage and story sections.
  factory HomeLayout.standard() => HomeLayout([
    const HomeSection('hero', _hero),
    const HomeSection('categories', _categories),
    const HomeSection('bestsellers', _bestsellers),
    const HomeSection('newArrivals', _newArrivals),
    const HomeSection('metal', _metal),
    const HomeSection('trending', _trending),
    const HomeSection('price', _price),
    const HomeSection('deals', _deals),
    const HomeSection('bridal', _bridal),
    const HomeSection('collections', _collections),
    const HomeSection('completeLook', _completeLook),
    const HomeSection('recentlyViewed', _recentlyViewed),
    const HomeSection('details', _details),
    const HomeSection('occasion', _occasion),
    const HomeSection('gifts', _gifts),
    const HomeSection('social', _social),
    const HomeSection('about', _about),
    const HomeSection('footer', _footer),
  ]);

  /// Returns a copy with the listed ids moved to the front, in that order.
  /// Ids omitted from [order] keep their original relative order behind them,
  /// and unknown ids are ignored — so a caller can nudge one section without
  /// restating the whole stack.
  HomeLayout reorder(List<String> order) {
    final byId = {for (final section in sections) section.id: section};
    final reordered = <HomeSection>[];
    for (final id in order) {
      final section = byId.remove(id);
      if (section != null) reordered.add(section);
    }
    reordered.addAll(sections.where((section) => byId.containsKey(section.id)));
    return HomeLayout(reordered);
  }
}

Widget _hero(BuildContext context) => const HeroBanner();
Widget _categories(BuildContext context) => const ShopByCategory();

/// The editorial "Made to be noticed" collage — now a first-class section so
/// the Home Builder can reorder or hide it like every other block.
Widget _details(BuildContext context) {
  final products = [...context.watch<CommerceStore>().shopProducts]
    ..sort((a, b) {
      final rating = b.rating.compareTo(a.rating);
      return rating != 0 ? rating : b.reviewCount.compareTo(a.reviewCount);
    });
  // The editorial collage needs three distinct picks; skipping ten on a
  // small demo catalogue left two (the hero collapsed to nothing).
  final source = products.length > 8 ? products.sublist(4) : products;
  return JewelleryCollageHero(products: source);
}

Widget _metal(BuildContext context) => const ShopByMetal();
Widget _collections(BuildContext context) => const CollectionsRail();
Widget _bestsellers(BuildContext context) => const BestsellersRail();
Widget _newArrivals(BuildContext context) => const NewArrivalsRail();
Widget _trending(BuildContext context) => const TrendingRail();
Widget _deals(BuildContext context) => const WholesaleDealsRail();
Widget _completeLook(BuildContext context) => const CompleteLookRail();
Widget _recentlyViewed(BuildContext context) => const RecentlyViewedRail();
Widget _occasion(BuildContext context) => const ShopByOccasion();
Widget _price(BuildContext context) => const PriceBands();
Widget _bridal(BuildContext context) => const BridalBanner();
Widget _gifts(BuildContext context) => const GiftSplit();
Widget _social(BuildContext context) => const SocialStrip();
Widget _about(BuildContext context) => const AboutCollection();
Widget _footer(BuildContext context) => const SiteFooter();

/// The customer-facing stack: the owner's saved order and visibility edits
/// (SPEC-18) layered over the §6.1 standard layout, so a Home Builder change
/// lands with no restart. Sections the standard stack no longer knows are
/// dropped; ones added after the save are appended.
HomeLayout resolveHomeLayout(CommerceStore store) {
  final standard = HomeLayout.standard();
  if (!store.hasHomeEdits) return standard;
  final byId = {for (final section in standard.sections) section.id: section};
  final hidden = store.homeSectionHidden;
  final ordered = <HomeSection>[
    for (final id in store.homeSectionOrder)
      if (byId[id] != null && !hidden.contains(id)) byId[id]!,
  ];
  for (final section in standard.sections) {
    if (store.homeSectionOrder.contains(section.id)) continue;
    if (hidden.contains(section.id)) continue;
    ordered.add(section);
  }
  return HomeLayout(ordered);
}
