import 'package:flutter/material.dart';
import '../core/responsive.dart';
import 'app_bar.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final String title;
  final List<Widget>? actions;

  const NavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    if (isMobile) {
      return _buildMobileLayout(context);
    } else if (isTablet) {
      return _buildTabletLayout(context);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: title, actions: actions),
      body: child,
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNav(context, compact: true),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSideNav(context, compact: false),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = _getNavigationItems();

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex.clamp(0, items.length - 1),
        onTap: onIndexChanged,
        items: items.take(5).map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context, {required bool compact}) {
    final items = _getNavigationItems();
    final theme = Theme.of(context);

    return Container(
      width: compact ? 72 : 260,
      decoration: BoxDecoration(
        color: theme.primaryColor,
      ),
      child: Column(
        children: [
          _buildLogo(context, compact),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: Responsive.spacing(context, mobile: 8)),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = currentIndex == index;

                return _buildNavItem(context, item, isSelected, compact);
              },
            ),
          ),
          _buildUserInfo(context, compact),
        ],
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool compact) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 20),
      child: Row(
        mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: Responsive.fontSize(context, mobile: 40, desktop: 50),
            height: Responsive.fontSize(context, mobile: 40, desktop: 50),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'CA',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, mobile: 16, desktop: 20),
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Chirag',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 16, desktop: 18),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Associates',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, mobile: 11, desktop: 12),
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, NavigationItemData item, bool isSelected, bool compact) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(item.icon, color: Colors.white, size: compact ? 20 : 24),
        title: compact
            ? null
            : Text(
                item.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: Responsive.fontSize(context, mobile: 13, desktop: 14),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        selected: isSelected,
        contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => onIndexChanged(_getNavigationItems().indexOf(item)),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context, bool compact) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(Icons.person, color: Colors.white, size: compact ? 16 : 20),
          ),
          if (!compact) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.fontSize(context, mobile: 13, desktop: 14),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'admin@chirag.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: Responsive.fontSize(context, mobile: 11, desktop: 12),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ],
        ],
      ),
    );
  }

  List<NavigationItemData> _getNavigationItems() {
    return const [
      NavigationItemData(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      NavigationItemData(icon: Icons.shopping_cart_rounded, label: 'Sales'),
      NavigationItemData(icon: Icons.shopping_bag_rounded, label: 'Purchase'),
      NavigationItemData(icon: Icons.account_balance_rounded, label: 'Banking'),
      NavigationItemData(icon: Icons.assessment_rounded, label: 'Reports'),
      NavigationItemData(icon: Icons.receipt_rounded, label: 'GST'),
      NavigationItemData(icon: Icons.chat_rounded, label: 'Chat'),
      NavigationItemData(icon: Icons.people_rounded, label: 'Clients'),
      NavigationItemData(icon: Icons.settings_rounded, label: 'Settings'),
    ];
  }
}

class NavigationItemData {
  final IconData icon;
  final String label;

  const NavigationItemData({
    required this.icon,
    required this.label,
  });
}

