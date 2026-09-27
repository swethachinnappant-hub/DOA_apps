import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce_app/core/models/user.dart';
import 'package:ecommerce_app/core/router/app_router.dart';
import 'package:ecommerce_app/features/auth/providers/auth_provider.dart';

/// The role matrix: which paths each kind of visitor may reach.
///
/// This is the rule that keeps a shopper out of the seller console and an
/// owner out of the checkout, so it is asserted directly rather than only
/// through a pumped screen.
void main() {
  Future<AuthProvider> signedOut() async {
    final auth = AuthProvider();
    await auth.restore();
    return auth;
  }

  AuthProvider customer() {
    final auth = AuthProvider();
    auth.signInAsDemo(UserRole.customer);
    return auth;
  }

  AuthProvider owner() {
    final auth = AuthProvider();
    auth.signInAsDemo(UserRole.owner);
    return auth;
  }

  group('while the session is restoring', () {
    test('no path is redirected, so the splash is never bounced', () {
      final auth = AuthProvider();
      expect(auth.isRestoring, isTrue);
      expect(guardLocation(auth, '/app'), isNull);
      expect(guardLocation(auth, '/owner'), isNull);
      expect(guardLocation(auth, '/login'), isNull);
      expect(guardLocation(auth, '/cart'), isNull);
    });
  });

  group('signed out', () {
    test('the launch and setup paths are reachable', () async {
      final auth = await signedOut();
      for (final path in [
        '/',
        '/login',
        '/register',
        '/config',
        '/business-rules',
      ]) {
        expect(guardLocation(auth, path), isNull, reason: path);
      }
    });

    test('everything else sends the visitor to sign in', () async {
      final auth = await signedOut();
      for (final path in [
        '/app',
        '/catalogue',
        '/cart',
        '/checkout',
        '/orders',
        '/order/ORD-1',
        '/profile',
        '/notifications',
        '/owner',
        '/owner/products',
        '/owner/orders',
        '/something/unknown',
      ]) {
        expect(guardLocation(auth, path), '/login', reason: path);
      }
    });
  });

  group('signed in as a customer', () {
    test('the shopping routes are open', () {
      final auth = customer();
      for (final path in [
        '/app',
        '/catalogue',
        '/product/p1',
        '/wishlist',
        '/cart',
        '/checkout',
        '/orders',
        '/order/ORD-1',
        '/profile',
        '/notifications',
        '/config',
        '/business-rules',
      ]) {
        expect(guardLocation(auth, path), isNull, reason: path);
      }
    });

    test('the seller console is closed', () {
      final auth = customer();
      expect(guardLocation(auth, '/owner'), '/app');
      expect(guardLocation(auth, '/owner/products'), '/app');
      expect(guardLocation(auth, '/owner/products/new'), '/app');
      expect(guardLocation(auth, '/owner/orders'), '/app');
      expect(guardLocation(auth, '/owner/orders/ORD-1'), '/app');
    });

    test('a signed-in shopper is moved off the sign-in screens', () {
      final auth = customer();
      expect(guardLocation(auth, '/login'), '/app');
      expect(guardLocation(auth, '/register'), '/app');
    });

    test('the splash still resolves on its own', () {
      final auth = customer();
      expect(guardLocation(auth, '/'), isNull);
    });
  });

  group('signed in as a shop owner', () {
    test('the seller console is open', () {
      final auth = owner();
      for (final path in [
        '/owner',
        '/owner/products',
        '/owner/products/new',
        '/owner/products/p1/edit',
        '/owner/orders',
        '/owner/orders/ORD-1',
      ]) {
        expect(guardLocation(auth, path), isNull, reason: path);
      }
    });

    test('shared screens stay reachable', () {
      final auth = owner();
      expect(guardLocation(auth, '/profile'), isNull);
      expect(guardLocation(auth, '/notifications'), isNull);
      expect(guardLocation(auth, '/config'), isNull);
      expect(guardLocation(auth, '/business-rules'), isNull);
    });

    test('the storefront is closed', () {
      final auth = owner();
      for (final path in [
        '/app',
        '/catalogue',
        '/product/p1',
        '/wishlist',
        '/cart',
        '/checkout',
        '/orders',
        '/order/ORD-1',
      ]) {
        expect(guardLocation(auth, path), '/owner', reason: path);
      }
    });

    test('a signed-in owner is moved off the sign-in screens', () {
      final auth = owner();
      expect(guardLocation(auth, '/login'), '/owner');
      expect(guardLocation(auth, '/register'), '/owner');
    });
  });

  group('role homes', () {
    test('each role lands on its own route after redirecting an auth page', () {
      expect(guardLocation(customer(), '/login'), '/app');
      expect(guardLocation(owner(), '/login'), '/owner');
    });
  });
}
