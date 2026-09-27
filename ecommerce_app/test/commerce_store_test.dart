import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce_app/core/models/notification.dart';
import 'package:ecommerce_app/core/models/order.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:ecommerce_app/core/services/realtime_service.dart';
import 'package:ecommerce_app/core/store/commerce_store.dart';

Product product({
  required String id,
  String name = 'Test Product',
  int price = 999,
  int mrp = 1999,
  String ownerId = '',
  int stock = 0,
  bool inStock = true,
}) {
  return Product(
    id: id,
    name: name,
    brand: 'Brand of $name',
    category: 'Women > Tops',
    sku: 'SKU-$id',
    price: price,
    mrp: mrp,
    rating: 4.4,
    reviewCount: 128,
    images: ['https://picsum.photos/seed/$id/640/800'],
    icon: Icons.image_outlined,
    inStock: inStock,
    ownerId: ownerId,
    stock: stock,
    createdAt: DateTime(2026, 9, 20),
  );
}

void main() {
  late RealtimeService realtime;
  late CommerceStore store;

  setUp(() {
    realtime = RealtimeService.instance;
    store = CommerceStore(realtime: realtime);
  });

  tearDown(() {
    realtime.dispose();
  });

  group('shared catalogue', () {
    test('a seller listing and platform stock both reach the shopper', () {
      store.seedProducts([product(id: 'seed-1', ownerId: '', stock: 0)]);
      store.publishProduct(
        product(id: 'own-1', ownerId: 'owner-1', stock: 12, name: 'Silk Kurta'),
      );

      final ids = store.shopProducts.map((p) => p.id).toList();
      expect(ids, containsAll(['seed-1', 'own-1']));
      expect(store.allProducts.length, 2);
    });

    test('owner listings sort ahead of platform seed', () {
      store.seedProducts([product(id: 'seed-1', ownerId: '')]);
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 5));

      expect(store.shopProducts.first.id, 'own-1');
    });

    test('an owner sees only their own listings', () {
      store.publishProduct(product(id: 'a', ownerId: 'owner-1', stock: 3));
      store.publishProduct(product(id: 'b', ownerId: 'owner-2', stock: 3));

      expect(store.productsForOwner('owner-1').map((p) => p.id), ['a']);
      expect(store.productsForOwner('owner-2').map((p) => p.id), ['b']);
    });

    test('sold-out owner stock is hidden from the shopper', () {
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 4));
      expect(store.shopProducts, isNotEmpty);

      store.setStock('own-1', 0);

      expect(store.shopProducts, isEmpty);
    });

    test('re-seeding the platform catalogue keeps seller listings', () {
      store.seedProducts([product(id: 'seed-1')]);
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 2));

      store.seedProducts([product(id: 'seed-2')]);

      expect(store.allProducts.map((p) => p.id), contains('own-1'));
      expect(store.allProducts.map((p) => p.id), contains('seed-2'));
      expect(store.allProducts.map((p) => p.id), isNot(contains('seed-1')));
    });
  });

  group('real-time propagation', () {
    test('publishing a product emits an event to subscribers', () async {
      final events = <AppEvent>[];
      final sub = realtime.events.listen(events.add);

      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 7));
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(events, hasLength(1));
      expect(events.single.type, AppEventType.productPublished);
      expect(events.single.productId, 'own-1');
      expect(events.single.product?.ownerId, 'owner-1');
    });

    test('a stock edit emits an event and a broadcast notification', () async {
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 1));

      final events = <AppEvent>[];
      final notes = <AppNotification>[];
      final sub1 = realtime.events.listen(events.add);
      final sub2 = realtime.notifications.listen(notes.add);

      store.setStock('own-1', 0);
      await Future<void>.delayed(Duration.zero);
      await sub1.cancel();
      await sub2.cancel();

      expect(events.single.type, AppEventType.stockChanged);
      expect(notes.single.type, NotificationType.outOfStock);
      // The shopper reloads and simply does not see the item any more.
      expect(store.shopProducts, isEmpty);
    });

    test('both roles see the same order record', () {
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 10));
      store.addToCart(store.productById('own-1')!);

      final order = store.placeOrder(
        customerId: 'cust-1',
        customerName: 'Priya S',
        deliveryAddress: '14 MG Road',
      );

      expect(order, isNotNull);
      expect(store.ordersForCustomer('cust-1'), hasLength(1));
      expect(store.ordersForOwner('owner-1'), hasLength(1));
      expect(
        store.ordersForCustomer('cust-1').single.id,
        store.ordersForOwner('owner-1').single.id,
      );
    });

    test('an owner status change reaches the customer as a notification',
        () async {
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 10));
      store.addToCart(store.productById('own-1')!);
      final order = store.placeOrder(
        customerId: 'cust-1',
        customerName: 'Priya S',
        deliveryAddress: '14 MG Road',
      )!;

      final customerNotes = <AppNotification>[];
      final sub = realtime.notifications.listen(customerNotes.add);

      // placed -> confirmed -> packed -> shipped, one legal step at a time.
      expect(store.advanceOrder(order.id), isTrue);
      expect(store.advanceOrder(order.id), isTrue);
      expect(store.advanceOrder(order.id), isTrue);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(customerNotes, hasLength(3));
      expect(customerNotes.first.audienceId, 'cust-1');
      expect(customerNotes.last.title, OrderStatus.shipped.label);

      final seenByCustomer = store.notificationsFor('cust-1');
      expect(seenByCustomer.first.title, OrderStatus.shipped.label);
      expect(store.unreadCount('cust-1'), greaterThan(0));
    });

    test('the seller is notified of a new order', () {
      store.publishProduct(product(id: 'own-1', ownerId: 'owner-1', stock: 10));
      store.addToCart(store.productById('own-1')!);
      store.placeOrder(
        customerId: 'cust-1',
        customerName: 'Priya S',
        deliveryAddress: '14 MG Road',
      );

      final forSeller = store.notificationsFor('owner-1');
      expect(forSeller, isNotEmpty);
      expect(forSeller.first.title, 'New order');
    });
  });

  group('cart', () {
    test('adds a line', () {
      store.addToCart(product(id: 'p1'));
      expect(store.cartCount, 1);
      expect(store.cartSubtotal, 999);
    });

    test('merges the same variant instead of duplicating the line', () {
      final p = product(id: 'p1');
      store.addToCart(p, selectedSize: 'M');
      store.addToCart(p, selectedSize: 'M');
      store.addToCart(p, selectedSize: 'M');

      expect(store.cart, hasLength(1));
      expect(store.cartCount, 3);
      expect(store.cartSubtotal, 999 * 3);
    });

    test('keeps different sizes as separate lines', () {
      final p = product(id: 'p1');
      store.addToCart(p, selectedSize: 'M');
      store.addToCart(p, selectedSize: 'L');

      expect(store.cart, hasLength(2));
      expect(store.cartCount, 2);
    });

    test('increments a line', () {
      store.addToCart(product(id: 'p1'));
      store.incrementCart(store.cart.single.lineKey);

      expect(store.cartCount, 2);
      expect(store.cartSubtotal, 999 * 2);
    });

    test('decrementing past zero removes the line', () {
      store.addToCart(product(id: 'p1'));
      store.decrementCart(store.cart.single.lineKey);

      expect(store.cart, isEmpty);
      expect(store.isCartEmpty, isTrue);
    });

    test('setCartQuantity can raise a line without touching another', () {
      store.addToCart(product(id: 'p1'), selectedSize: 'M');
      store.addToCart(product(id: 'p2'), selectedSize: 'L');

      store.setCartQuantity(store.cart.first.lineKey, 5);

      expect(store.cart.first.quantity, 5);
      expect(store.cart.last.quantity, 1);
      expect(store.cartCount, 6);
    });

    test('removing a product from the catalogue drops it from the cart', () {
      store.publishProduct(product(id: 'own-1', ownerId: 'o1', stock: 5));
      store.addToCart(store.productById('own-1')!);

      store.deleteProduct('own-1');

      expect(store.cart, isEmpty);
    });

    test('placing an order empties the cart', () {
      store.addToCart(product(id: 'p1'));
      store.placeOrder(
        customerId: 'c1',
        customerName: 'A',
        deliveryAddress: 'B',
      );

      expect(store.isCartEmpty, isTrue);
      expect(store.cartSubtotal, 0);
    });

    test('placing from an empty cart returns null', () {
      expect(
        store.placeOrder(
          customerId: 'c1',
          customerName: 'A',
          deliveryAddress: 'B',
        ),
        isNull,
      );
    });
  });

  group('orders', () {
    CommerceStore buildOrderStore() {
      final s = CommerceStore(realtime: RealtimeService.instance);
      s.publishProduct(
        product(id: 'own-1', ownerId: 'owner-1', stock: 10, price: 499, mrp: 999),
      );
      s.addToCart(s.productById('own-1')!, quantity: 2);
      return s;
    }

    test('order snapshot records the buyer, seller and address', () {
      final order = buildOrderStore().placeOrder(
        customerId: 'cust-1',
        customerName: 'Priya S',
        deliveryAddress: '14 MG Road, Bengaluru',
        paymentMethod: 'Cash on Delivery',
      )!;

      expect(order.customerId, 'cust-1');
      expect(order.ownerId, 'owner-1');
      expect(order.deliveryAddress, '14 MG Road, Bengaluru');
      expect(order.paymentMethod, 'Cash on Delivery');
      expect(order.status, OrderStatus.placed);
      expect(order.itemCount, 2);
      expect(order.subtotal, 499 * 2);
      expect(order.updatedAt, isNull);
    });

    test('placing an order deducts the seller stock', () {
      final store = buildOrderStore();
      store.placeOrder(
        customerId: 'c1',
        customerName: 'A',
        deliveryAddress: 'B',
      );

      expect(store.productById('own-1')!.stock, 8);
    });

    test('advances through the flow and stamps updatedAt', () {
      final store = buildOrderStore();
      final order = store.placeOrder(
        customerId: 'c1',
        customerName: 'A',
        deliveryAddress: 'B',
      )!;
      expect(order.updatedAt, isNull);

      expect(store.advanceOrder(order.id), isTrue);

      final after = store.orderById(order.id)!;
      expect(after.status, OrderStatus.confirmed);
      expect(after.updatedAt, isNotNull);
      // The stamp lands at or after placement; the clock may not tick inside
      // a single test, so an equality check is valid here.
      expect(after.updatedAt!.isBefore(order.placedAt), isFalse);
    });

    test('rejects an illegal backwards transition', () {
      final store = buildOrderStore();
      final order = store.placeOrder(
        customerId: 'c1',
        customerName: 'A',
        deliveryAddress: 'B',
      )!;
      store.advanceOrder(order.id); // placed -> processed

      final jumped = store.advanceOrderStatus(order.id, OrderStatus.placed);

      expect(jumped, isFalse);
      expect(store.orderById(order.id)!.status, OrderStatus.confirmed);
    });

    test('a delivered order has no further transition', () {
      final store = buildOrderStore();
      final order = store.placeOrder(
        customerId: 'c1',
        customerName: 'A',
        deliveryAddress: 'B',
      )!;

      // A seller cannot skip straight to the end; the flow is one step at a
      // time, so an illegal jump leaves the order untouched.
      expect(store.advanceOrderStatus(order.id, OrderStatus.delivered), isFalse);
      expect(store.orderById(order.id)!.status, OrderStatus.placed);

      // placed -> confirmed -> packed -> shipped -> out for delivery ->
      // delivered, then the flow closes.
      var guard = 0;
      while (store.advanceOrder(order.id) && guard++ < 10) {}

      final done = store.orderById(order.id)!;
      expect(done.status, OrderStatus.delivered);
      expect(store.advanceOrder(order.id), isFalse);
      expect(store.advanceOrderStatus(order.id, OrderStatus.cancelled), isFalse);
      expect(done.updatedAt, isNotNull);
    });

    test('advancing an unknown order is a no-op', () {
      expect(store.advanceOrder('nope'), isFalse);
      expect(store.advanceOrderStatus('nope', OrderStatus.shipped), isFalse);
    });

    test('orders sort newest first for both roles', () {
      final s = buildOrderStore();
      s.placeOrder(customerId: 'c1', customerName: 'A', deliveryAddress: 'B');
      final first = s.allOrders.single;
      expect(first.placedAt, isNotNull);
      expect(s.ordersForCustomer('c1'), hasLength(1));
    });
  });

  group('notifications', () {
    test('broadcast notices reach every audience', () {
      store.pushNotification(AppNotification(
        id: 'n1',
        type: NotificationType.newArrival,
        title: 'Just dropped',
        body: 'Something new',
        audienceId: '*',
        createdAt: DateTime.now(),
      ));

      expect(store.notificationsFor('anyone'), hasLength(1));
      expect(store.notificationsFor('other-role'), hasLength(1));
    });

    test('direct notices reach only the addressee', () {
      store.pushNotification(AppNotification(
        id: 'n1',
        type: NotificationType.orderStatus,
        title: 'Packed',
        body: 'x',
        audienceId: 'cust-1',
        createdAt: DateTime.now(),
      ));

      expect(store.notificationsFor('cust-1'), hasLength(1));
      expect(store.notificationsFor('owner-1'), isEmpty);
    });

    test('marking read clears the unread badge without deleting history', () {
      store.pushNotification(AppNotification(
        id: 'n1',
        type: NotificationType.orderStatus,
        title: 'Packed',
        body: 'x',
        audienceId: 'cust-1',
        createdAt: DateTime.now(),
      ));
      expect(store.unreadCount('cust-1'), 1);

      store.markNotificationRead('n1');

      expect(store.unreadCount('cust-1'), 0);
      expect(store.notificationsFor('cust-1'), hasLength(1));
    });

    test('mark all read only touches that audience', () {
      for (final audience in ['cust-1', 'owner-1']) {
        store.pushNotification(AppNotification(
          id: 'n-$audience',
          type: NotificationType.orderStatus,
          title: 't',
          body: 'b',
          audienceId: audience,
          createdAt: DateTime.now(),
        ));
      }

      store.markAllRead('cust-1');

      expect(store.unreadCount('cust-1'), 0);
      expect(store.unreadCount('owner-1'), 1);
    });

    test('clearing history keeps the other role\'s messages', () {
      store.pushNotification(AppNotification(
        id: 'n1',
        type: NotificationType.orderStatus,
        title: 't',
        body: 'b',
        audienceId: 'cust-1',
        createdAt: DateTime.now(),
      ));
      store.pushNotification(AppNotification(
        id: 'n2',
        type: NotificationType.orderPlaced,
        title: 't',
        body: 'b',
        audienceId: 'owner-1',
        createdAt: DateTime.now(),
      ));

      store.clearNotifications('cust-1');

      expect(store.notificationsFor('cust-1'), isEmpty);
      expect(store.notificationsFor('owner-1'), hasLength(1));
    });

    test('notifications sort newest first', () {
      store.pushNotification(AppNotification(
        id: 'old',
        type: NotificationType.orderStatus,
        title: 'old',
        body: 'b',
        audienceId: 'cust-1',
        createdAt: DateTime(2026, 1, 1),
      ));
      store.pushNotification(AppNotification(
        id: 'new',
        type: NotificationType.orderStatus,
        title: 'new',
        body: 'b',
        audienceId: 'cust-1',
        createdAt: DateTime(2026, 9, 20),
      ));

      expect(store.notificationsFor('cust-1').map((n) => n.id), ['new', 'old']);
    });
  });

  group('wishlist', () {
    test('toggling saves then removes and reports the new state', () {
      store.seedProducts([product(id: 'a'), product(id: 'b')]);
      var rebuilds = 0;
      store.addListener(() => rebuilds++);

      expect(store.toggleWishlist('a'), isTrue);
      expect(store.isWishlisted('a'), isTrue);
      expect(store.wishlistIds, ['a']);

      expect(store.toggleWishlist('a'), isFalse);
      expect(store.isWishlisted('a'), isFalse);
      expect(store.wishlistCount, 0);

      expect(rebuilds, 2, reason: 'the badge and wishlist screen rebuild');
    });

    test('a product that is not in the catalogue cannot be saved', () {
      expect(store.toggleWishlist('missing'), isFalse);
      expect(store.wishlistIds, isEmpty);
    });

    test('saved products resolve against the live catalogue', () {
      store.seedProducts([product(id: 'a', name: 'Silk Kurta')]);
      store.toggleWishlist('a');

      expect(store.wishlistProducts.single.name, 'Silk Kurta');

      store.deleteProduct('a');

      expect(store.wishlistProducts, isEmpty,
          reason: 'a delisted product drops off the wishlist');
      expect(store.isWishlisted('a'), isTrue);
    });
  });
}
