import 'package:flutter/widgets.dart';

import '../catalog_repository.dart';
import '../models/cart.dart';
import '../models/cart_totals.dart';
import '../models/cms.dart';
import '../models/coupon.dart';
import '../models/notification.dart';
import '../models/order.dart';
import '../navigation/menu_data.dart';
import '../product.dart';
import '../services/realtime_service.dart';

/// Single source of truth for everything the buyer and seller surfaces read.
///
/// Both roles see the same records, which is the whole point: a seller's stock
/// edit and a buyer's catalogue view must never disagree. Every mutation
/// publishes to [RealtimeService] so the other role updates with no refresh.
class CommerceStore extends ChangeNotifier {
  CommerceStore({RealtimeService? realtime, CatalogRepository? repository})
      : _realtime = realtime ?? RealtimeService.instance,
        _repository = repository,
        _navHeaderKeys = [
          for (final menu in StoreNav.desktopOrder) menu.route,
        ],
        _navDrawerKeys = [
          for (final menu in StoreNav.drawerOrder) menu.route,
        ],
        _coupons = List.of(defaultCoupons),
        _collections = [
          for (var i = 0; i < StoreNav.collections.tiles.length; i++)
            ShopCollection(
              id: StoreNav.collections.tiles[i].route
                  .replaceAll(RegExp(r'^/+|/+$'), ''),
              name: StoreNav.collections.tiles[i].label,
              route: StoreNav.collections.tiles[i].route,
            ),
        ],
        _customers = List.of(_defaultCustomers);

  final RealtimeService _realtime;

  /// Saves CMS edits when set (SPEC-18); null keeps everything in memory.
  final CatalogRepository? _repository;

  final List<Product> _products = [];
  final List<Order> _orders = [];
  final List<CartItem> _cart = [];
  final List<AppNotification> _notifications = [];
  final Set<String> _wishlist = {};

  int _sequence = 0;

  // ------------------------------------------------------------------ reads

  List<Product> get allProducts => List.unmodifiable(_products);

  List<Order> get allOrders => List.unmodifiable(_orders);

  List<CartItem> get cart => List.unmodifiable(_cart);

  List<AppNotification> get allNotifications =>
      List.unmodifiable(_notifications);

  /// Everything a shopper can see: available products only, with owner
  /// listings promoted ahead of seeded stock so a seller's upload is actually
  /// discoverable.
  List<Product> get shopProducts {
    final available = _products.where((p) => p.isAvailable).toList();
    available.sort((a, b) {
      final aOwned = a.ownerId.isEmpty ? 1 : 0;
      final bOwned = b.ownerId.isEmpty ? 1 : 0;
      if (aOwned != bOwned) return aOwned.compareTo(bOwned);
      return (b.createdAt ?? DateTime(2000))
          .compareTo(a.createdAt ?? DateTime(2000));
    });
    return available;
  }

  List<Product> productsForOwner(String ownerId) =>
      _products.where((p) => p.ownerId == ownerId).toList();

  List<Order> ordersForCustomer(String customerId) =>
      _sortedNewestFirst(_orders.where((o) => o.customerId == customerId));

  List<Order> ordersForOwner(String ownerId) =>
      _sortedNewestFirst(_orders.where((o) => o.ownerId == ownerId));

  /// Orders that still need a seller's attention, for the dashboard tiles.
  List<Order> get openOrders =>
      _orders.where((o) => o.status.isActive).toList();

  /// Notifications addressed to [audienceId], plus the broadcast ones.
  List<AppNotification> notificationsFor(String audienceId) {
    final mine = _notifications
        .where((n) => n.audienceId == audienceId || n.audienceId == '*');
    return _sortedNotifications(mine);
  }

  int unreadCount(String audienceId) =>
      notificationsFor(audienceId).where((n) => !n.read).length;

  Product? productById(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  Order? orderById(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Resolves the live product behind a cart line, which may have been deleted
  /// or repriced since the line was added.
  Product? productFor(CartItem item) => productById(item.productId);

  // ---------------------------------------------------------- recent views

  static const int _maxRecentlyViewed = 10;

  final List<String> _recentlyViewedIds = [];

  /// Detail pages in the order they were last opened, newest first, for the
  /// "Recently viewed" rail.
  List<Product> get recentlyViewed {
    final out = <Product>[];
    for (final id in _recentlyViewedIds) {
      final product = productById(id);
      if (product != null) out.add(product);
    }
    return out;
  }

  /// Records a detail-page view. Notify after the current frame because this
  /// is called from a detail screen's `initState`; the home rail then updates
  /// when the buyer returns to the storefront.
  void recordView(String productId) {
    final wasFirst =
        _recentlyViewedIds.isNotEmpty && _recentlyViewedIds.first == productId;
    _recentlyViewedIds.remove(productId);
    _recentlyViewedIds.insert(0, productId);
    if (_recentlyViewedIds.length > _maxRecentlyViewed) {
      _recentlyViewedIds.removeRange(
        _maxRecentlyViewed,
        _recentlyViewedIds.length,
      );
    }
    if (!wasFirst) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyListeners());
    }
  }

