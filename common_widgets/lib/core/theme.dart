import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeMode _mode = ThemeMode.light;

  static ThemeMode get mode => _mode;

  static void setMode(ThemeMode mode) => _mode = mode;

  static ColorScheme buildColorScheme({
    required Color primary,
    required Color secondary,
    Color? accent,
  }) {
    final container = accent ?? primary.withValues(alpha: 0.08);
    return ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: container,
      onPrimaryContainer: AppPalette.textPrimary,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: container,
      onSecondaryContainer: AppPalette.textPrimary,
      tertiary: secondary,
      onTertiary: Colors.white,
      error: AppPalette.error,
      onError: Colors.white,
      surface: AppPalette.surface,
      onSurface: AppPalette.textPrimary,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppPalette.surfaceMuted,
      surfaceContainer: AppPalette.surfaceMuted,
      surfaceContainerHigh: AppPalette.surfaceMuted,
      surfaceContainerHighest: AppPalette.surfaceMuted,
      onSurfaceVariant: AppPalette.textSecondary,
      outline: AppPalette.border,
      outlineVariant: AppPalette.divider,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: AppPalette.textPrimary,
      onInverseSurface: Colors.white,
      inversePrimary: primary,
    );
  }

  static TextTheme _textTheme(Color primary) {
    return const TextTheme(
      displayLarge: AppTypography.display,
      displayMedium: AppTypography.display,
      displaySmall: AppTypography.title,
      headlineLarge: AppTypography.display,
      headlineMedium: AppTypography.title,
      headlineSmall: AppTypography.sectionTitle,
      titleLarge: AppTypography.title,
      titleMedium: AppTypography.subtitle,
      titleSmall: AppTypography.subtitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.caption,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.label,
      labelSmall: AppTypography.overline,
    );
  }

  static ThemeData lightTheme({
    Color primary = const Color(0xFF1E3A5F),
    Color secondary = const Color(0xFF3B82F6),
    Color? accent,
  }) {
    final scheme = buildColorScheme(primary: primary, secondary: secondary, accent: accent);
    return _base(scheme, primary: primary, secondary: secondary, accent: accent);
  }

  static ThemeData buildTheme({
    required Color primary,
    required Color secondary,
    Color? accent,
  }) {
    return lightTheme(primary: primary, secondary: secondary, accent: accent);
  }

  static ThemeData _base(
    ColorScheme scheme, {
    required Color primary,
    required Color secondary,
    Color? accent,
  }) {
    final container = accent ?? primary.withValues(alpha: 0.08);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
      canvasColor: AppPalette.background,
      textTheme: _textTheme(primary),
      primaryColor: primary,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.background,
        foregroundColor: AppPalette.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.title.copyWith(color: AppPalette.textPrimary),
        iconTheme: const IconThemeData(color: AppPalette.textPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: AppPalette.textPrimary, size: 22),
        shape: const Border(bottom: BorderSide(color: AppPalette.divider, width: 1)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.allMd,
          side: const BorderSide(color: AppPalette.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppPalette.textPrimary, size: 22),
      listTileTheme: const ListTileThemeData(
        iconColor: AppPalette.textPrimary,
        textColor: AppPalette.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppPalette.surfaceMuted,
        selectedColor: container,
        side: const BorderSide(color: AppPalette.border),
        labelStyle: AppTypography.label,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allPill),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.surfaceMuted,
        hintStyle: AppTypography.body.copyWith(color: AppPalette.textHint),
        labelStyle: AppTypography.caption,
        floatingLabelStyle: AppTypography.caption.copyWith(color: primary),
        prefixIconColor: AppPalette.textSecondary,
        suffixIconColor: AppPalette.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppPalette.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppPalette.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadius.allMd,
          borderSide: BorderSide(color: AppPalette.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppPalette.divider,
          disabledForegroundColor: AppPalette.textHint,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTypography.button,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.allSm),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppPalette.surface,
        selectedItemColor: primary,
        unselectedItemColor: AppPalette.textSecondary,
        selectedLabelStyle: AppTypography.label,
        unselectedLabelStyle: AppTypography.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: container,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTypography.label.copyWith(color: primary)
              : AppTypography.caption,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? primary : AppPalette.textSecondary,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allLg),
        titleTextStyle: AppTypography.title,
        contentTextStyle: AppTypography.bodyMuted,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
        showDragHandle: true,
        dragHandleColor: AppPalette.divider,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.textPrimary,
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        actionTextColor: secondary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allMd),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: AppPalette.surfaceMuted,
        circularTrackColor: AppPalette.surfaceMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : AppPalette.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : AppPalette.divider,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: AppPalette.border, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.allXs),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : AppPalette.textHint,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: AppPalette.divider,
        thumbColor: primary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppPalette.textPrimary,
          borderRadius: AppRadius.allSm,
        ),
        textStyle: AppTypography.caption.copyWith(color: Colors.white),
      ),
      splashColor: primary.withValues(alpha: 0.06),
      highlightColor: primary.withValues(alpha: 0.04),
    );
  }

  static TextStyle headingStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return AppTypography.display.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppPalette.textPrimary,
    );
  }

  static TextStyle subheadingStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return AppTypography.sectionTitle.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppPalette.textPrimary,
    );
  }

  static TextStyle bodyStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return AppTypography.body.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppPalette.textPrimary,
    );
  }

  static TextStyle captionStyle(BuildContext context, {double? size, FontWeight? weight, Color? color}) {
    return AppTypography.caption.copyWith(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppPalette.textSecondary,
    );
  }

  static BoxDecoration cardDecoration(BuildContext context, {double radius = AppRadius.md, List<BoxShadow>? shadow}) {
    return BoxDecoration(
      color: AppPalette.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppPalette.border),
      boxShadow: shadow ?? AppShadows.none,
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
      fillColor: AppPalette.surfaceMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppPalette.border),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.6),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: AppRadius.allMd,
        borderSide: BorderSide(color: AppPalette.error),
      ),
    );
  }
}
