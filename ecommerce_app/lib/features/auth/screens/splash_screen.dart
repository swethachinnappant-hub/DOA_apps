import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/business_config.dart';
import '../../config/providers/business_config_provider.dart';
import '../providers/auth_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    _navigationTimer = Timer(const Duration(milliseconds: 1600), _navigate);
  }

  /// Lands returning users in their workspace and new users at sign in.
  Future<void> _navigate() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();

    // Give the stored session a moment to be read back, but never hang here.
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (auth.isRestoring && mounted && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (!mounted) return;

    context.go(auth.isSignedIn ? auth.homePath : '/login');
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    return Scaffold(
      backgroundColor: AppPalette.textPrimary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fadeIn.value,
          child: Transform.scale(
            scale: _scaleUp.value,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (config.type == BusinessType.jewellery)
                  const ProductImageTile(
                    url: 'assets/demo_jewellery/bridal_set.png',
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.diamond_outlined,
                    placeholderColor: Color(0xFF211D17),
                    placeholderAccent: Color(0xFFD8C39A),
                  )
                else
                  ColoredBox(color: config.primaryColor),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55000000),
                        Color(0x22000000),
                        Color(0xE6000000),
                      ],
                      stops: [0, .42, 1],
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 700;
                      final compactHeight = constraints.maxHeight < 500;
                      final horizontal = wide ? 72.0 : 28.0;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          28,
                          horizontal,
                          38,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .36),
                                borderRadius: AppRadius.allPill,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    config.icon,
                                    size: 17,
                                    color: const Color(0xFFE4D6B7),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    config.name.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 620),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FINE JEWELLERY  ·  THOUGHTFULLY CHOSEN',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.overline.copyWith(
                                      color: const Color(0xFFE4D6B7),
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 7 : 12),
                                  Text(
                                    'Made to be\ntreasured.',
                                    style: AppTypography.display.copyWith(
                                      color: Colors.white,
                                      fontSize: compactHeight
                                          ? 34
                                          : wide
                                          ? 56
                                          : 42,
                                      height: 1.02,
                                      letterSpacing: -1.4,
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 7 : 12),
                                  Text(
                                    config.tagline,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.body.copyWith(
                                      color: Colors.white.withValues(alpha: .8),
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 12 : 25),
                                  Row(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 1,
                                        color: const Color(0xFFD8C39A),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Color(0xFFD8C39A)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'PREPARING YOUR EXPERIENCE',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.overline
                                              .copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: .7,
                                                ),
                                                fontSize: 9,
                                                letterSpacing: 1.3,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
