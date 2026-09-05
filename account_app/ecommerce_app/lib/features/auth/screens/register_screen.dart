import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import 'package:common_widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _businessName = TextEditingController();
  final _ownerName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();
  final bool _isLoading = false;

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _gstin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    return Scaffold(
      appBar: AppBar(title: const Text('Retailer Registration')),
      body: SingleChildScrollView(
        padding: Responsive.padding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
              decoration: BoxDecoration(
                color: config.accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(config.icon, color: config.primaryColor, size: Responsive.fontSize(context, mobile: 32)),
                  SizedBox(width: Responsive.spacing(context, mobile: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Register as a Retailer', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold, color: config.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Get wholesale pricing & exclusive deals', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),
            AppTextField(controller: _businessName, label: 'Business Name', prefixIcon: Icon(Icons.business_outlined)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppTextField(controller: _ownerName, label: 'Owner Name', prefixIcon: Icon(Icons.person_outline)),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppTextField(controller: _phone, label: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined), keyboardType: TextInputType.phone),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppTextField(controller: _email, label: 'Email (Optional)', prefixIcon: Icon(Icons.email_outlined), keyboardType: TextInputType.emailAddress),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppTextField(controller: _address, label: 'Business Address', prefixIcon: Icon(Icons.location_on_outlined), maxLines: 2),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            AppTextField(controller: _gstin, label: 'GSTIN (Optional)', prefixIcon: Icon(Icons.receipt_long_outlined)),
            SizedBox(height: Responsive.spacing(context, mobile: 24)),
            AppButton(
              text: 'Submit Registration',
              isLoading: _isLoading,
              onPressed: () => context.go('/config'),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 12)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already registered? ', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 13))),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('Login', style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
