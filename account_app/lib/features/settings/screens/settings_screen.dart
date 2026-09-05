import 'package:flutter/material.dart';
import '../../../core/responsive.dart';
import '../../../shared/widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ? _buildSkeleton() : _buildContent();
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SkeletonCard(height: 120),
          SizedBox(height: 16),
          const SkeletonCard(height: 300),
          SizedBox(height: 16),
          const SkeletonCard(height: 250),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: Responsive.padding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileSection(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildGeneralSettings(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildSecuritySettings(),
          SizedBox(height: Responsive.spacing(context, mobile: 16)),
          _buildSupportSection(),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Admin User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('admin@chiragassociates.com', style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Super Admin', style: TextStyle(fontSize: Responsive.fontSize(context, mobile: 10), color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          IconAppButton(icon: Icons.edit, onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'General Settings'),
          const SizedBox(height: 8),
          _buildSettingItem(Icons.business, 'Company Profile', 'Manage company details'),
          _buildSettingItem(Icons.language, 'Language', 'English'),
          _buildSettingItem(Icons.notifications, 'Notifications', 'Manage notification preferences'),
          _buildSettingItem(Icons.palette, 'Theme', 'Light Mode'),
          _buildSettingItem(Icons.backup, 'Backup & Restore', 'Cloud backup settings'),
        ],
      ),
    );
  }

  Widget _buildSecuritySettings() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Security'),
          const SizedBox(height: 8),
          _buildSettingItem(Icons.lock, 'Change Password', 'Update your password'),
          _buildSettingItem(Icons.security, 'Two-Factor Authentication', 'Enabled'),
          _buildSettingItem(Icons.fingerprint, 'Biometric Login', 'Enabled'),
          _buildSettingItem(Icons.history, 'Activity Log', 'View login history'),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Support & About'),
          const SizedBox(height: 8),
          _buildSettingItem(Icons.help, 'Help & Support', 'FAQs, Contact Support'),
          _buildSettingItem(Icons.info, 'About', 'Version 1.0.0'),
          _buildSettingItem(Icons.share, 'Share App', 'Share with friends'),
          _buildSettingItem(Icons.star_rate, 'Rate Us', 'Rate on Play Store'),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leading: Container(
        width: Responsive.spacing(context, mobile: 40),
        height: Responsive.spacing(context, mobile: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: () {},
    );
  }
}
