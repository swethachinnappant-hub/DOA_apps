import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/business_config.dart';
import '../../../core/models/user.dart';
import '../../config/providers/business_config_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_selector.dart';

/// Account creation for both roles.
///
/// The form is deliberately short: only what the role actually needs, with the
/// shop name appearing for sellers rather than making shoppers scroll past it.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _shopName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();

  UserRole _role = UserRole.customer;
  bool _busy = false;
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _shopName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _isOwner => _role == UserRole.owner;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _formError = null;
    });

    final error = auth.register(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      role: _role,
      shopName: _isOwner ? _shopName.text : null,
      address: _address.text,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _formError = error;
      });
      return;
    }

    await auth.flush();
    if (!mounted) return;
    setState(() => _busy = false);
    context.go(auth.homePath);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwner ? 'Open your shop' : 'Create account'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: Responsive.padding(context),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderBanner(config: config, role: _role),
                    SizedBox(height: Responsive.spacing(context, mobile: 24)),
                    RoleSelector(
                      role: _role,
                      config: config,
                      enabled: !_busy,
                      caption: _isOwner
                          ? 'You will list products and fulfil orders'
                          : 'You will browse and shop',
                      onChanged: (next) {
                        if (next == _role) return;
                        setState(() {
                          _role = next;
                          _formError = null;
                        });
                      },
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 24)),
                    if (_isOwner) ...[
                      AppTextField(
                        controller: _shopName,
                        label: 'Shop name',
                        hint: 'Chirag Associates',
                        prefixIcon: const Icon(Icons.storefront_outlined),
                        validator: AuthProvider.validateShopName,
                      ),
                      SizedBox(height: Responsive.spacing(context, mobile: 14)),
                    ],
                    AppTextField(
                      controller: _name,
                      label: _isOwner ? 'Your name' : 'Full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      textCapitalization: TextCapitalization.words,
                      validator: AuthProvider.validateName,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 14)),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone number',
                      hint: '98765 43210',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      keyboardType: TextInputType.phone,
                      validator: AuthProvider.validatePhone,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 14)),
                    AppTextField(
                      controller: _email,
                      label: 'Email (optional)',
                      prefixIcon: const Icon(Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      validator: AuthProvider.validateEmail,
                    ),
                    if (_isOwner) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 14)),
                      AppTextField(
                        controller: _address,
                        label: 'Shop address',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        maxLines: 2,
                      ),
                    ],
                    if (_formError != null) ...[
                      SizedBox(height: Responsive.spacing(context, mobile: 12)),
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                size: 16, color: Colors.red),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _formError!,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: Responsive.spacing(context, mobile: 24)),
                    AppButton(
                      text: _isOwner ? 'Open my shop' : 'Create account',
                      isLoading: _busy,
                      onPressed: _submit,
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Already registered? ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: Responsive.fontSize(context, mobile: 13),
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _busy ? null : () => context.go('/login'),
                          child: Text(
                            'Sign in',
                            style: TextStyle(
                              color: config.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  const _HeaderBanner({required this.config, required this.role});

  final BusinessConfig config;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Responsive.spacing(context, mobile: 16)),
      decoration: BoxDecoration(
        color: config.accentColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(role.icon, color: config.primaryColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  role == UserRole.owner
                      ? 'Open a shop on ${config.name}'
                      : 'Join ${config.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 16),
                    fontWeight: FontWeight.bold,
                    color: config.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 12),
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
