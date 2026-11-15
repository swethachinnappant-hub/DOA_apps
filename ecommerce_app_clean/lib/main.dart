import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/token_manager.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenManager.initialize();
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TokenManager.hasToken().then((hasToken) => setState(() => _hasToken = hasToken));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jewelry Store',
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: _hasToken ? const HomeScreen() : const AuthScreen(),
    );
  }
}