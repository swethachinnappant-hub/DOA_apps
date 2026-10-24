import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/sign_out_action.dart';
import '../../config/providers/business_config_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  void _showMyProfile(BuildContext context, AppUser? user) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('My Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user?.displayName ?? 'Guest account',
                style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.sm),
            if (user?.phone.isNotEmpty ?? false)
              Text(user!.phone, style: AppTypography.bodyMuted),
            if (user?.email.isNotEmpty ?? false)
              Text(user!.email, style: AppTypography.bodyMuted),
            const SizedBox(height: AppSpacing.sm),
            Text(
              user?.role.label ?? 'Guest',
              style: AppTypography.caption,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rules = context.watch<BusinessConfigProvider>().config.rules;
    final isOwner = user?.role == UserRole.owner;
    final details = [
      if (user?.phone.isNotEmpty ?? false) user!.phone,
      if (user?.email.isNotEmpty ?? false) user!.email,
    ].join('  ·  ');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: showAppBar ? AppBar(title: const Text('Your account')) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: Responsive.padding(context),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF171717),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: Colors.white.withValues(alpha: .12),
                      foregroundColor: const Color(0xFFE4D6B7),
                      child: Text(
                        user?.initials ?? 'G',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Guest account',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            details.isEmpty
                                ? (user == null
                                      ? 'Sign in to keep your orders together'
                                      : user.role.label)
                                : details,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .68),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text('ACCOUNT', style: AppTypography.overline),
              const SizedBox(height: 10),
              _AccountAction(
                icon: Icons.person_outline_rounded,
                title: 'My Profile',
                subtitle: 'Name, phone and email',
                onTap: () => _showMyProfile(context, user),
              ),
              _AccountAction(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Order updates and shop messages',
                onTap: () => context.push('/notifications'),
              ),
              _AccountAction(
                icon: Icons.help_outline_rounded,
                title: 'Help',
                subtitle: 'Frequently asked questions',
                onTap: () => context.push('/faq'),
              ),
              if (!isOwner) ...[
                const SizedBox(height: 30),
                Text('YOUR SHOPPING', style: AppTypography.overline),
                const SizedBox(height: 10),
                _AccountAction(
                  icon: Icons.receipt_long_outlined,
                  title: 'My Orders',
                  subtitle: 'Track, download or reorder',
                  onTap: () => context.push('/orders'),
                ),
                _AccountAction(
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  subtitle: 'Where we deliver',
                  onTap: () => context.push('/addresses'),
                ),
                _AccountAction(
                  icon: Icons.favorite_border_rounded,
                  title: 'Wishlist',
                  subtitle: 'Your saved pieces',
                  onTap: () => context.go('/wishlist'),
                ),
                _AccountAction(
                  icon: Icons.stars_outlined,
                  title: 'Loyalty Points',
                  subtitle: 'Club Loyal balance and ledger',
                  onTap: () => context.push('/loyalty'),
                ),
                if (rules.coupons)
                  _AccountAction(
                    icon: Icons.local_offer_outlined,
                    title: 'Coupons',
                    subtitle: 'Codes ready to apply',
                    onTap: () => context.push('/coupons'),
                  ),
              ],
              const SizedBox(height: 30),
              Divider(color: scheme.outlineVariant),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFF8A4943),
                ),
                title: const Text('Sign out'),
                subtitle: const Text('Sign out of this account on this device'),
                onTap: () => confirmSignOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 15),
            child: Row(
              children: [
                Icon(icon, size: 21, color: AppPalette.textSecondary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.subtitle),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppPalette.textHint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
