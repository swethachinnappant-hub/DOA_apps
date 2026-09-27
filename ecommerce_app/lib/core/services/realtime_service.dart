import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/notification.dart';
import '../models/order.dart';
import '../product.dart';

/// Something that just happened in the data layer.
///
/// Repositories emit these instead of callers poking each other, which is what
/// lets a seller's "Ship" tap reach the customer's order screen with no
/// refresh. The transport is deliberately hidden: today events fire in-process,
/// and swapping in a WebSocket or FCM adapter later only changes who publishes
/// to the controller.
enum AppEventType {
  productPublished,
  productUpdated,
  productDeleted,
  stockChanged,
  orderPlaced,
  orderStatusChanged,
}

@immutable
class AppEvent {
  final AppEventType type;
  final String? productId;
  final String? orderId;
  final String? audienceId;
  final Product? product;
  final Order? order;
  final OrderStatus? status;
  final String? previousStatus;
  final String message;

  const AppEvent({
    required this.type,
    this.productId,
    this.orderId,
    this.audienceId,
    this.product,
    this.order,
    this.status,
    this.previousStatus,
    this.message = '',
  });

  @override
  String toString() =>
      'AppEvent(${type.name}, product: $productId, order: $orderId)';
}

/// Broadcast hub for domain events.
///
/// The singleton is recreated after [dispose] rather than staying dead, so
/// tests can tear one down between cases and the app gets a fresh bus on the
/// next read.
class RealtimeService {
  RealtimeService._();

  static RealtimeService? _instance;

  static RealtimeService get instance => _instance ??= RealtimeService._();

  final _events = StreamController<AppEvent>.broadcast();
  final _notifications = StreamController<AppNotification>.broadcast();

  /// Domain events: product and order changes.
  Stream<AppEvent> get events => _events.stream;

  /// Notifications derived from those events, already filtered per audience.
  Stream<AppNotification> get notifications => _notifications.stream;

  bool _disposed = false;

  void publish(AppEvent event) {
    if (_disposed) return;
    _events.add(event);
  }

  /// Emits a notification to whoever it is addressed to.
  void notify(AppNotification notification) {
    if (_disposed) return;
    _notifications.add(notification);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _events.close();
    _notifications.close();
    if (identical(_instance, this)) _instance = null;
  }
}
