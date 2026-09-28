import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    Future.delayed(const Duration(milliseconds: 1600), _navigate);
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.scale(
              scale: _scaleUp.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppPalette.surface,
                      border: Border.all(color: AppPalette.border),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      config.icon,
                      size: Responsive.fontSize(
                        context,
                        mobile: 56,
                        tablet: 68,
                      ),
                      color: AppPalette.goldDark,
                    ),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 22)),
                  Text(
                    config.name.toUpperCase(),
                    style: AppTypography.title.copyWith(
                      fontSize: Responsive.fontSize(
                        context,
                        mobile: 18,
                        tablet: 21,
                      ),
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
                  Text(
                    config.tagline,
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      color: AppPalette.textSecondary,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 30)),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        config.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
