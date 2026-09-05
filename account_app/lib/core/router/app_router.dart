import 'package:go_router/go_router.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/main_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/purchase/screens/purchase_screen.dart';
import '../../features/banking/screens/banking_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/gst/screens/gst_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

final appRouter = GoRouter(
  // CHANGE initialLocation to jump directly to any screen for testing
  // Available routes: '/', '/login', '/app', '/dashboard', '/sales',
  //   '/purchase', '/banking', '/reports', '/gst', '/chat', '/clients', '/settings'
  initialLocation: '/app',
  routes: [
    // --- Auth Routes ---
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // --- Main Screen (all tabs) ---
    GoRoute(
      path: '/app',
      builder: (context, state) => const MainScreen(),
    ),

    // --- Individual Screens (use these for direct testing) ---
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesScreen(),
    ),
    GoRoute(
      path: '/purchase',
      builder: (context, state) => const PurchaseScreen(),
    ),
    GoRoute(
      path: '/banking',
      builder: (context, state) => const BankingScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/gst',
      builder: (context, state) => const GstScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/clients',
      builder: (context, state) => const ClientsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
