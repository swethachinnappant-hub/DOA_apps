import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/models/user.dart';
import '../../config/providers/business_config_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_selector.dart';

/// Entry point for both roles.
///
/// The role chosen here decides which navigation tree the router will allow,
/// so a seller never sees the shopping tabs and a buyer never sees the seller
/// console.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  UserRole _role = UserRole.customer;
  bool _otpSent = false;
  bool _busy = false;
  String? _formError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  BusinessConfig get _config => context.read<BusinessConfigProvider>().config;

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final error = auth.sendOtp(_phoneController.text);
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() {
      _busy = true;
      _formError = null;
    });
    // Stands in for the round trip to a real SMS gateway.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _otpSent = true;
      _otpController.clear();
    });
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final error = auth.verifyOtp(
      _phoneController.text,
      _otpController.text,
      role: _role,
    );
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    setState(() => _formError = null);
    _goHome();
  }

  Future<void> _skip() async {
    final auth = context.read<AuthProvider>();
    auth.signInAsDemo(_role);
    await auth.flush();
    if (!mounted) return;
    _goHome();
  }

  void _goHome() {
    final auth = context.read<AuthProvider>();
    context.go(auth.homePath);
  }

  void _switchRole(UserRole role) {
    if (_role == role) return;
    setState(() {
      _role = role;
      _formError = null;
      _otpSent = false;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    final isWide = Responsive.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: isWide
            ? Row(children: [
                Expanded(flex: 1, child: _BrandPanel(config: config)),
                Expanded(flex: 1, child: _buildForm(context, config)),
              ])
            : SingleChildScrollView(
                padding: Responsive.padding(context),
                child: _buildMobileForm(context, config),
              ),
      ),
    );
  }

  Widget _buildMobileForm(BuildContext context, BusinessConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: Responsive.spacing(context, mobile: 32)),
        Icon(config.icon,
            size: 56, color: config.primaryColor, semanticLabel: config.name),
        SizedBox(height: Responsive.spacing(context, mobile: 12)),
        Text(
          config.name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 24),
            fontWeight: FontWeight.bold,
            color: config.primaryColor,
          ),
        ),
        Text(
          config.tagline,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: Responsive.fontSize(context, mobile: 13),
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: Responsive.spacing(context, mobile: 28)),
        _buildForm(context, config),
      ],
    );
  }

  Widget _buildForm(BuildContext context, BusinessConfig config) {
    final spacing = Responsive.spacing(context, mobile: 16);
    return Center(
      child: ConstrainedBox(
        // Keeps the column readable on ultrawide monitors.
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context) ? 48 : 0,
            vertical: Responsive.spacing(context, mobile: 16),
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _otpSent ? 'Enter the code' : 'Sign in to ${config.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 6)),
                Text(
                  _otpSent
                      ? 'We sent a 6-digit code to ${_phoneController.text}'
                      : 'Choose how you want to use the app',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 13),
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 20)),
                RoleSelector(
                  role: _role,
                  enabled: !_busy,
                  config: config,
                  caption: 'Choose how you want to use the app',
                  onChanged: _switchRole,
                ),
                SizedBox(height: spacing),
                if (!_otpSent) ...[
                  AppTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    hint: '98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    validator: AuthProvider.validatePhone,
                    onFieldSubmitted: (_) => _sendOtp(),
                  ),
                  SizedBox(height: spacing),
                  AppButton(
                    text: 'Continue',
                    isLoading: _busy,
                    onPressed: _sendOtp,
                  ),
                ] else ...[
                  AppTextField(
                    controller: _otpController,
                    label: '6-digit code',
                    hint: AuthProvider.demoOtp,
                    prefixIcon: const Icon(Icons.lock_outline),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: AuthProvider.validateOtp,
                    onFieldSubmitted: (_) => _verify(),
                  ),
                  SizedBox(height: spacing / 2),
                  Text(
                    'Demo code: ${AuthProvider.demoOtp}',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 12),
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: spacing),
                  AppButton(
                    text: 'Verify & continue',
                    isLoading: _busy,
                    onPressed: _verify,
                  ),
                  SizedBox(height: Responsive.spacing(context, mobile: 12)),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _formError = null;
                              _otpController.clear();
                            }),
                    child: const Text('Change number'),
                  ),
                ],
                if (_formError != null) ...[
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
                  _FormError(message: _formError!),
                ],
                SizedBox(height: Responsive.spacing(context, mobile: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'New here? ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 13),
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy ? null : () => context.push('/register'),
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          color: config.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Responsive.spacing(context, mobile: 8)),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _skip,
                  icon: const Icon(Icons.explore_outlined, size: 18),
                  label: Text(
                    'Explore as ${_role.label.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// The shared, branded half of the desktop split.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.config});

  final BusinessConfig config;

  @override
  Widget build(BuildContext context) {
    final onPrimary = config.onPrimaryColor;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [config.primaryColor, config.secondaryColor],
        ),
      ),
      padding: const EdgeInsets.all(48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(config.icon, size: 72, color: onPrimary),
              const SizedBox(height: 24),
              Text(
                config.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: onPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                config.tagline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: onPrimary.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 32),
              _FeatureLine(icon: UserRole.customer.icon, label: 'Shop and track your orders'),
              const SizedBox(height: 14),
              _FeatureLine(icon: UserRole.owner.icon, label: 'List products and fulfil orders'),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _FormError extends StatelessWidget {
  const _FormError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Colors.red),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
