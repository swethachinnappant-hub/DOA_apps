import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:common_widgets/common_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Responsive.fontSize(context, mobile: 100, tablet: 120, desktop: 140),
                  height: Responsive.fontSize(context, mobile: 100, tablet: 120, desktop: 140),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Center(
                    child: Text('CA', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 40, tablet: 48, desktop: 56), fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 24)),
                Text('Chirag Associates', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 24, tablet: 30, desktop: 34), fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: Responsive.spacing(context, mobile: 8)),
                Text('AI Powered Accounting ERP', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12, tablet: 16), color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: Responsive.spacing(context, mobile: 40)),
                SizedBox(
                  width: 40, height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
