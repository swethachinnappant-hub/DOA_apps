import '../../core/navigation/menu_data.dart';
import '../../core/product.dart';

/// One breadcrumb step on a listing page (§7.1 header block).
class RouteCrumb {
  final String label;
  final String route;
  const RouteCrumb(this.label, this.route);
}

/// Content, service and editorial paths keep their designed landing page
/// (§6 SEO block, §10.7) instead of resolving to a product grid.
const Set<String> contentSectionPaths = {
  '/faq',
  '/feedback',
  '/contactusform',
  '/privacy-policy',
  '/shipping-and-return-policy',
  '/investors',
  '/terms-and-conditions',
  '/clp-terms',
  '/world-of-kirtilals',
  '/tryinstore',
  '/bespoke',
  '/virtual-tryon',
  '/virtualstoreproduct',
  '/co-shopping-products',
  '/giftcardsforms',
  '/realbrides',
  '/navaratna',
  '/goldjewellerypromotion',
    '/blog/country/kirtilals-india',
};

/// Resolved listing scope for a §4.3 path: the serif H1, breadcrumb trail,
/// sub-category chips (§4.2 groups) and the product tokens that narrow the
/// grid (§7.3 "filtered grid").
class RouteScope {
  final String path;
  final String title;
  final List<RouteCrumb> crumbs;
  final List<NavFacet> subChips;
  final bool isShop;
  final String description;

  const RouteScope({
    required this.path,
    required this.title,
    required this.crumbs,
    required this.subChips,
    required this.isShop,
    required this.description,
  });
}

/// True when [path] should render the shared listing (§7) rather than the
/// landing or 404 bodies: known section paths that are not content pages,
/// plus deeper jewellery paths that never made it into the nav registry.
bool isShopSection(String path) {
  if (contentSectionPaths.contains(path)) return false;
  if (StoreNav.sectionTitles.containsKey(path)) return true;
  return path.split('/').where((s) => s.isNotEmpty).length > 1;
}

/// Resolves the §7.1 header block and scope tokens for a catch-all route.
RouteScope resolveRouteScope(String path) {
  final segments = path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  final crumbs = <RouteCrumb>[const RouteCrumb('Home', '/app')];
  final buffer = <String>[];
  for (final segment in segments) {
    buffer.add(segment);
    final prefix = '/${buffer.join('/')}';
    crumbs.add(
      RouteCrumb(StoreNav.sectionTitles[prefix] ?? _prettify(segment), prefix),
    );
  }

  final title = StoreNav.titleFor(path);
  return RouteScope(
    path: path,
    title: title,
    crumbs: crumbs,
    subChips: _subChipsFor(path),
    isShop: isShopSection(path),
    description:
        'Browse the full $title edit — every design is hallmarked, '
        'certified and shipped with the store promise. New pieces land '
        'every week.',
  );
}

/// Products narrowed by the path's segment keywords. A segment only filters
/// when it still matches at least one design, so facet paths with no demo
/// stock fall back to their category grid instead of an empty page (§16.3
/// Phase 5 gate).
List<Product> narrowToScope(List<Product> products, RouteScope scope) {
  final segments = scope.path
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) return products;

  final searchable = <String, String>{
    for (final product in products)
      product.id:
          ('${product.name} ${product.brand} ${product.category} '
                  '${product.sku} ${product.description} '
                  '${product.badges.join(' ')} '
                  '${product.highlights.join(' ')} '
                  '${product.specs.values.join(' ')} '
                  '${product.shades.map((shade) => shade.name).join(' ')}')
              .toLowerCase(),
  };

  var current = products;
  for (final segment in segments) {
    final keywords = segment
        .toLowerCase()
        .split(RegExp('[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (keywords.isEmpty) continue;
    final next = current
        .where(
          (product) => keywords.any(
            (keyword) => searchable[product.id]!.contains(keyword),
          ),
        )
        .toList();
    if (next.isNotEmpty) current = next;
  }
  return current;
}

/// Sub-category chips for the header (§7.1): the sibling facets of the
/// group the path belongs to, or the categories/tiles of its parent menu.
List<NavFacet> _subChipsFor(String path) {
  final menus = <NavMenu>{
    ...StoreNav.desktopOrder,
    ...StoreNav.drawerOrder,
    StoreNav.aboutUs,
  };

  for (final menu in menus) {
    if (menu.route == path) {
      if (menu.categories.isNotEmpty) {
        return [
          for (final category in menu.categories)
            NavFacet(category.label, category.route),
        ];
      }
      if (menu.tiles.isNotEmpty) {
        return [for (final tile in menu.tiles) NavFacet(tile.label, tile.route)];
      }
      if (menu.groups.isNotEmpty) return menu.groups.first.links;
    }
    for (final group in menu.groups) {
      if (group.links.any((link) => link.route == path)) return group.links;
    }
    for (final category in menu.categories) {
      if (category.route == path) {
        if (category.groups.isNotEmpty) return category.groups.first.links;
        return const [];
      }
      for (final group in category.groups) {
        if (group.links.any((link) => link.route == path)) return group.links;
      }
    }
    if (menu.tiles.any((tile) => tile.route == path)) {
      return [for (final tile in menu.tiles) NavFacet(tile.label, tile.route)];
    }
  }
  return const [];
}

String _prettify(String segment) {
  return segment
      .split(RegExp(r'[-_]+'))
      .map((word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
