import 'package:flutter/material.dart';

/// Navigation data for the storefront chrome (architecture Â§4).
///
/// Labels, order and routes mirror the live jewellery storefront verified in
/// `KIRTILALS_UI_ARCHITECTURE.md` Â§0.4 / Â§4.1 / Â§4.2. Icons stand in for the
/// site's PNG pictograms until brand assets are supplied (Â§13).

class NavFacet {
  final String label;
  final String route;
  const NavFacet(this.label, this.route);
}

/// "Shop By Style" / "Shop By Gender" / "Shop By Metal" / "Shop By Occasion".
class NavGroup {
  final String title;
  final List<NavFacet> links;
  const NavGroup(this.title, this.links);
}

/// A shop category (Earrings, Rings, ...) with its facet groups.
class NavCategory {
  final String label;
  final String route;
  final List<NavGroup> groups;
  const NavCategory(this.label, this.route, [this.groups = const []]);
}

/// Flat tile entry (collections, virtual, by-price, gifts).
class NavTile {
  final String label;
  final String route;
  const NavTile(this.label, this.route);
}

/// Top-level navigation entry.
class NavMenu {
  final String label;
  final String route;
  final IconData icon;

  /// Categories (metals), grouped tiles (gifts) or flat tiles (collections).
  final List<NavCategory> categories;
  final List<NavGroup> groups;
  final List<NavTile> tiles;

  const NavMenu({
    required this.label,
    required this.route,
    required this.icon,
    this.categories = const [],
    this.groups = const [],
    this.tiles = const [],
  });

  bool get hasPanel =>
      categories.isNotEmpty || tiles.isNotEmpty || groups.isNotEmpty;
}

class StoreNav {
  const StoreNav._();

