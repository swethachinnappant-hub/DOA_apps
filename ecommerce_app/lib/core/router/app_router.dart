import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/catalogue/screens/catalogue_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/config/screens/business_config_screen.dart';
import '../../features/config/screens/business_rules_screen.dart';
import '../../features/main_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/owner/screens/owner_dashboard_screen.dart';
import '../../features/owner/screens/owner_order_detail_screen.dart';
import '../../features/owner/screens/owner_orders_screen.dart';
import '../../features/owner/screens/owner_product_form_screen.dart';
import '../../features/owner/screens/owner_products_screen.dart';
import '../../features/owner/screens/owner_shell.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../core/models/user.dart';

/// Reachable before signing in: the launch flow and the shop setup screens.
const Set<String> _publicPaths = {
  '/',
  '/login',
  '/register',
  '/config',
  '/business-rules',
};

/// Reachable by whichever role is signed in. These carry no buyer/seller
/// responsibility, so gating them by role would only add friction.
const Set<String> _sharedPaths = {
  '/config',
  '/business-rules',
  '/profile',
  '/notifications',
};

/// Builds the router with a role guard bound to [auth].
///
/// `refreshListenable` is the important part: when someone signs in or out,
/// every route in flight is re-evaluated, so a customer who taps a bookmarked
/// `/owner/...` link is sent to their own home instead of seeing a seller
/// screen they have no business seeing.
GoRouter buildAppRouter({required AuthProvider auth}) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) => guardLocation(auth, state.matchedLocation),
    errorBuilder: (context, state) => _RouteFallback(state: state),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/config',
        builder: (context, state) => const BusinessConfigScreen(),
      ),
      GoRoute(
        path: '/business-rules',
        builder: (context, state) => const BusinessRulesScreen(),
      ),

      // ----------------------------------------------------- seller console
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            OwnerShell(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner',
                builder: (context, state) => const OwnerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/products',
                builder: (context, state) => const OwnerProductsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        const OwnerProductFormScreen(productId: null),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    builder: (context, state) => OwnerProductFormScreen(
                      productId: state.pathParameters['id'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/orders',
                builder: (context, state) => const OwnerOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OwnerOrderDetailScreen(
                      orderId: state.pathParameters['id'] ?? '',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ---------------------------------------------------------- storefront
      GoRoute(path: '/app', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return CatalogueScreen(
            initialCategory: query['category'],
            priceMin: int.tryParse(query['min'] ?? ''),
            priceMax: int.tryParse(query['max'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id'] ?? 'p0'),
      ),
      GoRoute(
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/order/:id',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
}

/// Decides where [location] is allowed to land for the signed-in [auth].
///
/// Returns `null` to allow the navigation, or the path to redirect to.
/// Exposed so the whole matrix can be asserted directly rather than only
/// through a pumped widget tree.
String? guardLocation(AuthProvider auth, String location) {
  // The splash screen navigates on its own timer while the session is read
  // back, and it is public, so it never needs correcting.
  if (location == '/') return null;
  if (auth.isRestoring) return null;

  final isAuthPage = location == '/login' || location == '/register';
  final isPublic = _publicPaths.contains(location);

  if (!auth.isSignedIn) {
    return (isPublic || isAuthPage) ? null : '/login';
  }

  final role = auth.role ?? UserRole.customer;

  // Someone already signed in has no reason to sit on a sign-in form.
  if (isAuthPage) return role.homePath;

  if (role == UserRole.owner) {
    final inConsole = location.startsWith('/owner');
    return (inConsole || _sharedPaths.contains(location)) ? null : '/owner';
  }

  // A shopper is never allowed into the seller console.
  if (location.startsWith('/owner')) return '/app';
  return null;
}

/// Friendly landing for a link that does not exist, rather than a red screen.
class _RouteFallback extends StatelessWidget {
  const _RouteFallback({required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                '${state.matchedLocation} does not exist',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // `read` inside the handler: the destination is only known
                  // once the button is tapped, not when the page is built.
                  final auth = context.read<AuthProvider>();
                  context.go(auth.isSignedIn ? auth.homePath : '/login');
                },
                child: const Text('Take me back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
