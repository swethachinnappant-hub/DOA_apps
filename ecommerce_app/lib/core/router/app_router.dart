import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/catalogue/screens/catalogue_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/config/screens/business_config_screen.dart';
import '../../features/config/screens/business_rules_screen.dart';
import '../../features/main_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/owner/screens/owner_categories_screen.dart';
import '../../features/owner/screens/owner_collections_screen.dart';
import '../../features/owner/screens/owner_coupons_screen.dart';
import '../../features/owner/screens/owner_customers_screen.dart';
import '../../features/owner/screens/owner_dashboard_screen.dart';
import '../../features/owner/screens/owner_gold_rate_screen.dart';
import '../../features/owner/screens/owner_home_builder_screen.dart';
import '../../features/owner/screens/owner_order_detail_screen.dart';
import '../../features/owner/screens/owner_orders_screen.dart';
import '../../features/owner/screens/owner_product_form_screen.dart';
import '../../features/owner/screens/owner_products_screen.dart';
import '../../features/owner/screens/owner_shell.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/profile/screens/addresses_screen.dart';
import '../../features/profile/screens/coupons_screen.dart';
import '../../features/profile/screens/loyalty_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/section_screen.dart';
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

/// Root navigator key shared by overlays (search, mini-cart) that must open
/// from app-level keyboard shortcuts above any route.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Builds the router with a role guard bound to [auth].
///
/// `refreshListenable` is the important part: when someone signs in or out,
/// every route in flight is re-evaluated, so a customer who taps a bookmarked
/// `/owner/...` link is sent to their own home instead of seeing a seller
/// screen they have no business seeing.
GoRouter buildAppRouter({required AuthProvider auth}) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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

      // ----------------------------------------------- seller console pages
      // SPEC-18 storefront management: pushed full-screen from the shell's
      // sidebar / "More" sheet, owner-only via the `/owner` guard below.
      GoRoute(
        path: '/owner/categories',
        builder: (context, state) => const OwnerCategoriesScreen(),
      ),
      GoRoute(
        path: '/owner/collections',
        builder: (context, state) => const OwnerCollectionsScreen(),
      ),
      GoRoute(
        path: '/owner/home-builder',
        builder: (context, state) => const OwnerHomeBuilderScreen(),
      ),
      GoRoute(
        path: '/owner/coupons',
        builder: (context, state) => const OwnerCouponsScreen(),
      ),
      GoRoute(
        path: '/owner/gold-rate',
        builder: (context, state) => const OwnerGoldRateScreen(),
      ),
      GoRoute(
        path: '/owner/customers',
        builder: (context, state) => const OwnerCustomersScreen(),
      ),

      // ---------------------------------------------------------- storefront
      GoRoute(path: '/app', builder: (context, state) => const MainScreen()),
      GoRoute(
        path: '/catalogue',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return CatalogueScreen(
            initialCategory: query['category'],
            initialQuery: query['search'],
            priceMin: int.tryParse(query['min'] ?? ''),
            priceMax: int.tryParse(query['max'] ?? ''),
            initialMetal: query['metal'],
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
        path: '/order-success/:id',
        builder: (context, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(showAppBar: true),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/loyalty',
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/coupons',
        builder: (context, state) => const CouponsScreen(),
      ),

      // ------------------------------------------- §4.3 alias & band paths
      GoRoute(
        path: '/shopping-cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const ProfileScreen(showAppBar: true),
      ),
      // INR price bands feed the existing query-string PLP (rule 4), so a
      // band deep link keeps filter/sort/refresh behaviour for free.
      GoRoute(
        path: '/20k-products',
        builder: (context, state) => const CatalogueScreen(priceMax: 20000),
      ),
      GoRoute(
        path: '/30k-products',
        builder: (context, state) => const CatalogueScreen(priceMax: 30000),
      ),
      GoRoute(
        path: '/50k-products',
        builder: (context, state) => const CatalogueScreen(priceMax: 50000),
      ),
      GoRoute(
        path: '/above-50k',
        builder: (context, state) => const CatalogueScreen(priceMin: 50001),
      ),
      // Legacy USD bands (US locale) redirect to the nearest INR band.
      GoRoute(
        path: '/500-dollar-products',
        redirect: (context, state) => '/50k-products',
      ),
      GoRoute(
        path: '/1000-dollar-products',
        redirect: (context, state) => '/above-50k',
      ),
      GoRoute(
        path: '/2000-dollar-products',
        redirect: (context, state) => '/above-50k',
      ),
      GoRoute(
        path: '/above-2000-dollar-products',
        redirect: (context, state) => '/above-50k',
      ),
      // Footer extra: the old product list is the PLP itself.
      GoRoute(
        path: '/product-list',
        redirect: (context, state) => '/catalogue',
      ),

      // --------------------------------------------- catch-all shop paths
      // Declared last so every explicit route above wins the match. These
      // cover the verified kirtilals.com slugs (/diamond-earrings/studs and
      // friends): known paths render a section landing, the rest the
      // designed 404 (§10.8) — both still pass through the role guard.
      GoRoute(
        path: '/:slug',
        builder: (context, state) =>
            SectionScreen(path: state.matchedLocation),
      ),
      GoRoute(
        path: '/:slug/:facet',
        builder: (context, state) =>
            SectionScreen(path: state.matchedLocation),
      ),
      GoRoute(
        path: '/:slug/:facet/:sub',
        builder: (context, state) =>
            SectionScreen(path: state.matchedLocation),
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
