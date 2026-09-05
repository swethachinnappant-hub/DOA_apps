import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)));
    _scaleUp = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/config');
    });
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
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [config.primaryColor, config.secondaryColor],
          ),
        ),
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
                    padding: EdgeInsets.all(Responsive.spacing(context, mobile: 24)),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(config.icon, size: Responsive.fontSize(context, mobile: 60, tablet: 80), color: Colors.white),
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 24)),
                  Text(config.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 28, tablet: 36), fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
                  Text(config.tagline, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14, tablet: 16), color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                  SizedBox(height: Responsive.spacing(context, mobile: 40)),
                  SizedBox(
                    width: Responsive.spacing(context, mobile: 24),
                    height: Responsive.spacing(context, mobile: 24),
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
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
