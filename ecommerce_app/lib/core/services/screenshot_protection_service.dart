import 'package:no_screenshot/no_screenshot.dart';

class ScreenshotProtectionService {
  static final ScreenshotProtectionService _instance =
      ScreenshotProtectionService._();
  factory ScreenshotProtectionService() => _instance;
  ScreenshotProtectionService._();

  final NoScreenshot _noScreenshot = NoScreenshot.instance;
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  Future<void> initialize() async {
    await _preventScreenshots();
    _isEnabled = true;
  }

  Future<void> syncWithRule(bool allowScreenshots) async {
    if (allowScreenshots) {
      await _allowScreenshots();
      _isEnabled = false;
    } else {
      await _preventScreenshots();
      _isEnabled = true;
    }
  }

  Future<void> _preventScreenshots() async {
    try {
      await _noScreenshot.screenshotOff();
    } catch (_) {}
  }

  Future<void> _allowScreenshots() async {
    try {
      await _noScreenshot.screenshotOn();
    } catch (_) {}
  }
}
