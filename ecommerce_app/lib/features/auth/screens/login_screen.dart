import 'dart:async';

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
      backgroundColor: const Color(0xFFF5F1EA),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 1, child: _BrandPanel(config: config)),
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: _buildForm(context, config),
                    ),
                  ),
                ],
              )
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
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 22),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1E6D3),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD8C3A0)),
                ),
                child: Icon(config.icon, color: AppPalette.goldDark, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.title.copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'FINE JEWELLERY',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.7,
                        color: Color(0xFF85765F),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.verified_outlined,
                color: AppPalette.goldDark,
                size: 19,
              ),
            ],
          ),
        ),
        Container(
          height: Responsive.isTablet(context) ? 190 : 172,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E9DC),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 4, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THE ART OF GOLD',
                        style: TextStyle(
                          color: Color(0xFF866D47),
                          fontSize: 9,
                          letterSpacing: 1.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gold, made\npersonal.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.display.copyWith(
                          fontSize: 23,
                          height: 1.06,
                          color: const Color(0xFF342B20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(flex: 5, child: _JewelleryGallery(config: config)),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          _otpSent ? 'Verify your number' : 'Welcome back',
          style: AppTypography.headline.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF29241D),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _otpSent
              ? 'Enter the code sent to ${_phoneController.text}'
              : 'Sign in to discover your next favourite piece.',
          style: AppTypography.body.copyWith(
            fontSize: 13,
            color: const Color(0xFF777169),
          ),
        ),
        const SizedBox(height: 15),
        _buildForm(context, config, framed: false),
      ],
    );
  }

  Widget _buildForm(
    BuildContext context,
    BusinessConfig config, {
    bool framed = true,
  }) {
    final spacing = Responsive.spacing(context, mobile: 16);
    return Center(
      child: ConstrainedBox(
        // Keeps the column readable on ultrawide monitors.
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: EdgeInsets.all(
            framed ? (Responsive.isDesktop(context) ? 30 : 18) : 0,
          ),
          decoration: BoxDecoration(
            color: framed ? const Color(0xFFFFFEFC) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: framed ? Border.all(color: const Color(0xFFEAE3D8)) : null,
            boxShadow: framed
                ? const [
                    BoxShadow(
                      color: Color(0x180D0B08),
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: framed && Responsive.isDesktop(context) ? 18 : 0,
              vertical: framed ? Responsive.spacing(context, mobile: 8) : 0,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (framed && !_otpSent) ...[
                    Text(
                      'THE DOOR TO YOUR COLLECTION',
                      style: AppTypography.overline.copyWith(
                        color: AppPalette.goldDark,
                        fontSize: 9,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 7),
                  ],
                  if (framed) ...[
                    Text(
                      _otpSent ? 'Enter the code' : 'Welcome back',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headline.copyWith(
                        fontSize: Responsive.fontSize(context, mobile: 27),
                        fontWeight: FontWeight.w400,
                        letterSpacing: -.6,
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 6)),
                    Text(
                      _otpSent
                          ? 'We sent a 6-digit code to ${_phoneController.text}'
                          : 'Sign in, or explore the collection as a guest.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, mobile: 13),
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: Responsive.spacing(context, mobile: 20)),
                  ],
                  RoleSelector(
                    role: _role,
                    enabled: !_busy,
                    config: config,
                    caption: 'CONTINUE AS',
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
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 2,
                    children: [
                      Text(
                        'New here?',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 13),
                          color: Colors.grey[600],
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => context.push('/register'),
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
      ),
    );
  }
}

class _JewelleryGallery extends StatefulWidget {
  const _JewelleryGallery({required this.config});

  final BusinessConfig config;

  @override
  State<_JewelleryGallery> createState() => _JewelleryGalleryState();
}

class _JewelleryGalleryState extends State<_JewelleryGallery> {
  static const _images = [
    'assets/demo_jewellery/bridal_set.png',
    'assets/demo_jewellery/bridal_necklace.png',
    'assets/demo_jewellery/gold_earrings.png',
    'assets/demo_jewellery/gold_bangles.png',
    'assets/demo_jewellery/gold_pendant.png',
  ];

  final _controller = PageController();
  Timer? _timer;
  int _page = 0;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || _dragging) return;
      final next = (_page + 1) % _images.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: const Color(0xFFF1E9DC),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    notification.dragDetails != null) {
                  _dragging = true;
                  _timer?.cancel();
                } else if (notification is ScrollEndNotification && _dragging) {
                  _dragging = false;
                  _startTimer();
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: _images.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => Image.asset(
                  _images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => Icon(
                    Icons.diamond_outlined,
                    color: widget.config.primaryColor,
                    size: 42,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: active ? 14 : 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? widget.config.primaryColor
                          : widget.config.primaryColor.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
          ],
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
    return ColoredBox(
      color: const Color(0xFFF3EBDD),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 36, 44, 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7D9C2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD1BC98)),
                  ),
                  child: Icon(config.icon, color: AppPalette.goldDark),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    config.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.title.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF30291F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'FINE GOLD  ·  DIAMONDS  ·  SILVER',
              style: TextStyle(
                color: Color(0xFF887657),
                fontSize: 9,
                letterSpacing: 1.3,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 510),
                  child: _JewelleryGallery(config: config),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Find the piece\nthat feels like you.',
              style: AppTypography.display.copyWith(
                fontSize: 37,
                height: 1.08,
                color: const Color(0xFF30291F),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              config.tagline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body.copyWith(
                fontSize: 14,
                color: const Color(0xFF71685B),
              ),
            ),
          ],
        ),
      ),
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
