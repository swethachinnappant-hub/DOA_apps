import 'package:flutter/material.dart';

enum NotificationType {
  orderPlaced('Order placed', Icons.receipt_long_outlined),
  orderStatus('Order update', Icons.local_shipping_outlined),
  outOfStock('Out of stock', Icons.error_outline),
  priceChange('Price update', Icons.trending_down),
  newArrival('New arrival', Icons.auto_awesome_outlined),
  sellerMessage('Message from shop', Icons.chat_bubble_outline),
  enquiry('Product enquiry', Icons.forum_outlined);

  const NotificationType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// An in-app notification.
///
/// These are generated from real domain events by [RealtimeService] rather
/// than hardcoded, so an owner's status change produces a genuine entry in
/// the customer's list.
@immutable
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;

  /// Who should see this, e.g. a customer id or an owner id.
  final String audienceId;

  /// Route to open when tapped, e.g. `/order/ORD-1`.
  final String? route;

  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.audienceId,
    required this.createdAt,
    this.route,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        audienceId: audienceId,
        route: route,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'audienceId': audienceId,
        'route': route,
        'createdAt': createdAt.toIso8601String(),
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, Object?> json) => AppNotification(
        id: json['id'] as String? ?? '',
        type: NotificationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => NotificationType.orderStatus,
        ),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        audienceId: json['audienceId'] as String? ?? '',
        route: json['route'] as String?,
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        read: json['read'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotification &&
          other.id == id &&
          other.type == type &&
          other.title == title &&
          other.body == body &&
          other.audienceId == audienceId &&
          other.route == route &&
          other.read == read &&
          other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        title,
        body,
        audienceId,
        route,
        read,
        createdAt,
      );
}
