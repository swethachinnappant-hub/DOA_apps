import '../../core/navigation/menu_data.dart';
import '../../core/product.dart';

class SearchIndex {
  const SearchIndex._();

  static List<NavFacet> relatedSearches(String query, {int limit = 6}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <NavFacet>[];
    void add(String label, String route) {
      if (out.length >= limit) return;
      if (!label.toLowerCase().contains(q)) return;
      if (out.any((f) => f.route == route)) return;
      out.add(NavFacet(label, route));
    }

    for (final menu in StoreNav.desktopOrder) {
      add(menu.label, menu.route);
      for (final category in menu.categories) {
        add(category.label, category.route);
        for (final group in category.groups) {
          for (final facet in group.links) {
            add(facet.label, facet.route);
          }
        }
      }
      for (final group in menu.groups) {
        for (final facet in group.links) {
          add(facet.label, facet.route);
        }
      }
      for (final tile in menu.tiles) {
        add(tile.label, tile.route);
      }
    }
    return out;
  }

  static List<Product> products(
    String query,
    List<Product> pool, {
    int limit = 6,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final out = <Product>[];
    for (final product in pool) {
      if (out.length >= limit) break;
      if (<String>[
        product.name,
        product.brand,
        product.category,
        product.sku,
        product.description,
        ...product.specs.values,
      ]
          .any((value) => value.toLowerCase().contains(q))) {
        out.add(product);
      }
    }
    return out;
  }
}
