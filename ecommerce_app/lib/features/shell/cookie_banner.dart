import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:common_widgets/common_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cookie notice strip (architecture §5.8) — web only, dismissal persisted.
class CookieBanner extends StatefulWidget {
  const CookieBanner({super.key});

  static const _prefsKey = 'cookie_banner_ack';

  @override
  State<CookieBanner> createState() => _CookieBannerState();
}

class _CookieBannerState extends State<CookieBanner> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    SharedPreferences.getInstance().then((prefs) {
      if (!mounted) return;
      setState(() {
        _visible = prefs.getBool(CookieBanner._prefsKey) ?? true;
      });
    });
  }

  Future<void> _dismiss() async {
    setState(() => _visible = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(CookieBanner._prefsKey, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      color: AppPalette.drawerSurface,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.pageInset(context),
        vertical: AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.cookie_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'We use cookies to optimise your visits. By continuing to '
                'browse our site you are accepting our cookie policy.',
                style: AppTypography.caption.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              onPressed: _dismiss,
              tooltip: 'Dismiss',
              icon: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
