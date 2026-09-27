import 'package:ecommerce_app/core/models/cart.dart';
import 'package:ecommerce_app/core/models/notification.dart';
import 'package:ecommerce_app/core/models/order.dart';
import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const IconData _icon = Icons.checkroom;

Product _product({
  String id = 'p1',
  int price = 1299,
  int mrp = 2999,
  int stock = 10,
  String ownerId = '',
  bool inStock = true,
  int deliveryDays = 3,
}) {
  return Product(
    id: id,
    name: 'Oxford Shirt',
    brand: 'Acme',
    category: 'Men',
    sku: 'SKU-0001',
    price: price,
    mrp: mrp,
    rating: 4.2,
    reviewCount: 100,
    images: const ['https://example.com/a.jpg'],
    icon: _icon,
    inStock: inStock,
    deliveryDays: deliveryDays,
    ownerId: ownerId,
    stock: stock,
  );
}

void main() {
  group('UserRole', () {
    test('sends each role to its own home', () {
      expect(UserRole.customer.homePath, '/app');
      expect(UserRole.owner.homePath, '/owner');
    });

    test('round-trips by name and defaults to customer', () {
      expect(UserRole.fromName('owner'), UserRole.owner);
      expect(UserRole.fromName('customer'), UserRole.customer);
      expect(UserRole.fromName('nonsense'), UserRole.customer);
      expect(UserRole.fromName(null), UserRole.customer);
    });
  });

  group('AppUser', () {
    test('builds initials from a multi-word name', () {
      const user = AppUser(
        id: 'u1',
        name: 'Chirag Associates',
        email: 'a@b.com',
        phone: '1',
        role: UserRole.customer,
      );
      expect(user.initials, 'CA');
    });

    test('builds initials from a single-word name', () {
      const user = AppUser(
        id: 'u1',
        name: 'Priya',
        email: 'a@b.com',
        phone: '1',
        role: UserRole.customer,
      );
      expect(user.initials, 'P');
    });

    test('falls back to the contact name when an owner has no shop name', () {
      const noShop = AppUser(
        id: 'o1',
        name: 'Raj Patel',
        email: 'a@b.com',
        phone: '1',
        role: UserRole.owner,
      );
      expect(noShop.displayName, 'Raj Patel');

      const withShop = AppUser(
        id: 'o1',
        name: 'Raj Patel',
        email: 'a@b.com',
        phone: '1',
        role: UserRole.owner,
        shopName: 'Silver Studio',
      );
      expect(withShop.displayName, 'Silver Studio');
    });

    test('survives a json round trip', () {
      const user = AppUser(
        id: 'o1',
        name: 'Raj Patel',
        email: 'r@s.com',
        phone: '99999',
        role: UserRole.owner,
        shopName: 'Silver Studio',
      );
      expect(AppUser.fromJson(user.toJson()), user);
    });
  });

  group('Product ownership', () {
    test('seeded listings ignore stock and follow the inStock flag', () {
      final seeded = _product(inStock: true, stock: 0);
      expect(seeded.isAvailable, isTrue);

      final soldOut = _product(inStock: false, stock: 50);
      expect(soldOut.isAvailable, isFalse);
    });

    test('owner listings go unavailable at zero stock', () {
      expect(_product(ownerId: 'o1', stock: 1).isAvailable, isTrue);
      expect(_product(ownerId: 'o1', stock: 0).isAvailable, isFalse);
    });

    test('flags low stock only for owner listings', () {
      expect(_product(ownerId: 'o1', stock: 3).isLowStock, isTrue);
      expect(_product(ownerId: 'o1', stock: 50).isLowStock, isFalse);
      expect(_product(ownerId: '', stock: 3).isLowStock, isFalse);
    });

    test('copyWith can edit every owner-facing field', () {
      final edited = _product(ownerId: 'o1', stock: 4).copyWith(
        name: 'New Name',
        price: 999,
        stock: 42,
        images: const ['a', 'b'],
        inStock: true,
      );

      expect(edited.name, 'New Name');
      expect(edited.price, 999);
      expect(edited.stock, 42);
      expect(edited.images, ['a', 'b']);
      expect(edited.ownerId, 'o1');
    });

    test('copyWith preserves untouched fields', () {
      final original = _product(price: 1111, stock: 7);
      final edited = original.copyWith(name: 'Changed');
      expect(edited.price, 1111);
      expect(edited.stock, 7);
      expect(edited.sku, original.sku);
    });
  });

  group('OrderStatus state machine', () {
    test('walks forward one step at a time', () {
      expect(OrderStatus.placed.next, OrderStatus.confirmed);
      expect(OrderStatus.confirmed.next, OrderStatus.packed);
      expect(OrderStatus.packed.next, OrderStatus.shipped);
      expect(OrderStatus.shipped.next, OrderStatus.outForDelivery);
      expect(OrderStatus.outForDelivery.next, OrderStatus.delivered);
      expect(OrderStatus.delivered.next, isNull);
    });

    test('rejects skipping a step', () {
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.shipped), isFalse);
      expect(
        OrderStatus.packed.canTransitionTo(OrderStatus.delivered),
        isFalse,
      );
    });

    test('accepts the legal next step', () {
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.confirmed), isTrue);
      expect(
        OrderStatus.shipped.canTransitionTo(OrderStatus.outForDelivery),
        isTrue,
      );
    });

    test('allows cancelling only while active', () {
      expect(OrderStatus.placed.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.cancelled), isTrue);
      expect(
        OrderStatus.delivered.canTransitionTo(OrderStatus.cancelled),
        isFalse,
      );
    });

    test('never moves backwards or stays put', () {
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.packed), isFalse);
      expect(OrderStatus.shipped.canTransitionTo(OrderStatus.shipped), isFalse);
    });

    test('closed statuses are closed', () {
      expect(OrderStatus.delivered.isClosed, isTrue);
      expect(OrderStatus.cancelled.isClosed, isTrue);
      expect(OrderStatus.returned.isClosed, isTrue);
      expect(OrderStatus.shipped.isActive, isTrue);
    });

    test('round-trips by name', () {
      expect(OrderStatus.fromName('shipped'), OrderStatus.shipped);
      expect(OrderStatus.fromName('bogus'), OrderStatus.placed);
      expect(OrderStatus.fromName(null), OrderStatus.placed);
    });
  });

  group('Order', () {
    Order build({int unitPrice = 1000, int quantity = 1}) {
      return Order(
        id: 'ORD-1',
        customerId: 'u1',
        customerName: 'Priya',
        ownerId: 'o1',
        ownerName: 'Silver Studio',
        placedAt: DateTime(2026, 1, 1),
        items: [
          OrderItem.fromProduct(
            _product(price: unitPrice),
            quantity: quantity,
          ),
        ],
      );
    }

    test('computes subtotal, tax and free-shipping threshold', () {
      final order = build(unitPrice: 2000);
      expect(order.subtotal, 2000);
      expect(order.tax, 360);
      expect(order.shipping, 0);
      expect(order.total, 2360);
    });

    test('charges shipping below the threshold', () {
      final order = build(unitPrice: 500);
      expect(order.shipping, 79);
      expect(order.amountToFreeShipping, 499);
    });

    test('reports no gap once free shipping is earned', () {
      final order = build(unitPrice: 1000);
      expect(order.isFreeShipping, isTrue);
      expect(order.amountToFreeShipping, 0);
    });

    test('counts total quantity across lines', () {
      expect(build(quantity: 3).itemCount, 3);
    });

    test('advances status and stamps the time', () {
      final order = build();
      expect(order.status, OrderStatus.placed);

      final moved = order.copyWith(status: OrderStatus.confirmed);
      expect(moved.status, OrderStatus.confirmed);
      expect(moved.updatedAt, isNotNull);
    });

    test('survives a json round trip', () {
      final order = build().copyWith(
        status: OrderStatus.shipped,
        updatedAt: DateTime(2026, 2, 2),
      );
      final restored = Order.fromJson(order.toJson());

      expect(restored.id, order.id);
      expect(restored.status, OrderStatus.shipped);
      expect(restored.items.length, 1);
      expect(restored.items.first.unitPrice, 1000);
      expect(restored.total, order.total);
    });
  });

  group('CartItem', () {
    test('separates the same product bought in different sizes', () {
      final small = CartItem.fromProduct(_product(), selectedSize: 'S');
      final large = CartItem.fromProduct(_product(), selectedSize: 'L');
      expect(small.lineKey, isNot(large.lineKey));
    });

    test('merges identical variant selections', () {
      final a = CartItem.fromProduct(_product(), selectedSize: 'M');
      final b = CartItem.fromProduct(_product(), selectedSize: 'M');
      expect(a.lineKey, b.lineKey);
    });

    test('labels the chosen variant', () {
      final item = CartItem.fromProduct(
        _product(),
        selectedSize: 'L',
        selectedShade: 'Ivory',
      );
      expect(item.variantLabel, 'L · Ivory');
      expect(CartItem.fromProduct(_product()).variantLabel, '');
    });

    test('converts to an order item preserving the variant', () {
      final item = CartItem.fromProduct(_product(), selectedShade: 'Rose Gold');
      final orderItem = item.toOrderItem();
      expect(orderItem.selectedShade, 'Rose Gold');
      expect(orderItem.lineTotal, item.lineTotal);
    });

    test('survives a json round trip', () {
      final item = CartItem.fromProduct(_product(), quantity: 2);
      final restored = CartItem.fromJson(item.toJson());
      expect(restored.quantity, 2);
      expect(restored.productId, item.productId);
    });
  });

  group('AppNotification', () {
    test('round-trips through json', () {
      final note = AppNotification(
        id: 'n1',
        type: NotificationType.orderStatus,
        title: 'Shipped',
        body: 'Your order is on the way',
        audienceId: 'u1',
        createdAt: DateTime(2026, 3, 3),
        route: '/order/ORD-1',
      );
      final restored = AppNotification.fromJson(note.toJson());
      expect(restored, note);
    });

    test('marks itself read without mutating the original', () {
      final note = AppNotification(
        id: 'n1',
        type: NotificationType.orderPlaced,
        title: 't',
        body: 'b',
        audienceId: 'u1',
        createdAt: DateTime(2026, 3, 3),
      );
      final read = note.copyWith(read: true);
      expect(note.read, isFalse);
      expect(read.read, isTrue);
    });
  });
}
