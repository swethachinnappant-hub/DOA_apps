import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses white surfaces and dark text', () {
      final theme = AppTheme.lightTheme();

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppPalette.background);
      expect(theme.colorScheme.surface, Colors.white);
      expect(theme.appBarTheme.backgroundColor, AppPalette.background);
      expect(theme.appBarTheme.foregroundColor, AppPalette.textPrimary);
      expect(theme.cardTheme.color, Colors.white);
    });

    test('light theme body text is near-black, not grey or white', () {
      final theme = AppTheme.lightTheme();
      final body = theme.textTheme.bodyMedium;

      expect(body?.color, isNotNull);
      expect(
        body!.color!.computeLuminance(),
        lessThan(0.2),
        reason: 'body text must be dark for contrast on white',
      );
    });

    test('honours a custom primary colour', () {
      const custom = Color(0xFF6A1B9A);
      final theme = AppTheme.lightTheme(primary: custom);

      expect(theme.colorScheme.primary, custom);
      expect(theme.colorScheme.surface, Colors.white);
    });

    test('custom colours still produce a light, white-surfaced theme', () {
      for (final primary in const [
        Color(0xFF6A1B9A),
        Color(0xFF0B5FA5),
        Color(0xFF00695C),
        Color(0xFFB71C1C),
      ]) {
        final theme = AppTheme.lightTheme(primary: primary);

        expect(theme.brightness, Brightness.light);
        expect(theme.scaffoldBackgroundColor, AppPalette.background);
        expect(theme.colorScheme.surface, Colors.white);
        expect(theme.colorScheme.primary, primary);
        expect(
          theme.textTheme.bodyMedium?.color!.computeLuminance(),
          lessThan(0.2),
        );
      }
    });
  });
}
