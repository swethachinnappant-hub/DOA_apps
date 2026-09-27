import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:common_widgets/common_widgets.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final signedIn = await context.read<AuthProvider>().login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (mounted && signedIn) context.go('/app');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController(text: _emailController.text.trim());
    final formKey = GlobalKey<FormState>();
    final requested = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset password'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Account email'),
            validator: (value) => value != null && value.contains('@')
                ? null
                : 'Enter a valid email address',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    if (requested == true && mounted) {
      await context.read<AuthProvider>().resetPassword(email.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset request submitted')),
        );
      }
    }
    email.dispose();
  }

  Future<void> _loginWithOtp() async {
    final phone = TextEditingController();
    final code = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var codeSent = false;
    final authenticated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) => AlertDialog(
          title: Text(codeSent ? 'Verify code' : 'Sign in with OTP'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: codeSent ? code : phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: codeSent ? '6 digit code' : 'Phone number',
              ),
              validator: (value) {
                final text = value?.trim() ?? '';
                if (!codeSent &&
                    text.replaceAll(RegExp(r'\D'), '').length < 10) {
                  return 'Enter a valid phone number';
                }
                if (codeSent && !RegExp(r'^\d{6}$').hasMatch(text)) {
                  return 'Enter the 6 digit code';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final auth = context.read<AuthProvider>();
                if (!codeSent) {
                  await auth.loginWithOtp(phone.text.trim());
                  if (dialogContext.mounted) refresh(() => codeSent = true);
                } else {
                  final ok = await auth.verifyOtp(code.text.trim());
                  if (dialogContext.mounted) Navigator.pop(dialogContext, ok);
                }
              },
              child: Text(codeSent ? 'Verify and continue' : 'Send code'),
            ),
          ],
        ),
      ),
    );
    phone.dispose();
    code.dispose();
    if (authenticated == true && mounted) context.go('/app');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Responsive.isMobile(context)
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: Responsive.padding(context, mobile: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: Responsive.spacing(context, mobile: 40)),
            _buildLogo(),
            SizedBox(height: Responsive.spacing(context, mobile: 40)),
            _buildLoginForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: Theme.of(context).primaryColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  SizedBox(height: Responsive.spacing(context, mobile: 24)),
                  Text(
                    'AI Powered Accounting ERP',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(
                        context,
                        mobile: 18,
                        tablet: 20,
                      ),
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: Responsive.padding(context, mobile: 48),
              child: _buildLoginForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: Responsive.fontSize(context, mobile: 80, tablet: 90, desktop: 100),
      height: Responsive.fontSize(
        context,
        mobile: 80,
        tablet: 90,
        desktop: 100,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'CA',
          style: TextStyle(
            fontSize: Responsive.fontSize(
              context,
              mobile: 36,
              tablet: 40,
              desktop: 44,
            ),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return AppCard(
      padding: Responsive.padding(context, mobile: 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.headlineMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Login to your account',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 28)),
            AppTextField(
              label: 'Email',
              hint: 'Enter your email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(Icons.email_outlined, size: 20),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            AppTextField(
              label: 'Password',
              hint: 'Enter your password',
              controller: _passwordController,
              obscureText: _obscurePassword,
              prefixIcon: Icon(Icons.lock_outlined, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),
            AppButton(
              text: 'Login',
              isLoading: _isLoading,
              isExpanded: true,
              onPressed: _handleLogin,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: Responsive.horizontalPadding(context, mobile: 16),
                  child: Text('OR', style: TextStyle(color: Colors.grey[500])),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 16)),
            AppButton(
              text: 'Login with OTP',
              type: AppButtonType.outlined,
              icon: Icons.phone,
              isExpanded: true,
              onPressed: _loginWithOtp,
            ),
            SizedBox(height: Responsive.spacing(context, mobile: 20)),
            Center(
              child: Text(
                'New accounts are created by your company administrator.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
