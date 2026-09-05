import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/providers/business_config_provider.dart';
import '../../../core/business_config.dart';
import 'package:common_widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
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
                  child: Text('CA', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Chirag Associates', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 16), fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Rajkot, Gujarat', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 12), color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('GSTIN: 24AABCC1234D1ZD', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 11), color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(icon: Icon(Icons.edit_outlined, color: config.primaryColor), onPressed: () {}),
              ],
            ),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          // Menu Items
          SectionHeader(title: 'Account', padding: EdgeInsets.only(top: 16)),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          _menuItem(context, Icons.person_outline, 'Edit Profile', config),
          _menuItem(context, Icons.location_on_outlined, 'Manage Addresses', config),
          _menuItem(context, Icons.payment_outlined, 'Payment Methods', config),
          _menuItem(context, Icons.receipt_long_outlined, 'Invoice History', config),
          SizedBox(height: Responsive.spacing(context, mobile: 20)),

          SectionHeader(title: 'Settings', padding: EdgeInsets.only(top: 16)),
          SizedBox(height: Responsive.spacing(context, mobile: 12)),
          _menuItem(context, Icons.security, 'Business Rules', config, onTap: () => context.push('/business-rules')),
          _menuItem(context, Icons.notifications_outlined, 'Notifications', config),
          _menuItem(context, Icons.language, 'Language', config),
          _menuItem(context, Icons.help_outline, 'Help & Support', config),
          _menuItem(context, Icons.info_outline, 'About', config),
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
            onPressed: () => context.go('/login'),
          ),
          SizedBox(height: Responsive.spacing(context, mobile: 24)),
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String title, BusinessConfig config, {VoidCallback? onTap}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap ?? () {},
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
