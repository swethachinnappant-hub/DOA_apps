import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final isWide = Responsive.isDesktop(context);

    return Scaffold(
      body: isWide ? _buildWideLayout(context, config) : _buildMobileLayout(context, config),
    );
  }

  Widget _buildWideLayout(BuildContext context, BusinessConfig config) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [config.primaryColor, config.secondaryColor]),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(config.icon, size: Responsive.fontSize(context, mobile: 80), color: Colors.white),
                  SizedBox(height: Responsive.spacing(context, mobile: 24)),
                  Text(config.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 32), fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
                  Text(config.tagline, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: _buildForm(context, config),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, BusinessConfig config) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          children: [
            SizedBox(height: Responsive.spacing(context, mobile: 40)),
            Icon(config.icon, size: 60, color: config.primaryColor),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            Text(config.name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 24), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: Responsive.spacing(context, mobile: 8)),
            Text(config.tagline, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
            SizedBox(height: Responsive.spacing(context, mobile: 32)),
            _buildForm(context, config),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, BusinessConfig config) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.isDesktop(context) ? 48 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_otpSent ? 'Enter OTP' : 'Login to ${config.name}', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 20), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: Responsive.spacing(context, mobile: 24)),
          if (!_otpSent) ...[
            AppTextField(
              controller: _phoneController,
              label: 'Phone Number',
              prefixIcon: Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            AppButton(
              text: 'Send OTP',
              isLoading: _isLoading,
              onPressed: () {
                setState(() { _otpSent = true; _isLoading = false; });
              },
            ),
          ] else ...[
            AppTextField(
              controller: _otpController,
              label: 'Enter 6-digit OTP',
              prefixIcon: Icon(Icons.lock_outline),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            AppButton(
              text: 'Verify & Login',
              isLoading: _isLoading,
              onPressed: () => context.go('/app'),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            TextButton(
              onPressed: () => setState(() => _otpSent = false),
              child: Text('Change Number'),
            ),
          ],
          SizedBox(height: Responsive.spacing(context, mobile: 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ", style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13), color: Colors.grey[600])),
              TextButton(
                onPressed: () => context.push('/register'),
                child: Text('Register as Retailer', style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          TextButton(
            onPressed: () => context.go('/app'),
            child: Text('Skip for Demo', style: TextStyle(color: Colors.grey[500])),
          ),
        ],
      ),
    );
  }
}
