import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/catalogue/screens/catalogue_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/wishlist/screens/wishlist_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/config/screens/business_config_screen.dart';
import '../../features/config/screens/business_rules_screen.dart';
import '../../features/main_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/config', builder: (context, state) => const BusinessConfigScreen()),
    GoRoute(path: '/app', builder: (context, state) => const MainScreen()),
    GoRoute(path: '/catalogue', builder: (context, state) => const CatalogueScreen()),
    GoRoute(path: '/product/:id', builder: (context, state) => const ProductDetailScreen()),
    GoRoute(path: '/wishlist', builder: (context, state) => const WishlistScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
    GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    GoRoute(path: '/order/:id', builder: (context, state) => const OrderDetailScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/business-rules', builder: (context, state) => const BusinessRulesScreen()),
  ],
);