  List<CartItem> get cartProducts => _cart
      .where((item) => productFor(item) != null)
      .toList(growable: false);

  int get cartSubtotal => _cart.fold<int>(0, (sum, l) => sum + l.lineTotal);

  int get cartCount => _cart.fold<int>(0, (sum, l) => sum + l.quantity);

  bool get isCartEmpty => _cart.isEmpty;

  // --------------------------------------------------------------- coupons

  /// The coupons a fresh store starts with (SPEC-18); the live list is
  /// [coupons], which the owner console edits.
  static const List<Coupon> defaultCoupons = [
    Coupon(
      code: 'HOPE500',
      flatOffInr: 500,
      minSubtotal: 95900,
      description: 'Flat ₹500 off on orders above ₹95,900',
    ),
    Coupon(
      code: 'DIAMOND200',
      flatOffInr: 200,
      minSubtotal: 49900,
      description: 'Flat ₹200 off on orders above ₹49,900',
    ),
    Coupon(
      code: 'GIFT1000',
      flatOffInr: 1000,
      minSubtotal: 149900,
      description: 'Flat ₹1,000 off on orders above ₹1,49,900',
    ),
  ];

  final List<Coupon> _coupons;

  Coupon? _appliedCoupon;

  List<Coupon> get coupons => List.unmodifiable(_coupons);

  Coupon? get appliedCoupon => _appliedCoupon;

  Coupon? couponByCode(String code) {
    for (final c in _coupons) {
      if (c.code.toUpperCase() == code.trim().toUpperCase()) return c;
    }
    return null;
  }

  bool isCouponEligible(Coupon coupon) =>
      coupon.isLive &&
      !coupon.isExhausted &&
      !isCartEmpty &&
      coupon.isSatisfiedBy(cartSubtotal);

  /// Adds a coupon or replaces the one with the same code (case-insensitive).
  void upsertCoupon(Coupon coupon) {
    final index =
        _coupons.indexWhere((c) => c.code.toUpperCase() == coupon.code.toUpperCase());
    if (index == -1) {
      _coupons.insert(0, coupon);
    } else {
      _coupons[index] = coupon;
    }
    _revalidateCoupon();
    notifyListeners();
    _persist();
  }

  void removeCouponCode(String code) {
    final index =
        _coupons.indexWhere((c) => c.code.toUpperCase() == code.trim().toUpperCase());
    if (index == -1) return;
    _coupons.removeAt(index);
    if (_appliedCoupon?.code.toUpperCase() == code.trim().toUpperCase()) {
      _appliedCoupon = null;
    }
    notifyListeners();
    _persist();
  }

  int get couponDiscount {
    final coupon = _appliedCoupon;
    if (coupon == null) return 0;
    return coupon.isSatisfiedBy(cartSubtotal) ? coupon.flatOffInr : 0;
  }

  CartTotals get cartTotals =>
      CartTotals.compute(subtotal: cartSubtotal, coupon: _appliedCoupon);

  bool applyCoupon(String code) {
    final coupon = couponByCode(code);
    if (coupon == null || !isCouponEligible(coupon)) return false;
    _appliedCoupon = coupon;
    notifyListeners();
    return true;
  }

  void removeCoupon() {
    if (_appliedCoupon == null) return;
    _appliedCoupon = null;
    notifyListeners();
  }

  void _revalidateCoupon() {
    final coupon = _appliedCoupon;
    if (coupon == null) return;
    if (!coupon.isLive || isCartEmpty || !coupon.isSatisfiedBy(cartSubtotal)) {
      _appliedCoupon = null;
    }
  }

  // ---------------------------------------------------------------- search

