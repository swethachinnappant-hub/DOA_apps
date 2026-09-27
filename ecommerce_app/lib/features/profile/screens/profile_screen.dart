import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final name = user?.displayName ?? 'Guest';
    final subtitle = user == null
        ? 'Sign in to sync your orders'
        : user.role.label;
    final detail = user == null
        ? ''
        : [if (user.phone.isNotEmpty) user.phone, if (user.email.isNotEmpty) user.email]
            .join('  ·  ');

    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Header
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: config.primaryColor,
                  child: Text(
                    user?.initials ?? 'G',
                    style: TextStyle(
                      fontSize: 20,
                      color: config.onPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(subtitle, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (detail.isNotEmpty)
                        Text(detail, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          // Menu Items
          SectionHeader(title: 'Settings', padding: EdgeInsets.only(top: 16)),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          _menuItem(context, Icons.notifications_outlined, 'Notifications', config, () => context.push('/notifications')),
          _menuItem(context, Icons.security, 'Business Rules', config, () => context.push('/business-rules')),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          // Switch Business
          AppButton(
            text: 'Switch Business Type',
            color: config.secondaryColor,
            onPressed: () => context.push('/config'),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),

          // Logout
          AppButton(
            text: 'Logout',
            color: Colors.red,
            onPressed: () async {
              await context.read<AuthProvider>().signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, BusinessConfig config, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: config.primaryColor, size: 22),
            SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 14), fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
