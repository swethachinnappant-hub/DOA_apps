import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/notification.dart';
import '../models/order.dart';
import '../product.dart';
import '../services/realtime_service.dart';

/// Single source of truth for everything the buyer and seller surfaces read.
///
/// Both roles see the same records, which is the whole point: a seller's stock
/// edit and a buyer's catalogue view must never disagree. Every mutation
/// publishes to [RealtimeService] so the other role updates with no refresh.
class CommerceStore extends ChangeNotifier {
  CommerceStore({RealtimeService? realtime})
      : _realtime = realtime ?? RealtimeService.instance;

  final RealtimeService _realtime;

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

  List<CartItem> get cartProducts => _cart
      .where((item) => productFor(item) != null)
      .toList(growable: false);

  int get cartSubtotal => _cart.fold<int>(0, (sum, l) => sum + l.lineTotal);

  int get cartCount => _cart.fold<int>(0, (sum, l) => sum + l.quantity);

  bool get isCartEmpty => _cart.isEmpty;

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
    int quantity = 1,
    String? selectedSize,
    String? selectedShade,
  }) {
    if (quantity <= 0) return 0;

    final item = CartItem.fromProduct(
      product,
      quantity: quantity,
      selectedSize: selectedSize,
      selectedShade: selectedShade,
    );

    final index = _cart.indexWhere((l) => l.lineKey == item.lineKey);
    if (index == -1) {
      _cart.add(item);
    } else {
      _cart[index] = _cart[index].copyWith(
        quantity: _cart[index].quantity + quantity,
      );
    }
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
      _cart[index] = _cart[index].copyWith(quantity: quantity);
    }
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
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
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
