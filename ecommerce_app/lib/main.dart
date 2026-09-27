import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/demo_catalog.dart';
import 'core/router/app_router.dart';
import 'core/services/screenshot_protection_service.dart';
import 'core/store/commerce_store.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/config/providers/business_config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  final screenshotService = ScreenshotProtectionService();
  await screenshotService.initialize();

  runApp(const EcommerceApp());
}

class EcommerceApp extends StatefulWidget {
  const EcommerceApp({super.key});

  @override
  State<EcommerceApp> createState() => _EcommerceAppState();
}

class _EcommerceAppState extends State<EcommerceApp> {
  late final BusinessConfigProvider _configProvider;
  late final AuthProvider _authProvider;
  late final CommerceStore _store;
  late final GoRouter _router;

  String _seededCategories = '';

  @override
  void initState() {
    super.initState();
    _configProvider = BusinessConfigProvider()..load();
    _authProvider = AuthProvider()..restore();
    _store = CommerceStore();
    _router = buildAppRouter(auth: _authProvider);

    // The catalogue is derived from the chosen business type, so it is
    // rebuilt whenever that type changes.
    _configProvider.addListener(_syncCatalog);
    _syncCatalog();
  }

  void _syncCatalog() {
    if (!_configProvider.isLoaded) return;
    final categories = _configProvider.config.categories;
    final key = categories.join('|');
    if (key == _seededCategories) return;
    _seededCategories = key;
    _store.seedProducts(DemoCatalog.build(categories));
  }

  @override
  void dispose() {
    _configProvider.removeListener(_syncCatalog);
    _router.dispose();
    _store.dispose();
    _authProvider.dispose();
    _configProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BusinessConfigProvider>.value(
          value: _configProvider,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<CommerceStore>.value(value: _store),
      ],
      child: Consumer<BusinessConfigProvider>(
        builder: (context, configProvider, _) {
          final config = configProvider.config;
          return MaterialApp.router(
            title: config.name,
            debugShowCheckedModeBanner: false,
            theme: config.getTheme(),
            themeMode: ThemeMode.light,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
