import 'package:flutter/material.dart';
import '../../shared/widgets/navigation_shell.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/sales/screens/sales_screen.dart';
import '../../features/purchase/screens/purchase_screen.dart';
import '../../features/banking/screens/banking_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/gst/screens/gst_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/clients/screens/clients_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<String> _titles = [
    'Dashboard',
    'Sales',
    'Purchase',
    'Banking',
    'Reports',
    'GST',
    'Chat',
    'Clients',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationShell(
      currentIndex: _currentIndex,
      onIndexChanged: (index) {
        setState(() => _currentIndex = index);
      },
      title: _titles[_currentIndex],
      actions: _currentIndex == 0
          ? [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {},
              ),
            ]
          : null,
      child: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          SalesScreen(),
          PurchaseScreen(),
          BankingScreen(),
          ReportsScreen(),
          GstScreen(),
          ChatScreen(),
          ClientsScreen(),
          SettingsScreen(),
        ],
      ),
    );
  }
}