  // ---------------------------------------------------------------- metals
  static const diamond = NavMenu(
    label: 'Diamond',
    route: '/diamond',
    icon: Icons.diamond_outlined,
    categories: [
      NavCategory('Earrings', '/diamond-earrings', [
        NavGroup('Shop By Style', [
          NavFacet('Studs', '/diamond-earrings/studs'),
          NavFacet('Dangling', '/diamond-earrings/dangling'),
          NavFacet('Vallies', '/diamond-earrings/ear-lobes'),
          NavFacet('Jhumkas', '/diamond-earring/jhumkha'),
          NavFacet('Chandeliers', '/diamond-earrings/chandeliers'),
          NavFacet('Hoops', '/diamond-earrings/hoops'),
          NavFacet('Koppu', '/diamond-earrings/koppu'),
          NavFacet('Clip on earrings', '/clip-on-earrings'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-earrings/yellow-gold'),
          NavFacet('White Gold', '/diamond-earrings/white-gold'),
          NavFacet('Rose Gold', '/diamond-earrings/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/diamond-earring/daily-wear'),
          NavFacet('Casual Wear', '/diamond-earring/casual-wear'),
          NavFacet('Office Wear', '/diamond-earring/office-wear'),
          NavFacet('Party Wear', '/diamond-earring/party-wear'),
          NavFacet('Festive & Bridal Wear', '/diamond-earring/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Rings', '/diamond-ring', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/women-diamond-ring'),
          NavFacet('Men', '/men-diamond-ring'),
          NavFacet('Unisex', '/diamond-ring/unisex'),
          NavFacet('Neliring', '/diamond-rings/vanki-rings'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-ring/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-ring/rose-gold'),
          NavFacet('White Gold', '/diamond-ring/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/diamond-rings/daily-wear'),
          NavFacet('Casual Wear', '/diamond-rings/casual-wear'),
          NavFacet('Office Wear', '/diamond-rings/office-wear'),
          NavFacet('Party Wear', '/diamond-rings/party-wear'),
        ]),
      ]),
      NavCategory('Pendant', '/diamond-pendant', [
        NavGroup('Shop By Style', [
          NavFacet('Single Hook', '/diamond-pendant/single-hook'),
          NavFacet('Mangalsutra', '/diamond-pendant-mangalsutra'),
          NavFacet('Double Hook', '/diamond-pendant/double-hook'),
          NavFacet('Men', '/diamond-pendant/men'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-pendant/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-pendant/rose-gold'),
          NavFacet('White Gold', '/diamond-pendant/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/diamond-pendant/daily-wear'),
          NavFacet('Casual Wear', '/diamond-pendant/casual-wear'),
          NavFacet('Office Wear', '/diamond-pendant/office-wear'),
          NavFacet('Party Wear', '/diamond-pendant/party-wear'),
          NavFacet('Festive & Bridal Wear', '/diamond-pendant/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Necklace', '/diamond-necklace', [
        NavGroup('Shop By Style', [
          NavFacet('Necklace', '/diamond-necklace/necklace'),
          NavFacet('Choker', '/diamond-necklace/choker'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-necklace/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-necklace/rose-gold'),
          NavFacet('White Gold', '/diamond-necklace/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Party Wear', '/diamond-necklace/party-wear'),
          NavFacet('Festive & Bridal Wear', '/diamond-necklace/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Bracelets', '/diamond-bracelet', [
        NavGroup('Shop By Gender', [
          NavFacet('Men', '/diamond-bracelet/men'),
          NavFacet('Women', '/diamond-bracelet/women'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-bracelet/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-bracelet/rose-gold'),
          NavFacet('White Gold', '/diamond-bracelet/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/diamond-bracelets/daily-wear'),
          NavFacet('Office Wear', '/diamond-bracelets/office-wear'),
        ]),
      ]),
      NavCategory('Bangles', '/diamond-bangles', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/diamond-bangles/women'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-bangles/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-bangles/rose-gold'),
          NavFacet('White Gold', '/diamond-bangles/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Office Wear', '/diamond-bangles/office-wear'),
          NavFacet('Party Wear', '/diamond-bangles/party-wear'),
        ]),
      ]),
      NavCategory('Chain', '/diamond-chain', [
        NavGroup('Shop By Style', [
          NavFacet('Chain', '/diamond-chain/women'),
          NavFacet('Side Hunt (Mugappu)', '/diamond-chain/mugappu'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/diamond-chain/yellow-gold'),
          NavFacet('Rose Gold', '/diamond-chain/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Office Wear', '/diamond-chain/office-wear'),
          NavFacet('Festive & Bridal Wear', '/diamond-chain/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Nose Pin', '/nose-pin', [
        NavGroup('Shop By Style', [
          NavFacet('Nose Screw', '/nose-pin/nose-screw'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/nose-pin/yellow-gold'),
          NavFacet('Rose Gold', '/nose-pin/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/diamond-nose-pin/daily-wear'),
        ]),
      ]),
      NavCategory('Watch Jewellery', '/watch-jewellery', [
        NavGroup('Shop By Style', [
          NavFacet('Charm', '/watch-jewellery/charms'),
          NavFacet('Pin', '/watch-jewellery/pin'),
          NavFacet('Band', '/watch-jewellery/band'),
        ]),
      ]),
    ],
  );

  static const gemstone = NavMenu(
    label: 'Gemstone',
    route: '/gemstone',
    icon: Icons.auto_awesome_outlined,
    categories: [
      NavCategory('Earrings', '/gemstone/diamond-earrings', [
        NavGroup('Shop By Style', [
          NavFacet('Studs', '/gemstone/diamond-earrings/studs'),
          NavFacet('Dangling', '/gemstone/diamond-earrings/dangling'),
          NavFacet('Jhumkha', '/gemstone/diamond-earring/jhumkha'),
          NavFacet('Chandeliers', '/gemstone/diamond-earrings/chandeliers'),
          NavFacet('Ear lobes', '/gemstone/diamond-earrings/ear-lobes'),
          NavFacet('Hoops', '/gemstone/diamond-earrings/hoops'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-earrings/yellow-gold'),
          NavFacet('White Gold', '/gemstone/diamond-earrings/white-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-earrings/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/gemstone/diamond-earrings/daily-wear'),
          NavFacet('Casual Wear', '/gemstone/diamond-earrings/casual-wear'),
          NavFacet('Office Wear', '/gemstone/diamond-earrings/office-wear'),
          NavFacet('Party Wear', '/gemstone/diamond-earrings/party-wear'),
          NavFacet('Festive & Bridal Wear', '/gemstone/diamond-earrings/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Rings', '/gemstone/diamond-ring', [
        NavGroup('Shop By Gender', [
          NavFacet('Men', '/gemstone/men-diamond-ring'),
          NavFacet('Women', '/gemstone/women-diamond-ring'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-ring/yellow-gold'),
          NavFacet('White Gold', '/gemstone/diamond-ring/white-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-ring/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/gemstone/diamond-rings/daily-wear'),
          NavFacet('Office Wear', '/gemstone/diamond-rings/office-wear'),
          NavFacet('Party Wear', '/gemstone/diamond-rings/party-wear'),
        ]),
      ]),
      NavCategory('Pendant', '/gemstone/diamond-pendant', [
        NavGroup('Shop By Style', [
          NavFacet('Single Hook', '/gemstone/diamond-pendant/single-hook'),
          NavFacet('Mangalsutra', '/gemstone/diamond-pendant-mangalsutra'),
          NavFacet('Double Hook', '/gemstone/diamond-pendant/double-hook'),
        ]),
        NavGroup('Shop By Gender', [
          NavFacet('Men', '/gemstone/diamond-pendant/men'),
          NavFacet('Women', '/gemstone/diamond-pendant-mangalsutra'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-pendant/yellow-gold'),
          NavFacet('White Gold', '/gemstone/diamond-pendant/white-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-pendant/rose-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/gemstone/diamond-pendant/daily-wear'),
          NavFacet('Casual Wear', '/gemstone/diamond-pendant/casual-wear'),
          NavFacet('Office Wear', '/gemstone/diamond-pendant/office-wear'),
          NavFacet('Party Wear', '/gemstone/diamond-pendant/party-wear'),
          NavFacet('Festive & Bridal Wear', '/gemstone/diamond-pendant/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Necklace', '/gemstone/diamond-necklace', [
        NavGroup('Shop By Style', [
          NavFacet('Semi Long', '/gemstone/diamond-chain/mugappu'),
          NavFacet('Choker', '/gemstone/diamond-necklace/choker'),
          NavFacet('Haram', '/gemstone/diamond-necklace/haram'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-necklace/yellow-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-necklace/rose-gold'),
          NavFacet('White Gold', '/gemstone/diamond-necklace/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Party Wear', '/gemstone/diamond-necklace/party-wear'),
          NavFacet('Festive & Bridal Wear', '/gemstone/diamond-necklace/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Bracelets', '/gemstone/diamond-bracelet', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/gemstone/diamond-bracelet/women'),
          NavFacet('Men', '/gemstone/diamond-bracelet/men'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-bracelet/yellow-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-bracelet/rose-gold'),
          NavFacet('White Gold', '/gemstone/diamond-bracelet/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Office Wear', '/gemstone/diamond-bracelets/office-wear'),
          NavFacet('Party Wear', '/gemstone/diamond-bracelets/party-wear'),
        ]),
      ]),
      NavCategory('Bangles', '/gemstone/diamond-bangles', [
        NavGroup('Shop By Metal', [
          NavFacet('Yellow Gold', '/gemstone/diamond-bangles/yellow-gold'),
          NavFacet('Rose Gold', '/gemstone/diamond-bangles/rose-gold'),
          NavFacet('White Gold', '/gemstone/diamond-bangles/white-gold'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Office Wear', '/gemstone/diamond-bangles/office-wear'),
          NavFacet('Party Wear', '/gemstone/diamond-bangles/party-wear'),
        ]),
      ]),
      NavCategory('Chains', '/gemstone/diamond-chain', [
        NavGroup('Shop By Metal', [
          NavFacet('Rose Gold', '/gemstone/diamond-chain/rose-gold'),
        ]),
      ]),
    ],
  );

  static const gold = NavMenu(
    label: 'Gold',
    route: '/gold',
    icon: Icons.monetization_on_outlined,
    categories: [
      NavCategory('Gold Promotions', '/goldjewellerypromotion'),
      NavCategory('Earrings', '/gold-earrings', [
        NavGroup('Shop By Style', [
          NavFacet('Chandeliers', '/gold-earrings/chandeliers'),
          NavFacet('Studs', '/gold-earrings/studs'),
          NavFacet('Danglers', '/gold-earrings/dangling'),
          NavFacet('Vallies', '/gold-earrings/ear-lobes'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/gold-earrings/daily-wear'),
          NavFacet('Festive & Bridal Wear', '/gold-earrings/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Rings', '/gold-ring', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/gold-ring/women'),
          NavFacet('Men', '/gold-ring/men'),
          NavFacet('Children', '/gold-ring/children'),
        ]),
        NavGroup('Shop By Occasion', [
          NavFacet('Daily Wear', '/gold-rings/daily-wear'),
          NavFacet('Festive & Bridal Wear', '/gold-rings/festive-bridal-wear'),
        ]),
      ]),
      NavCategory('Bangles', '/gold-bangle', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/gold-bangle/women'),
        ]),
      ]),
      NavCategory('Chain', '/gold-chain', [
        NavGroup('Shop By Gender', [
          NavFacet('Men', '/gold-chain/men'),
          NavFacet('Women', '/gold-chain/women'),
          NavFacet('Unisex', '/gold-chain/unisex'),
        ]),
      ]),
      NavCategory('Bracelets', '/gold-bracelet', [
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/gold-bracelet/women'),
          NavFacet('Men', '/gold-bracelet/men'),
          NavFacet('Children', '/gold-bracelet/children'),
        ]),
      ]),
      NavCategory('Necklace', '/gold-necklace', [
        NavGroup('Shop By Style', [
          NavFacet('Necklace', '/gold-necklace/necklace'),
          NavFacet('Haram', '/gold-necklace/haram'),
        ]),
      ]),
      NavCategory('Pendant', '/gold-pendant', [
        NavGroup('Shop By Style', [
          NavFacet('Single Hook', '/gold-pendant/single-hook'),
          NavFacet('Double Hook', '/gold-pendant/double-hook'),
        ]),
      ]),
      NavCategory('Accessories', '/gold-accessories', [
        NavGroup('Shop By Style', [
          NavFacet('Gold Coin', '/gold-coin'),
        ]),
      ]),
    ],
  );

  static const platinum = NavMenu(
    label: 'Platinum',
    route: '/platinum',
    icon: Icons.workspace_premium_outlined,
    categories: [
      NavCategory('Earrings', '/platinum-earrings', [
        NavGroup('Shop By Style', [
          NavFacet('Danglers', '/platinum-earrings/dangling'),
          NavFacet('Vallies', '/platinum-earrings/ear-lobes'),
          NavFacet('Studs', '/platinum-earrings/studs'),
        ]),
      ]),
      NavCategory('Rings', '/platinum-ring', [
        NavGroup('Shop By Style', [
          NavFacet('Men', '/platinum-ring/men'),
          NavFacet('Women', '/platinum-ring/women'),
          NavFacet('Unisex', '/platinum-ring/unisex'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Platinum', '/platinum-ring/platinum'),
          NavFacet('Two Tone', '/platinum-ring/two-tone'),
        ]),
      ]),
      NavCategory('Pendant', '/platinum-pendant', [
        NavGroup('Shop By Style', [
          NavFacet('Single Hook', '/platinum-pendant/single-hook'),
        ]),
      ]),
      NavCategory('Bracelets', '/platinum-bracelet', [
        NavGroup('Shop By Style', [
          NavFacet('Kada', '/platinum-bracelet/men'),
        ]),
        NavGroup('Shop By Gender', [
          NavFacet('Women', '/platinum-bracelet/women'),
          NavFacet('Men', '/platinum-bracelet/men'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Platinum', '/platinum-bracelet/platinum'),
          NavFacet('Two Tone', '/platinum-bracelet/two-tone'),
        ]),
      ]),
      NavCategory('Chain', '/platinum-chain', [
        NavGroup('Shop By Gender', [
          NavFacet('Men', '/platinum-chain/men'),
          NavFacet('Women', '/platinum-chain/women'),
        ]),
        NavGroup('Shop By Metal', [
          NavFacet('Two Tone', '/platinum-chain/two-tone'),
        ]),
      ]),
    ],
  );

  // -------------------------------------------------------- non-metal menus
  static const bridal = NavMenu(
    label: 'Bridal',
    route: '/realbrides',
    icon: Icons.favorite_border,
  );

  static const virtual = NavMenu(
    label: 'Virtual',
    route: '/virtual-tryon',
    icon: Icons.videocam_outlined,
    tiles: [
      NavTile('Virtual Try-on', '/virtual-tryon'),
      NavTile('Virtual Store', '/virtualstoreproduct'),
      NavTile('Decide With Friends', '/co-shopping-products'),
    ],
  );

  static const collections = NavMenu(
    label: 'Collections',
    route: '/bestsellers',
    icon: Icons.grid_view,
    tiles: [
      NavTile('Voyage of Hearts', '/voyage-of-hearts'),
      NavTile('Hope', '/hope'),
      NavTile('Glow & Go', '/glow-and-go'),
      NavTile('Tribal', '/tribal'),
      NavTile('Bandhan', '/realbrides'),
      NavTile('Ikat', '/ikat'),
      NavTile('Honeycomb', '/honeycomb'),
      NavTile('Bestsellers', '/bestsellers'),
      NavTile('Style Switch', '/style-switch'),
      NavTile('Promise', '/mens-platinum-collection'),
      NavTile('Couple Band', '/coupleband'),
      NavTile('Muse', '/the-muse'),
      NavTile('Illume', '/illume'),
      NavTile('Valentine', '/valentine'),
      NavTile('Divyadarsanam', '/divyadarsanam'),
      NavTile('Alchemist', '/alchemist'),
      NavTile('Paridhi', '/paridhi'),
      NavTile('Gemstone', '/gemstone'),
      NavTile('Divine', '/divine'),
      NavTile('Navarathiri', '/navarathiri'),
    ],
  );

  static const gifts = NavMenu(
    label: 'Gifts',
    route: '/gift-by-occasion',
    icon: Icons.card_giftcard,
    groups: [
      NavGroup('Gift By Occasion', [
        NavFacet('Wedding', '/wedding'),
        NavFacet('Birthday', '/birthday'),
        NavFacet('Anniversary', '/anniversary'),
      ]),
      NavGroup('Gift For Special', [
        NavFacet('Gift for her', '/gift-for-her'),
        NavFacet('Gift for him', '/gift-for-him'),
      ]),
      NavGroup('More Gifts', [
        NavFacet('Gift Card', '/giftcardsforms'),
        NavFacet('Gold Coin', '/gold-coin'),
      ]),
    ],
  );

  static const solitaire = NavMenu(
    label: 'Solitaire',
    route: '/solitaire-collections',
    icon: Icons.diamond,
  );

  static const byPrice = NavMenu(
    label: 'By Price',
    route: '/20k-products',
    icon: Icons.sell_outlined,
    tiles: [
      NavTile('Under 20K', '/20k-products'),
      NavTile('Under 30K', '/30k-products'),
      NavTile('Under 50K', '/50k-products'),
      NavTile('Above 50K', '/above-50k'),
    ],
  );

  static const aboutUs = NavMenu(
    label: 'About Us',
    route: '/world-of-kirtilals',
    icon: Icons.info_outline,
  );

  // ------------------------------------------------------------- orderings
  /// Desktop top-nav order (Â§4.1, live verified).
  static const List<NavMenu> desktopOrder = [
    diamond,
    gemstone,
    gold,
    platinum,
    bridal,
    virtual,
    collections,
    gifts,
    solitaire,
    byPrice,
  ];

  /// Mobile drawer order (Â§4.1, live verified).
  static const List<NavMenu> drawerOrder = [
    diamond,
    gold,
    platinum,
    gemstone,
    collections,
    gifts,
    bridal,
    virtual,
    solitaire,
    byPrice,
    aboutUs,
  ];

  // ------------------------------------------------------- section registry
  static Map<String, String> get _sectionTitles {
    final titles = <String, String>{};
    void add(String route, String label) => titles.putIfAbsent(route, () => label);

    for (final menu in [...desktopOrder, aboutUs]) {
      add(menu.route, menu.label);
      for (final tile in menu.tiles) {
        add(tile.route, tile.label);
      }
      for (final group in menu.groups) {
        for (final link in group.links) {
          add(link.route, link.label);
        }
      }
      for (final category in menu.categories) {
        add(category.route, category.label);
        for (final group in category.groups) {
          for (final link in group.links) {
            add(link.route, link.label);
          }
        }
      }
    }

    // Content and service routes exposed in the footer (Â§5.8).
    add('/tryinstore', 'Our Store');
    add('/bespoke', 'Bespoke');
    add('/faq', 'F.A.Q.');
    add('/feedback', 'Give Feedback');
    add('/contactusform', 'Contact Us');
    add('/privacy-policy', 'Privacy Policy');
    add('/shipping-and-return-policy', 'Shipping & Returns');
    add('/investors', 'Investors');
    add('/terms-and-conditions', 'Terms of Service');
    add('/clp-terms', 'CLP Terms & Conditions');
    add('/world-of-kirtilals', 'About Us');
    add('/navaratna', 'Navaratna Jewellery');
    add('/wishlist', 'My Wishlist');
    add('/shopping-cart', 'Shopping Cart');
    add('/account', 'My Account');
    add('/gift-for-special', 'Gifts For Someone Special');
    add('/solitaire-collection-rings', 'Solitaire Rings');
    add('/solitaire-collection-pendants', 'Solitaire Pendants');
    add('/solitaire-product-list', 'Solitaire Collection');
    add('/blog/country/kirtilals-india', 'Blog');

    // Legacy aliases kept resolving (Â§4.3): removed from the live menu but
    // still linked from old campaigns and bookmarks.
    add('/hair-deco', 'Hair Deco');
    add('/hair-deco/maang-tikka', 'Maang Tikka');
    return titles;
  }

  /// Known section route â†’ display title (used by the catch-all route).
  static final Map<String, String> sectionTitles = _sectionTitles;

  /// Title for a matched deep path, or a prettified fallback.
  static String titleFor(String path) {
    final known = sectionTitles[path];
    if (known != null) return known;
    final segment = path.split('/').where((s) => s.isNotEmpty).lastOrNull;
    if (segment == null) return 'Page';
    final words = segment.split(RegExp(r'[-_]+'));
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Category pictogram stand-in (Â§2.4) â€” replaced by brand PNGs later.
  static IconData categoryIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('earring')) return Icons.hearing_outlined;
    if (l.contains('ring')) return Icons.radio_button_unchecked;
    if (l.contains('pendant')) return Icons.diamond_outlined;
    if (l.contains('necklace')) return Icons.auto_awesome_outlined;
    if (l.contains('bangle') || l.contains('bracelet')) return Icons.watch;
    if (l.contains('chain')) return Icons.link;
    if (l.contains('nose')) return Icons.push_pin_outlined;
    if (l.contains('watch')) return Icons.watch;
    if (l.contains('coin') || l.contains('accessor')) {
      return Icons.monetization_on_outlined;
    }
    if (l.contains('promotion')) return Icons.local_offer_outlined;
    return Icons.category_outlined;
  }

  /// Help line and social targets verified live (Â§5.1 / Â§5.8).
  static const String helpLine = '18001200411';
  static const String whatsappSupport = '+919894840711';
  static const String whatsappBot = '+919655200411';
  static const String supportEmail = 'Enquiry@online-kirtilals.com';
}
