import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/menu_data.dart';
import '../../core/navigation/nav_helpers.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import '../config/providers/business_config_provider.dart';
import '../catalogue/listing_view.dart';
import '../catalogue/route_scope.dart';
import '../content/content_pages.dart';
import '../product/screens/product_detail_screen.dart';
import 'bottom_bar.dart';
import 'site_footer.dart';
import 'store_shell.dart';

/// Deep-route landing screen for the catch-all routes (§4.3 / §16.2).
///
/// Known jewellery paths render a section landing page inside the shared
/// chrome; unknown root slugs first try the product lookup (rule 3: unknown
/// slug → product → else 404) and everything else gets the designed 404
/// (§10.8) with a search box.
class SectionScreen extends StatefulWidget {
  const SectionScreen({super.key, required this.path});

  /// The matched path, e.g. `/diamond-earrings/studs`.
  final String path;

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  bool get _known => StoreNav.sectionTitles.containsKey(widget.path);

  List<String> get _segments =>
      widget.path.split('/').where((s) => s.isNotEmpty).toList();

  /// Route-map rule 3: an unknown root slug resolves to a product before the
  /// 404 fallback — matches by id, then by the name's kebab-case slug.
  Product? _lookupProduct(CommerceStore store) {
    if (_known) return null;
    final segments = _segments;
    if (segments.length != 1) return null;
    final slug = segments.single;
    final byId = store.productById(slug);
    if (byId != null) return byId;
    for (final product in store.shopProducts) {
      if (_slugify(product.name) == slug) return product;
    }
    return null;
  }

  static String _slugify(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  void _onBottomSelect(BuildContext context, int index) {
    switch (index) {
      case 0:
        navGo(context, '/app');
      case 1:
        navGo(context, '/tryinstore');
      default:
        navGo(context, '/account');
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final product = _lookupProduct(store);
    if (product != null) return ProductDetailScreen(productId: product.id);

    final showBottomBar = MediaQuery.sizeOf(context).width < 768;
    final bottomBar = showBottomBar
        ? BottomBar(
            selectedIndex: -1,
            onSelect: (index) => _onBottomSelect(context, index),
            cartCount: store.cartCount,
            onCart: () => navTo(context, '/cart'),
          )
        : null;

    // Shop paths (§4.3) render the shared listing surface (§7) inside the
    // customer chrome; content pages and unknown slugs keep their landing
    // and 404 bodies below.
    final scope = resolveRouteScope(widget.path);
    if (scope.isShop) {
      return StoreShell(
        bottomBar: bottomBar,
        body: ListingView(
          key: ValueKey(widget.path),
          scope: scope,
          footer: const SiteFooter(),
        ),
      );
    }

    // Designed §10.4–§10.7 bodies (FAQ, blog, stores, bespoke, virtual,
    // legal pages …) render inside the same chrome with the site footer.
    final designed = designedPages[widget.path];
    if (designed != null) {
      return StoreShell(
        bottomBar: bottomBar,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              designed(),
              const SiteFooter(),
            ],
          ),
        ),
      );
    }

    final title = StoreNav.titleFor(widget.path);

    return StoreShell(
      bottomBar: bottomBar,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.pageInset(context),
                vertical: AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: _known
                      ? _sectionBody(context, config.name, title)
                      : _notFoundBody(context),
                ),
              ),
            ),
            const SiteFooter(),
          ],
        ),
      ),
    );
  }

  Widget _sectionBody(BuildContext context, String brand, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          brand.toUpperCase(),
          style: AppTypography.eyebrow.copyWith(fontSize: 11),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(title, style: AppTypography.display.copyWith(fontSize: 34)),
        const SizedBox(height: AppSpacing.lg),
        Container(height: 2, width: 64, color: AppPalette.copper),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'This collection is being prepared. Browse the full catalogue '
          'while the designs for this section are added.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton(
              onPressed: () => navTo(context, '/catalogue'),
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.copper,
                textStyle: AppTypography.buttonUppercase,
              ),
              child: const Text('BROWSE ALL DESIGNS'),
            ),
            TextButton(
              onPressed: () => navGo(context, '/app'),
              child: const Text('Back to home'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _quickLink(context, 'Diamond', '/diamond'),
            _quickLink(context, 'Gold', '/gold'),
            _quickLink(context, 'Collections', '/bestsellers'),
            _quickLink(context, 'Bridal', '/realbrides'),
          ],
        ),
      ],
    );
  }

  Widget _quickLink(BuildContext context, String label, String route) {
    return ActionChip(
      onPressed: () => navTo(context, route),
      label: Text(label, style: AppTypography.caption),
      backgroundColor: AppPalette.warm,
      side: const BorderSide(color: AppPalette.hairline),
      avatar: const Icon(
        Icons.diamond_outlined,
        size: 15,
        color: AppPalette.copper,
      ),
    );
  }

  Widget _notFoundBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("We couldn't find that page", style: AppTypography.display),
        const SizedBox(height: AppSpacing.md),
        Text(
          'The link ${widget.path} may be out of date. Search for what you '
          'were looking for, or start from one of our bestsellers.',
          style: AppTypography.bodyMuted,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          decoration: AppTheme.inputDecoration(
            context,
            hintText: 'Search jewellery…',
            prefixIcon: const Icon(Icons.search),
          ),
          onSubmitted: (value) {
            final search = value.trim();
            if (search.isEmpty) return;
            navTo(
              context,
              '/catalogue?search=${Uri.encodeQueryComponent(search)}',
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _quickLink(context, 'Diamond', '/diamond'),
            _quickLink(context, 'Gold', '/gold'),
            _quickLink(context, 'Bestsellers', '/bestsellers'),
          ],
        ),
      ],
    );
  }
}
