import 'package:ecommerce_app/core/business_config.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('royal palettes', () {
    test('there are presets to choose from', () {
      expect(BusinessConfig.colorOptions.length, greaterThanOrEqualTo(8));
    });

    test('preset names are unique and accents stay light', () {
      final names = BusinessConfig.colorOptions.map((o) => o.name).toList();
      expect(
        names.toSet().length,
        names.length,
        reason: 'duplicate palette names: $names',
      );

      for (final option in BusinessConfig.colorOptions) {
        // Accents fill image wells and soft surfaces, so they must stay pale
        // enough that product photography still reads on top of them.
        expect(
          option.accent.computeLuminance(),
          greaterThan(0.7),
          reason: '${option.name}: accent is too dark to use as a surface',
        );
      }
    });

    test('every preset yields readable text on its primary colour', () {
      for (final option in BusinessConfig.colorOptions) {
        final config = BusinessConfig.configs.values.first.copyWith(
          primaryColor: option.primary,
        );
        final onPrimary = config.onPrimaryColor;
        final ratio =
            (onPrimary.computeLuminance() + 0.05) /
            (option.primary.computeLuminance() + 0.05);

        expect(
          ratio,
          greaterThan(4.5),
          reason: '${option.name}: onPrimary is not readable on primary',
        );
      }
    });

    test('pale custom colours switch to dark text', () {
      final config = BusinessConfig.configs.values.first.copyWith(
        primaryColor: const Color(0xFFFFF176),
      );

      expect(config.onPrimaryColor, Colors.black);
      expect(config.getTheme().scaffoldBackgroundColor, AppPalette.background);
    });

    test('dark custom colours keep light text', () {
      final config = BusinessConfig.configs.values.first.copyWith(
        primaryColor: const Color(0xFF1A237E),
      );

      expect(config.onPrimaryColor, Colors.white);
    });

    test('every business type resolves to a config with that name', () {
      for (final type in BusinessType.values) {
        final config = BusinessConfig.getConfig(type);
        expect(config.name, isNotEmpty);
        expect(config.type, type);
      }
    });
  });

  group('BusinessConfigProvider persistence', () {
    late BusinessConfigProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = BusinessConfigProvider();
      await provider.load();
    });

    test('starts on a light theme with white scaffold', () {
      final theme = provider.config.getTheme();

      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppPalette.background);
      expect(provider.config.hasCustomColors, isFalse);
    });

    test('custom colours survive a restart', () async {
      const chosen = Color(0xFF6A1B9A);
      provider.updateColors(
        primaryColor: chosen,
        secondaryColor: const Color(0xFF00BFA5),
      );
      await provider.flush();

      expect(provider.config.primaryColor, chosen);
      expect(provider.config.hasCustomColors, isTrue);

      // Simulate an app restart.
      final reloaded = BusinessConfigProvider();
      await reloaded.load();

      expect(reloaded.config.primaryColor, chosen);
      expect(reloaded.config.secondaryColor, const Color(0xFF00BFA5));
      expect(
        reloaded.config.getTheme().scaffoldBackgroundColor,
        AppPalette.background,
      );
    });

    test('rapid colour changes persist the final value, not a mix', () async {
      provider.updateColors(primaryColor: const Color(0xFF6A1B9A));
      provider.updateColors(primaryColor: const Color(0xFF0B5FA5));
      provider.updateColors(primaryColor: const Color(0xFF00695C));
      await provider.flush();

      final reloaded = BusinessConfigProvider();
      await reloaded.load();

      expect(reloaded.config.primaryColor, const Color(0xFF00695C));
    });

    test(
      'applying a royal palette persists and reports custom colours',
      () async {
        final palette = BusinessConfig.colorOptions.first;
        provider.applyPalette(palette);
        await provider.flush();

        final reloaded = BusinessConfigProvider();
        await reloaded.load();

        expect(reloaded.config.primaryColor, palette.primary);
        expect(reloaded.config.secondaryColor, palette.secondary);
        expect(reloaded.config.accentColor, palette.accent);
      },
    );

    test('reset restores the default palette', () async {
      provider.updateColors(primaryColor: const Color(0xFF6A1B9A));
      await provider.flush();
      expect(provider.config.hasCustomColors, isTrue);

      provider.resetColors();
      await provider.flush();

      expect(provider.config.hasCustomColors, isFalse);
      expect(
        provider.config.primaryColor,
        BusinessConfig.getConfig(provider.config.type).primaryColor,
      );
    });

    test('selected business type is remembered', () async {
      final target = BusinessType.values.last;
      provider.setBusinessType(target);
      await provider.flush();

      final reloaded = BusinessConfigProvider();
      await reloaded.load();

      expect(reloaded.config.type, target);
      expect(reloaded.config.name, BusinessConfig.getConfig(target).name);
    });

    test('switching business type gives that type its own default colours', () {
      final first = provider.config.type;
      final other = BusinessType.values.firstWhere((t) => t != first);

      provider.setBusinessType(other);

      expect(
        provider.config.primaryColor,
        BusinessConfig.getConfig(other).primaryColor,
      );
      expect(
        provider.config.getTheme().scaffoldBackgroundColor,
        AppPalette.background,
      );
    });
  });
}
