import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:common_widgets/common_widgets.dart';

import '../../../core/models/notification.dart';
import '../../../core/store/commerce_store.dart';
import '../../auth/providers/auth_provider.dart';
import '../../config/providers/business_config_provider.dart';

/// The buyer's notification feed, generated from real domain events.
///
/// Tapping a row marks it read and follows its route, so an order update
/// lands the shopper directly on that order.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<BusinessConfigProvider>().config;
    final store = context.watch<CommerceStore>();
    final user = context.watch<AuthProvider>().user;
    final audience = user?.id ?? '';

    final notes = store.notificationsFor(audience);
    final unread = notes.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () => store.markAllRead(audience),
              child: const Text('Mark all read'),
            ),
          if (notes.isNotEmpty)
            IconButton(
              tooltip: 'Clear notifications',
              icon: const Icon(Icons.clear_all_outlined),
              onPressed: () => _confirmClear(context, store, audience),
            ),
        ],
      ),
      body: notes.isEmpty
          ? _Empty(icon: config.icon)
          : ListView.separated(
              padding: Responsive.padding(context),
              itemCount: notes.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: Responsive.spacing(context, mobile: 8)),
              itemBuilder: (context, index) {
                final n = notes[index];
                return _Row(
                  note: n,
                  accent: config.accentColor,
                  brand: config.primaryColor,
                  onOpen: () {
                    store.markNotificationRead(n.id);
                    final route = n.route;
                    if (route != null && route.isNotEmpty) context.push(route);
                  },
                  onToggleRead: () =>
                      store.markNotificationRead(n.id, read: !n.read),
                );
              },
            ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CommerceStore store,
    String audience,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear notifications?'),
        content: const Text('This removes your notification history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) store.clearNotifications(audience);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.note,
    required this.accent,
    required this.brand,
    required this.onOpen,
    required this.onToggleRead,
  });

  final AppNotification note;
  final Color accent;
  final Color brand;
  final VoidCallback onOpen;
  final VoidCallback onToggleRead;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(note.type.icon, color: brand, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    if (!note.read) ...[
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, mobile: 14),
                          fontWeight:
                              note.read ? FontWeight.w500 : FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 12),
                    color: Colors.grey[600],
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _relative(note.createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Responsive.fontSize(context, mobile: 11),
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: note.read ? 'Mark unread' : 'Mark read',
            visualDensity: VisualDensity.compact,
            onPressed: onToggleRead,
            icon: Icon(
              note.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
              size: 18,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nothing yet',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, mobile: 16),
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Order updates and new arrivals show up here as they happen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _relative(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.isNegative || diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${time.day} ${names[time.month < 1 || time.month > 12 ? 0 : time.month - 1]}';
}
