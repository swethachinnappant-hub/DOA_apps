import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/business_config.dart';
import '../../../core/services/screenshot_protection_service.dart';

class BusinessConfigProvider extends ChangeNotifier {
  final ScreenshotProtectionService _screenshotService =
      ScreenshotProtectionService();

  static const String _kBusinessType = 'business_type';
  static const String _kPrimary = 'brand_primary';
  static const String _kSecondary = 'brand_secondary';
  static const String _kAccent = 'brand_accent';

  BusinessConfig _config = BusinessConfig.getConfig(BusinessType.jewellery);
  bool _loaded = false;

  BusinessConfig get config => _config;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeName = prefs.getString(_kBusinessType);
      final type = _decodeType(typeName) ?? _config.type;
      final base = BusinessConfig.getConfig(type);

      _config = base.copyWith(
        primaryColor: _decodeColor(prefs.getInt(_kPrimary)) ?? base.primaryColor,
        secondaryColor: _decodeColor(prefs.getInt(_kSecondary)) ?? base.secondaryColor,
        accentColor: _decodeColor(prefs.getInt(_kAccent)) ?? base.accentColor,
      );
    } catch (_) {
      _config = BusinessConfig.getConfig(BusinessType.jewellery);
    }
    _screenshotService.syncWithRule(_config.rules.allowScreenshots);
    _loaded = true;
    notifyListeners();
  }

  Future<void> _pendingWrite = Future<void>.value();

  /// Completes once every queued write has been flushed to disk.
  Future<void> flush() => _pendingWrite;

  /// Writes are queued so that rapid changes (e.g. dragging the colour picker)
  /// cannot interleave and persist a mix of old and new values.
  Future<void> _persist() {
    final snapshot = _config;
    _pendingWrite = _pendingWrite.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kBusinessType, snapshot.type.name);
        await prefs.setInt(_kPrimary, snapshot.primaryColor.toARGB32());
        await prefs.setInt(_kSecondary, snapshot.secondaryColor.toARGB32());
        await prefs.setInt(_kAccent, snapshot.accentColor.toARGB32());
      } catch (_) {}
    });
    return _pendingWrite;
  }

  static BusinessType? _decodeType(String? name) {
    if (name == null) return null;
    for (final type in BusinessType.values) {
      if (type.name == name) return type;
    }
    return null;
  }

  static Color? _decodeColor(int? value) {
    if (value == null) return null;
    return Color(value);
  }

  void setBusinessType(BusinessType type) {
    _config = BusinessConfig.getConfig(type);
    _screenshotService.syncWithRule(_config.rules.allowScreenshots);
    _persist();
    notifyListeners();
  }

  void updateColors({
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
  }) {
    _config = _config.copyWith(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      accentColor: accentColor,
    );
    _persist();
    notifyListeners();
  }

  void applyPalette(ColorPaletteOption palette) {
    updateColors(
      primaryColor: palette.primary,
      secondaryColor: palette.secondary,
      accentColor: palette.accent,
    );
  }

  void resetColors() {
    final base = _config.defaults;
    updateColors(
      primaryColor: base.primaryColor,
      secondaryColor: base.secondaryColor,
      accentColor: base.accentColor,
    );
  }

  void updateRules(BusinessRules rules) {
    _config = _config.copyWith(rules: rules);
    _screenshotService.syncWithRule(rules.allowScreenshots);
    _persist();
    notifyListeners();
  }

  void updateSingleRule(String ruleName, bool value) {
    final currentRules = _config.rules;
    BusinessRules newRules;

    switch (ruleName) {
      case 'allowScreenshots':
        newRules = currentRules.copyWith(allowScreenshots: value);
        break;
      case 'allowDownload':
        newRules = currentRules.copyWith(allowDownload: value);
        break;
      case 'allowShare':
        newRules = currentRules.copyWith(allowShare: value);
        break;
      case 'showWatermark':
        newRules = currentRules.copyWith(showWatermark: value);
        break;
      case 'showPrices':
        newRules = currentRules.copyWith(showPrices: value);
        break;
      case 'showContactInfo':
        newRules = currentRules.copyWith(showContactInfo: value);
        break;
      case 'allowPriceSharing':
        newRules = currentRules.copyWith(allowPriceSharing: value);
        break;
      case 'showMOQ':
        newRules = currentRules.copyWith(showMOQ: value);
        break;
      default:
        return;
    }

    _config = _config.copyWith(rules: newRules);

    if (ruleName == 'allowScreenshots') {
      _screenshotService.syncWithRule(value);
    }

    _persist();
    notifyListeners();
  }
}
