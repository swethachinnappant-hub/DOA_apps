import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/services/screenshot_protection_service.dart';
import 'features/config/providers/business_config_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final screenshotService = ScreenshotProtectionService();
  await screenshotService.initialize();

  runApp(const EcommerceApp());
}

class EcommerceApp extends StatelessWidget {
  const EcommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BusinessConfigProvider(),
      child: Consumer<BusinessConfigProvider>(
        builder: (context, configProvider, _) {
          final config = configProvider.config;
          return MaterialApp.router(
            title: config.name,
            debugShowCheckedModeBanner: false,
            theme: config.getTheme(brightness: Brightness.light),
            darkTheme: config.getTheme(brightness: Brightness.dark),
            themeMode: ThemeMode.system,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
