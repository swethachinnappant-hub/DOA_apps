import 'package:ecommerce_app/core/business_config.dart';
import 'package:ecommerce_app/core/services/screenshot_protection_service.dart';
import 'package:ecommerce_app/features/config/providers/business_config_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The B2C storefront must let shoppers take screenshots: every default
/// board ships with `allowScreenshots` on, loading the config leaves the
/// protection service open, and the rules toggle still flips protection
/// both ways (`ScreenshotProtectionService.syncWithRule`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every default board allows screenshots', () {
    for (final type in BusinessType.values) {
      expect(
        BusinessConfig.getConfig(type).rules.allowScreenshots,
        isTrue,
        reason: '${type.name} board lets shoppers take screenshots',
      );
    }
  });

  test('loading the config leaves screenshots allowed', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = BusinessConfigProvider();
    await provider.load();
    expect(provider.config.rules.allowScreenshots, isTrue);

    // syncWithRule runs unawaited from the provider; let its platform hop
    // settle before reading the service's state.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ScreenshotProtectionService().isEnabled, isFalse);
  });

  test('the rules toggle flips screenshot protection both ways', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = BusinessConfigProvider();
    await provider.load();

    provider.updateSingleRule('allowScreenshots', false);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ScreenshotProtectionService().isEnabled, isTrue);

    provider.updateSingleRule('allowScreenshots', true);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(ScreenshotProtectionService().isEnabled, isFalse);
  });
}
