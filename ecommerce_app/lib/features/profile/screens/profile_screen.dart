import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/sign_out_action.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
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
                padding: const EdgeInsets.all(24),
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
              Text('ACCOUNT & PREFERENCES', style: AppTypography.overline),
              const SizedBox(height: 10),
              _AccountAction(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Order updates and shop messages',
                onTap: () => context.push('/notifications'),
              ),
              if (!isOwner) ...[
                const SizedBox(height: 30),
                Text('YOUR SHOPPING', style: AppTypography.overline),
                const SizedBox(height: 10),
                _AccountAction(
                  icon: Icons.favorite_border_rounded,
                  title: 'Saved pieces',
                  subtitle: 'Your jewellery wishlist',
                  onTap: () => context.go('/wishlist'),
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