  List<Product> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return shopProducts
        .where(
          (p) => <String>[
            p.name,
            p.brand,
            p.sku,
            p.category,
            p.description,
            ...p.specs.values,
          ].any((value) => value.toLowerCase().contains(q)),
        )
        .toList();
  }

  // ------------------------------------------------------------- wishlist

  /// Ids the shopper has saved, in the order they were saved.
  List<String> get wishlistIds => List.unmodifiable(_wishlist);

  int get wishlistCount => _wishlist.length;

  bool isWishlisted(String productId) => _wishlist.contains(productId);

  /// Saved products resolved against the live catalogue, so a listing the
  /// seller deletes simply drops off the wishlist.
  List<Product> get wishlistProducts =>
      _products.where((p) => _wishlist.contains(p.id)).toList();

  /// Adds or removes the product from the wishlist and returns the new saved
  /// state, letting callers say "Saved" or "Removed" without re-reading.
  bool toggleWishlist(String productId) {
    if (!_products.any((p) => p.id == productId)) return false;
    final nowSaved = !_wishlist.contains(productId);
    if (nowSaved) {
      _wishlist.add(productId);
    } else {
      _wishlist.remove(productId);
    }
    notifyListeners();
    return nowSaved;
  }

  // --------------------------------------------------------------- seeding

  /// Replaces the platform catalogue. Called on first run and whenever the
  /// business configuration changes its category list. Owner-created listings
  /// are preserved, since they are not part of the seed.
  void seedProducts(List<Product> products) {
    final incomingIds = products.map((p) => p.id).toSet();
    final seen = <String>{};

    for (final seed in products) {
      seen.add(seed.id);
      final index = _products.indexWhere((p) => p.id == seed.id);
      if (index == -1) {
        _products.add(seed);
      } else if (_products[index].ownerId.isEmpty) {
        // Keep a seller's edits; only refresh true platform stock.
        _products[index] = seed;
      }
    }

    // Drop seed products the new configuration no longer defines, but never
    // touch a seller's own listings.
    _products.removeWhere(
      (p) => p.ownerId.isEmpty && !incomingIds.contains(p.id) && !seen.contains(p.id),
    );

    notifyListeners();
  }

  // -------------------------------------------------------------- products

  /// Publishes a new listing and tells shoppers something arrived.
  Product publishProduct(Product product) {
    _products.insert(0, product);
    _realtime.publish(AppEvent(
      type: AppEventType.productPublished,
      productId: product.id,
      product: product,
      message: product.name,
    ));
    pushNotification(AppNotification(
      id: _nextId('ntf'),
      type: NotificationType.newArrival,
      title: 'Just dropped',
      body: '${product.name} is now available',
      audienceId: '*',
      route: '/product/${product.id}',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    return product;
  }

  void updateProduct(Product product) {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index == -1) return;
    _products[index] = product;
    _realtime.publish(AppEvent(
      type: AppEventType.productUpdated,
      productId: product.id,
      product: product,
      message: product.name,
    ));
    notifyListeners();
  }

  /// Removes a listing and drops it from any cart that referenced it.
  void deleteProduct(String productId) {
    final product = productById(productId);
    _products.removeWhere((p) => p.id == productId);
    _cart.removeWhere((item) => item.productId == productId);
    _realtime.publish(AppEvent(
      type: AppEventType.productDeleted,
      productId: productId,
      product: product,
    ));
    notifyListeners();
  }

  /// Adjusts stock and tells shoppers when something just sold out.
  void setStock(String productId, int stock) {
    final product = productById(productId);
    if (product == null) return;

    final wasAvailable = product.isAvailable;
    _applyStock(productId, stock);

    if (wasAvailable && stock <= 0) {
      pushNotification(AppNotification(
        id: _nextId('ntf'),
        type: NotificationType.outOfStock,
        title: 'Sold out',
        body: '${product.name} just went out of stock',
        audienceId: '*',
        route: '/product/${product.id}',
        createdAt: DateTime.now(),
      ));
    }

    _realtime.publish(AppEvent(
      type: AppEventType.stockChanged,
      productId: productId,
      product: productById(productId),
      message: '$stock left',
    ));
    notifyListeners();
  }

  // ------------------------------------------------------------------ cart

  /// Adds a line, merging quantities when the same product and variant is
  /// already in the cart. Returns the resulting quantity in the cart.
  int addToCart(
    Product product, {
    int? quantity,
    String? selectedSize,
    String? selectedShade,
  }) {
    final requested = quantity ?? product.minimumOrderQuantity;
    if (requested < product.minimumOrderQuantity) return 0;
    final alreadyInCart = _cart
        .where((line) => line.productId == product.id)
        .fold<int>(0, (total, line) => total + line.quantity);
    if (product.ownerId.isNotEmpty &&
        alreadyInCart + requested > product.stock) {
      return 0;
    }

    final item = CartItem.fromProduct(
      product,
      quantity: requested,
      selectedSize: selectedSize,
      selectedShade: selectedShade,
    );

    final index = _cart.indexWhere((l) => l.lineKey == item.lineKey);
    if (index == -1) {
      _cart.add(item);
    } else {
      _cart[index] = _cart[index].copyWith(
        quantity: _cart[index].quantity + requested,
        unitPrice: product.unitPriceForQuantity(
          _cart[index].quantity + requested,
        ),
      );
    }
    _revalidateCoupon();
    notifyListeners();
    return _cart.firstWhere((l) => l.lineKey == item.lineKey).quantity;
  }

  /// Sets an exact quantity. Removing the last unit drops the line.
  void setCartQuantity(String lineKey, int quantity) {
    final index = _cart.indexWhere((l) => l.lineKey == lineKey);
    if (index == -1) return;

    if (quantity <= 0) {
      _cart.removeAt(index);
    } else {
      final product = productById(_cart[index].productId);
      final minimum = product?.minimumOrderQuantity ?? 1;
      final remainingStock = product != null && product.ownerId.isNotEmpty
          ? product.stock - _cart
              .where((line) => line.productId == product.id && line.lineKey != lineKey)
              .fold<int>(0, (total, line) => total + line.quantity)
          : null;
      if (remainingStock != null && remainingStock < minimum) {
        _cart.removeAt(index);
        _revalidateCoupon();
        notifyListeners();
        return;
      }
      final adjusted = remainingStock == null
          ? (quantity < minimum ? minimum : quantity)
          : quantity.clamp(minimum, remainingStock).toInt();
      _cart[index] = _cart[index].copyWith(
        quantity: adjusted,
        unitPrice: product?.unitPriceForQuantity(adjusted),
      );
    }
    _revalidateCoupon();
    notifyListeners();
  }

  void incrementCart(String lineKey) {
    final index = _cart.indexWhere((l) => l.lineKey == lineKey);
    if (index == -1) return;
    setCartQuantity(lineKey, _cart[index].quantity + 1);
  }

  void decrementCart(String lineKey) {
    final index = _cart.indexWhere((l) => l.lineKey == lineKey);
    if (index == -1) return;
    setCartQuantity(lineKey, _cart[index].quantity - 1);
  }

  void removeFromCart(String lineKey) {
    _cart.removeWhere((l) => l.lineKey == lineKey);
    _revalidateCoupon();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _appliedCoupon = null;
    notifyListeners();
  }

  // --------------------------------------------------------------- orders

  /// Turns the cart into orders, decrements stock, and notifies both sides.
  ///
  /// A cart can hold items from several shops, so it is grouped by seller and
  /// each seller receives their own order, which is how marketplaces actually
  /// split fulfilment. Returns null when there is nothing to place.
  Order? placeOrder({
    required String customerId,
    required String customerName,
    required String deliveryAddress,
    String paymentMethod = 'UPI',
  }) {
    if (_cart.isEmpty) return null;

    // Captured before the cart clears: the order records what was redeemed
    // and the coupon's usage count ticks up (SPEC-18).
    final redeemed = _appliedCoupon;
    final redeemedDiscount = redeemed == null ? 0 : couponDiscount;

    final byOwner = <String, List<CartItem>>{};
    for (final item in _cart) {
      byOwner.putIfAbsent(productFor(item)?.ownerId ?? '', () => []).add(item);
    }

    final created = <Order>[];
    for (final entry in byOwner.entries) {
      final items = entry.value;
      final seller = items.map(productFor).whereType<Product>().firstOrNull;
      final order = Order(
        id: _nextId('ORD'),
        customerId: customerId,
        customerName: customerName,
        ownerId: entry.key,
        ownerName: seller?.brand ?? 'Platform Store',
        items: items.map((i) => i.toOrderItem()).toList(),
        placedAt: DateTime.now(),
        paymentMethod: paymentMethod,
        deliveryAddress: deliveryAddress,
        // A split cart creates one order per seller; the redemption is
        // recorded once, on the first of them.
        couponCode: created.isEmpty ? redeemed?.code : null,
        couponDiscount: created.isEmpty ? redeemedDiscount : 0,
      );

      _orders.add(order);
      created.add(order);

      for (final item in items) {
        final product = productFor(item);
        // Platform seed stock is not tracked, only a seller's own inventory.
        if (product == null || product.ownerId.isEmpty) continue;
        _applyStock(
          product.id,
          (product.stock - item.quantity).clamp(0, 1 << 31),
        );
      }

      _realtime.publish(AppEvent(
        type: AppEventType.orderPlaced,
        orderId: order.id,
        audienceId: customerId,
        order: order,
        status: order.status,
        message: order.id,
      ));

      pushNotification(AppNotification(
        id: _nextId('ntf'),
        type: NotificationType.orderPlaced,
        title: 'Order placed',
        body: '${order.id} · ${order.itemCount} item(s) from ${order.ownerName}',
        audienceId: customerId,
        route: '/order/${order.id}',
        createdAt: DateTime.now(),
      ));

      if (order.ownerId.isNotEmpty) {
        pushNotification(AppNotification(
          id: _nextId('ntf'),
          type: NotificationType.orderPlaced,
          title: 'New order',
          body: '${order.id} from ${order.customerName}',
          audienceId: order.ownerId,
          route: '/owner/orders',
          createdAt: DateTime.now(),
        ));
      }
    }

    _cart.clear();
    if (redeemed != null) {
      final index =
          _coupons.indexWhere((c) => c.code.toUpperCase() == redeemed.code.toUpperCase());
      if (index != -1) {
        _coupons[index] = _coupons[index]
            .copyWith(usedCount: _coupons[index].usedCount + 1);
      }
      _appliedCoupon = null;
      _persist();
    }
    notifyListeners();
    return created.first;
  }

  /// Moves an order to [target], rejecting illegal jumps.
  ///
  /// Returns true when the order actually moved.
  bool advanceOrderStatus(String orderId, OrderStatus target) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index == -1) return false;

    final current = _orders[index];
    if (!current.status.canTransitionTo(target)) return false;

    final updated = current.copyWith(status: target);
    _orders[index] = updated;

    _realtime.publish(AppEvent(
      type: AppEventType.orderStatusChanged,
      orderId: orderId,
      audienceId: current.customerId,
      order: updated,
      status: target,
      previousStatus: current.status.name,
      message: target.label,
    ));

    pushNotification(AppNotification(
      id: _nextId('ntf'),
      type: NotificationType.orderStatus,
      title: target.label,
      body: '$orderId · ${target.hint}',
      audienceId: current.customerId,
      route: '/order/$orderId',
      createdAt: DateTime.now(),
    ));

    notifyListeners();
    return true;
  }

  /// Convenience for the seller's primary button: one step along the flow.
  bool advanceOrder(String orderId) {
    final order = orderById(orderId);
    if (order == null) return false;
    final next = order.status.next;
    if (next == null) return false;
    return advanceOrderStatus(orderId, next);
  }

  // -------------------------------------------------------- notifications

  void pushNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _realtime.notify(notification);
    // Cap history so a long session cannot grow without bound.
    if (_notifications.length > 200) {
      _notifications.removeRange(200, _notifications.length);
    }
    notifyListeners();
  }

  void markNotificationRead(String id, {bool read = true}) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(read: read);
    notifyListeners();
  }

  void markAllRead(String audienceId) {
    var changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      final n = _notifications[i];
      final inAudience = n.audienceId == audienceId || n.audienceId == '*';
      if (inAudience && !n.read) {
        _notifications[i] = n.copyWith(read: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void clearNotifications(String audienceId) {
    _notifications.removeWhere(
      (n) => n.audienceId == audienceId || n.audienceId == '*',
    );
    notifyListeners();
  }

  // --------------------------------------------------- CMS state (SPEC-18)
  //
  // Everything below is the owner console's editable storefront config.
  // Reads resolve over the static §4 defaults so an untouched store renders
  // exactly the verified live site; every mutation notifies listeners (the
  // customer side reflects with no restart) and persists via the repository.

  // --- navigation tree

  final List<String> _navHeaderKeys;
  final List<String> _navDrawerKeys;
  final Map<String, NavMenuState> _navPatches = {};

  static final Map<String, NavMenu> _navByRoute = {
    for (final menu in [...StoreNav.desktopOrder, ...StoreNav.drawerOrder])
      menu.route: menu,
  };

  List<String> get navHeaderKeys => List.unmodifiable(_navHeaderKeys);

  List<String> get navDrawerKeys => List.unmodifiable(_navDrawerKeys);

  NavMenuState navPatchFor(String route) =>
      _navPatches[route] ?? const NavMenuState();

  /// The desktop top-nav with the owner's label/icon/visibility edits applied.
  List<NavMenu> get headerMenus => _resolveNav(_navHeaderKeys);

  /// The mobile drawer, likewise.
  List<NavMenu> get drawerMenus => _resolveNav(_navDrawerKeys);

  /// Every menu in a stable order — the editor's "add" picker draws from
  /// this, so a menu hidden in one view can still be placed in the other.
  List<NavMenu> get allMenus {
    final seen = <String>{};
    final out = <NavMenu>[];
    for (final menu in [...StoreNav.desktopOrder, ...StoreNav.drawerOrder]) {
      if (seen.add(menu.route)) out.add(menu);
    }
    return out;
  }

  List<NavMenu> _resolveNav(List<String> keys) {
    final out = <NavMenu>[];
    for (final route in keys) {
      final base = _navByRoute[route];
      if (base == null) continue;
      final patch = _navPatches[route];
      if (patch != null && !patch.visible) continue;
      out.add(_applyNavPatch(base, patch));
    }
    return out;
  }

  static NavMenu _applyNavPatch(NavMenu base, NavMenuState? patch) => NavMenu(
        label: patch?.label ?? base.label,
        route: base.route,
        icon: navIconFor(patch?.iconCode, base.icon),
        categories: base.categories,
        groups: base.groups,
        tiles: base.tiles,
      );

  void _mutatePatch(String route, NavMenuState Function(NavMenuState) update) {
    final next = update(_navPatches[route] ?? const NavMenuState());
    final isDefault = next.label == null && next.iconCode == null && next.visible;
    if (isDefault) {
      _navPatches.remove(route);
    } else {
      _navPatches[route] = next;
    }
    notifyListeners();
    _persist();
  }

  /// Empty [label] clears the override and reverts to the built-in text.
  void setNavLabel(String route, String label) {
    final trimmed = label.trim();
    _mutatePatch(
      route,
      (p) => NavMenuState(
        label: trimmed.isEmpty ? null : trimmed,
        iconCode: p.iconCode,
        visible: p.visible,
      ),
    );
  }

  /// [codePoint] 0 clears the override and reverts to the built-in icon.
  void setNavIcon(String route, int codePoint) => _mutatePatch(
        route,
        (p) => NavMenuState(
          label: p.label,
          iconCode: codePoint == 0 ? null : codePoint,
          visible: p.visible,
        ),
      );

  void setNavVisible(String route, bool visible) => _mutatePatch(
        route,
        (p) => NavMenuState(
          label: p.label,
          iconCode: p.iconCode,
          visible: visible,
        ),
      );

  List<String> _navKeysFor(String view) =>
      view == 'header' ? _navHeaderKeys : _navDrawerKeys;

  void moveNavEntry(String view, int index, int delta) {
    final keys = _navKeysFor(view);
    final target = index + delta;
    if (target < 0 || target >= keys.length || index == target) return;
    final item = keys.removeAt(index);
    keys.insert(target, item);
    notifyListeners();
    _persist();
  }

  void appendNavEntry(String view, String route) {
    final keys = _navKeysFor(view);
    if (!_navByRoute.containsKey(route) || keys.contains(route)) return;
    keys.add(route);
    notifyListeners();
    _persist();
  }

  void removeNavEntry(String view, String route) {
    final keys = _navKeysFor(view);
    if (!keys.remove(route)) return;
    notifyListeners();
    _persist();
  }

  void resetNav() {
    _navHeaderKeys
      ..clear()
      ..addAll([for (final m in StoreNav.desktopOrder) m.route]);
    _navDrawerKeys
      ..clear()
      ..addAll([for (final m in StoreNav.drawerOrder) m.route]);
    _navPatches.clear();
    notifyListeners();
    _persist();
  }

  // --- home layout

  List<String> _homeOrder = const [];
  final Set<String> _homeHidden = {};

  List<String> get homeSectionOrder => List.unmodifiable(_homeOrder);

  Set<String> get homeSectionHidden => Set.unmodifiable(_homeHidden);

  bool get hasHomeEdits =>
      _homeOrder.isNotEmpty || _homeHidden.isNotEmpty;

  /// Records the default section ids the first time the builder opens, so
  /// moves start from exactly what the customer sees now.
  void ensureHomeOrder(List<String> standardIds) {
    if (_homeOrder.isNotEmpty || standardIds.isEmpty) return;
    _homeOrder = List.of(standardIds);
    notifyListeners();
  }

  void moveHomeSection(int index, int delta) {
    final target = index + delta;
    if (_homeOrder.isEmpty ||
        target < 0 ||
        target >= _homeOrder.length ||
        target == index) {
      return;
    }
    final item = _homeOrder.removeAt(index);
    _homeOrder.insert(target, item);
    notifyListeners();
    _persist();
  }

  void setHomeSectionVisible(String id, bool visible) {
    if (visible) {
      _homeHidden.remove(id);
    } else {
      _homeHidden.add(id);
    }
    notifyListeners();
    _persist();
  }

  void resetHomeLayout() {
    _homeOrder = const [];
    _homeHidden.clear();
    notifyListeners();
    _persist();
  }

  // --- hero slides

  List<HeroSlide>? _heroSlides;

  /// The owner's explicit slides, or null while the config-derived default
  /// carousel is in charge.
  List<HeroSlide>? get heroSlides =>
      _heroSlides == null ? null : List.unmodifiable(_heroSlides!);

  bool get hasHeroEdits => _heroSlides != null;

  void setHeroSlides(List<HeroSlide> slides) {
    _heroSlides = List.of(slides);
    notifyListeners();
    _persist();
  }

  void resetHeroSlides() {
    if (_heroSlides == null) return;
    _heroSlides = null;
    notifyListeners();
    _persist();
  }

  // --- collections

  final List<ShopCollection> _collections;

  List<ShopCollection> get collections => List.unmodifiable(_collections);

  List<ShopCollection> get visibleCollections =>
      _collections.where((c) => c.visible).toList();

  ShopCollection? collectionById(String id) {
    for (final c in _collections) {
      if (c.id == id) return c;
    }
    return null;
  }

  void upsertCollection(ShopCollection collection) {
    if (collection.id.isEmpty) return;
    final index = _collections.indexWhere((c) => c.id == collection.id);
    if (index == -1) {
      _collections.add(collection);
    } else {
      _collections[index] = collection;
    }
    notifyListeners();
    _persist();
  }

  void removeCollection(String id) {
    if (!_collections.any((c) => c.id == id)) return;
    _collections.removeWhere((c) => c.id == id);
    notifyListeners();
    _persist();
  }

  void moveCollection(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _collections.length || target == index) return;
    final item = _collections.removeAt(index);
    _collections.insert(target, item);
    notifyListeners();
    _persist();
  }

  /// A free id derived from [seed] (route or name), `col-2` style fallback.
  String collectionIdFor(String seed) {
    var base = seed
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    base = base.replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) base = 'collection';
    var candidate = base;
    var suffix = 2;
    while (_collections.any((c) => c.id == candidate)) {
      candidate = '$base-$suffix';
      suffix++;
    }
    return candidate;
  }

  // --- daily metal rates (SPEC-18 / SPEC-19)

  // Demo-start board: the storefront shows these from first launch so the
  // rate strip never sits empty; the owner's save replaces them.
  static const int defaultGoldRateInrPerGram = 7250;
  static const int defaultSilverRateInrPerGram = 89;
  static const int defaultPlatinumRateInrPerGram = 3100;

  int? _goldRateInrPerGram = defaultGoldRateInrPerGram;
  int? _silverRateInrPerGram = defaultSilverRateInrPerGram;
  int? _platinumRateInrPerGram = defaultPlatinumRateInrPerGram;
  DateTime? _ratesUpdatedAt;

  int? get goldRateInrPerGram => _goldRateInrPerGram;

  int? get silverRateInrPerGram => _silverRateInrPerGram;

  int? get platinumRateInrPerGram => _platinumRateInrPerGram;

  DateTime? get ratesUpdatedAt => _ratesUpdatedAt;

  bool get hasRates =>
      _goldRateInrPerGram != null ||
      _silverRateInrPerGram != null ||
      _platinumRateInrPerGram != null;

  /// 0 or less clears that metal's rate.
  void setRates({
    required int goldPerGram,
    required int platinumPerGram,
    int silverPerGram = 0,
    DateTime? at,
  }) {
    _goldRateInrPerGram = goldPerGram > 0 ? goldPerGram : null;
    _silverRateInrPerGram = silverPerGram > 0 ? silverPerGram : null;
    _platinumRateInrPerGram = platinumPerGram > 0 ? platinumPerGram : null;
    final anySet = hasRates;
    _ratesUpdatedAt = anySet ? (at ?? DateTime.now()) : null;
    notifyListeners();
    _persist();
  }

  // --- customers & loyalty (SPEC-18)

  static final List<ShopCustomer> _defaultCustomers = [
    ShopCustomer(
      id: 'cus-asha',
      name: 'Asha Patel',
      phone: '+91 98450 12345',
      email: 'asha.patel@example.com',
      points: 1250,
      joinedAt: DateTime(2025, 11, 12),
    ),
    ShopCustomer(
      id: 'cus-rahul',
      name: 'Rahul Mehta',
      phone: '+91 98765 23456',
      email: 'rahul.mehta@example.com',
      points: 480,
      joinedAt: DateTime(2026, 1, 8),
    ),
    ShopCustomer(
      id: 'cus-divya',
      name: 'Divya Iyer',
      phone: '+91 99001 34567',
      email: 'divya.iyer@example.com',
      points: 2100,
      joinedAt: DateTime(2026, 3, 21),
    ),
  ];

  final List<ShopCustomer> _customers;
  final List<LoyaltyAdjustment> _loyaltyLedger = [];

  /// Seeded customers first, then buyers seen only in orders (as `auto-…`
  /// rows that gain full details once loyalty is adjusted for them).
  List<ShopCustomer> get customers {
    final out = <ShopCustomer>[..._customers];
    final seen = {for (final c in _customers) _nameKey(c.name)};
    for (final order in _orders) {
      final key = _nameKey(order.customerName);
      if (key.isEmpty || !seen.add(key)) continue;
      out.add(ShopCustomer(
        id: 'auto-$key',
        name: order.customerName,
        joinedAt: order.placedAt,
      ));
    }
    return out;
  }

  static String _nameKey(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

  ShopCustomer? customerById(String id) {
    for (final c in customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Positive [delta] awards points, negative deducts; the ledger records why.
  void adjustLoyalty(String customerId, int delta, String reason) {
    if (delta == 0) return;
    var index = _customers.indexWhere((c) => c.id == customerId);
    ShopCustomer base;
    if (index != -1) {
      base = _customers[index];
    } else {
      final derived = customerById(customerId);
      if (derived == null) return;
      base = derived;
    }
    final updated = base.copyWith(
      points: base.points + delta < 0 ? 0 : base.points + delta,
    );
    if (index != -1) {
      _customers[index] = updated;
    } else {
      _customers.add(updated);
      index = _customers.length - 1;
    }
    _loyaltyLedger.insert(
      0,
      LoyaltyAdjustment(
        customerId: customerId,
        delta: delta,
        reason: reason.trim().isEmpty ? 'Manual adjustment' : reason.trim(),
        at: DateTime.now(),
      ),
    );
    if (_loyaltyLedger.length > 200) {
      _loyaltyLedger.removeRange(200, _loyaltyLedger.length);
    }
    notifyListeners();
    _persist();
  }

  List<LoyaltyAdjustment> loyaltyLedgerFor(String customerId) =>
      _loyaltyLedger.where((e) => e.customerId == customerId).toList();

  // --- persistence (CatalogRepository)

  Future<void> _pendingWrite = Future<void>.value();

  /// Awaits any in-flight CMS save; tests and shutdown call this.
  Future<void> flushCms() => _pendingWrite;

  Future<void> loadCms() async {
    final repo = _repository;
    if (repo == null) return;
    try {
      final data = await repo.read();
      if (data == null) return;
      _decodeCms(data);
      notifyListeners();
    } catch (_) {
      // Corrupt or partial state falls back to the verified defaults.
    }
  }

  void _persist() {
    final repo = _repository;
    if (repo == null) return;
    final payload = _encodeCms();
    _pendingWrite = _pendingWrite
        .then((_) => repo.write(payload))
        .catchError((Object _) {});
  }

  Map<String, Object?> _encodeCms() => {
        'v': 1,
        'navHeaderKeys': _navHeaderKeys,
        'navDrawerKeys': _navDrawerKeys,
        'navPatches': {
          for (final entry in _navPatches.entries)
            entry.key: entry.value.toJson(),
        },
        'homeOrder': _homeOrder,
        'homeHidden': _homeHidden.toList(),
        if (_heroSlides != null)
          'heroSlides': [for (final s in _heroSlides!) s.toJson()],
        'collections': [for (final c in _collections) c.toJson()],
        'coupons': [for (final c in _coupons) c.toJson()],
        'goldRate': _goldRateInrPerGram,
        'silverRate': _silverRateInrPerGram,
        'platinumRate': _platinumRateInrPerGram,
        'ratesUpdatedAt': _ratesUpdatedAt?.toIso8601String(),
        'customers': [for (final c in _customers) c.toJson()],
        'loyalty': [for (final e in _loyaltyLedger) e.toJson()],
      };

  void _decodeCms(Map<String, Object?> data) {
    final header =
        _stringList(data['navHeaderKeys']).where(_navByRoute.containsKey);
    if (header.isNotEmpty) {
      _navHeaderKeys
        ..clear()
        ..addAll(header);
    }
    final drawer =
        _stringList(data['navDrawerKeys']).where(_navByRoute.containsKey);
    if (drawer.isNotEmpty) {
      _navDrawerKeys
        ..clear()
        ..addAll(drawer);
    }

    _navPatches.clear();
    final patches = _jsonMap(data['navPatches']);
    for (final entry in patches.entries) {
      if (!_navByRoute.containsKey(entry.key)) continue;
      _navPatches[entry.key] =
          NavMenuState.fromJson(_jsonMap(entry.value));
    }

    if (data['homeOrder'] is List) {
      _homeOrder = _stringList(data['homeOrder']);
    }
    _homeHidden
      ..clear()
      ..addAll(_stringList(data['homeHidden']));

    if (data['heroSlides'] is List) {
      _heroSlides = [
        for (final raw in _jsonList(data['heroSlides']))
          HeroSlide.fromJson(raw),
      ];
    }

    if (data['collections'] is List) {
      _collections
        ..clear()
        ..addAll([
          for (final raw in _jsonList(data['collections']))
            ShopCollection.fromJson(raw),
        ]);
    }

    if (data['coupons'] is List) {
      _coupons
        ..clear()
        ..addAll([
          for (final raw in _jsonList(data['coupons'])) Coupon.fromJson(raw),
        ]);
      _revalidateCoupon();
    }

    // Keys are only overwritten when present so a payload saved before a
    // metal existed keeps this store's demo-start board value.
    if (data.containsKey('goldRate')) {
      _goldRateInrPerGram = (data['goldRate'] as num?)?.toInt();
    }
    if (data.containsKey('silverRate')) {
      _silverRateInrPerGram = (data['silverRate'] as num?)?.toInt();
    }
    if (data.containsKey('platinumRate')) {
      _platinumRateInrPerGram = (data['platinumRate'] as num?)?.toInt();
    }
    if (data.containsKey('ratesUpdatedAt')) {
      _ratesUpdatedAt =
          DateTime.tryParse(data['ratesUpdatedAt'] as String? ?? '');
    }

    if (data['customers'] is List) {
      _customers
        ..clear()
        ..addAll([
          for (final raw in _jsonList(data['customers']))
            ShopCustomer.fromJson(raw),
        ]);
    }
    _loyaltyLedger
      ..clear()
      ..addAll([
        for (final raw in _jsonList(data['loyalty']))
          LoyaltyAdjustment.fromJson(raw),
      ]);
  }

  static List<String> _stringList(Object? value) =>
      (value as List? ?? const []).whereType<String>().toList();

  static Map<String, Object?> _jsonMap(Object? value) =>
      value is Map ? value.cast<String, Object?>() : const {};

  static List<Map<String, Object?>> _jsonList(Object? value) =>
      (value as List? ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, Object?>())
          .toList();

  // ---------------------------------------------------------------- helpers

  /// Writes stock without the notification side effects of [setStock], used
  /// while placing an order where the decrement is not a seller edit.
  void _applyStock(String productId, int stock) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index == -1) return;
    final product = _products[index];
    _products[index] = product.copyWith(
      stock: stock,
      inStock: stock > 0 ? product.inStock : false,
    );
  }

  List<Order> _sortedNewestFirst(Iterable<Order> source) =>
      source.toList()..sort((a, b) => b.placedAt.compareTo(a.placedAt));

  List<AppNotification> _sortedNotifications(Iterable<AppNotification> source) =>
      source.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  String _nextId(String prefix) {
    _sequence++;
    return '$prefix-${_sequence.toString().padLeft(4, '0')}';
  }

  /// Test seam: makes generated ids deterministic.
  @visibleForTesting
  void resetSequence() => _sequence = 0;
}
