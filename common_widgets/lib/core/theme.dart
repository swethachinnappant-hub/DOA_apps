import 'package:flutter/material.dart';

class AppColors {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color divider;
  final Color border;
  final Color shimmerBase;
  final Color shimmerHighlight;

  const AppColors({
    this.primary = const Color(0xFF1E3A5F),
    this.primaryLight = const Color(0xFF3A6B9F),
    this.primaryDark = const Color(0xFF0F1F33),
    this.secondary = const Color(0xFF2196F3),
    this.success = const Color(0xFF4CAF50),
    this.warning = const Color(0xFFFF9800),
    this.error = const Color(0xFFE53935),
    this.info = const Color(0xFF2196F3),
    this.background = const Color(0xFFF5F7FA),
    this.surface = Colors.white,
    this.card = Colors.white,
    this.textPrimary = const Color(0xFF212121),
    this.textSecondary = const Color(0xFF757575),
    this.textHint = const Color(0xFFBDBDBD),
    this.divider = const Color(0xFFE0E0E0),
    this.border = const Color(0xFFE0E0E0),
    this.shimmerBase = const Color(0xFFE0E0E0),
    this.shimmerHighlight = const Color(0xFFF5F5F5),
  });

  static const light = AppColors();
  static const dark = AppColors(
    primary: Color(0xFF64B5F6),
    primaryLight: Color(0xFF9BE7FF),
    primaryDark: Color(0xFF2286D4),
    secondary: Color(0xFF64B5F6),
    success: Color(0xFF66BB6A),
    warning: Color(0xFFFFB74D),
    error: Color(0xFFEF5350),
    info: Color(0xFF64B5F6),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    card: Color(0xFF1E1E1E),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFF9E9E9E),
    textHint: Color(0xFF616161),
    divider: Color(0xFF333333),
    border: Color(0xFF333333),
    shimmerBase: Color(0xFF333333),
    shimmerHighlight: Color(0xFF444444),
  );
}

class AppTheme {
  static ThemeMode _mode = ThemeMode.system;

  static ThemeMode get mode => _mode;

  static void setMode(ThemeMode mode) => _mode = mode;

  static TextStyle headingStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return TextStyle(
      fontSize: size ?? 24,
      fontWeight: weight ?? FontWeight.bold,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );
  }

  static TextStyle subheadingStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return TextStyle(
      fontSize: size ?? 18,
      fontWeight: weight ?? FontWeight.w600,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1.3,
    );
  }

  static TextStyle bodyStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return TextStyle(
      fontSize: size ?? 14,
      fontWeight: weight ?? FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurface,
      height: 1.5,
    );
  }

  static TextStyle captionStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return TextStyle(
      fontSize: size ?? 12,
      fontWeight: weight ?? FontWeight.normal,
      color: color ?? Theme.of(context).colorScheme.onSurfaceVariant,
      height: 1.4,
    );
  }

  static BoxDecoration cardDecoration(BuildContext context, {double radius = 12, List<BoxShadow>? shadow}) {
    return BoxDecoration(
      color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ?? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static InputDecoration inputDecoration(BuildContext context, {
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1E3A5F),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E3A5F),
          side: const BorderSide(color: Color(0xFF1E3A5F)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF1E3A5F),
        unselectedItemColor: Color(0xFF757575),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF64B5F6),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF64B5F6),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
