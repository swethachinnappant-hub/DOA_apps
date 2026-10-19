import 'package:flutter/material.dart';

/// Owner-editable overlay on a static `NavMenu` (SPEC-18). Null fields mean
/// "keep the built-in value"; [visible] false hides the entry everywhere the
/// menu renders (header, drawer, search chips).
@immutable
class NavMenuState {
  const NavMenuState({this.label, this.iconCode, this.visible = true});

  final String? label;
  final int? iconCode;
  final bool visible;

  NavMenuState copyWith({String? label, int? iconCode, bool? visible}) =>
      NavMenuState(
        label: label ?? this.label,
        iconCode: iconCode ?? this.iconCode,
        visible: visible ?? this.visible,
      );

  Map<String, Object?> toJson() => {
        if (label != null) 'label': label,
        if (iconCode != null) 'iconCode': iconCode,
        'visible': visible,
      };

  factory NavMenuState.fromJson(Map<String, Object?> json) => NavMenuState(
        label: json['label'] as String?,
        iconCode: (json['iconCode'] as num?)?.toInt(),
        visible: json['visible'] as bool? ?? true,
      );
}

/// The owner icon-picker whitelist (SPEC-18). [navIconFor] resolves a stored
/// code point against this table so every [IconData] stays a compile-time
/// constant — release builds reject runtime `IconData(...)` construction
/// because the icon tree-shaker cannot see which glyphs it needs.
const List<IconData> navIconChoices = [
  Icons.diamond_outlined,
  Icons.diamond,
  Icons.auto_awesome_outlined,
  Icons.favorite_border,
  Icons.workspace_premium_outlined,
  Icons.grid_view,
  Icons.card_giftcard,
  Icons.local_fire_department_outlined,
  Icons.style_outlined,
  Icons.star_border,
];

/// The whitelisted icon for [code], or [fallback] when no patch is set or
/// the stored code is not in [navIconChoices] (older/foreign payload).
IconData navIconFor(int? code, IconData fallback) {
  if (code == null) return fallback;
  for (final icon in navIconChoices) {
    if (icon.codePoint == code) return icon;
  }
  return fallback;
}

/// One hero-carousel slide, owner-editable in the Home Builder (SPEC-18).
/// Empty [imageUrl] falls back to the carousel's product-photo rotation.
@immutable
class HeroSlide {
  const HeroSlide({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.location,
    this.imageUrl = '',
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final String cta;
  final String location;
  final String imageUrl;
  final bool enabled;

  HeroSlide copyWith({
    String? title,
    String? subtitle,
    String? cta,
    String? location,
    String? imageUrl,
    bool? enabled,
  }) =>
      HeroSlide(
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        cta: cta ?? this.cta,
        location: location ?? this.location,
        imageUrl: imageUrl ?? this.imageUrl,
        enabled: enabled ?? this.enabled,
      );

  Map<String, Object?> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'cta': cta,
        'location': location,
        'imageUrl': imageUrl,
        'enabled': enabled,
      };

  factory HeroSlide.fromJson(Map<String, Object?> json) => HeroSlide(
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        cta: json['cta'] as String? ?? '',
        location: json['location'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );
}

/// A curated collection tile (SPEC-18): name, the section route it opens,
/// an optional hero image and the assigned product ids.
@immutable
class ShopCollection {
  const ShopCollection({
    required this.id,
    required this.name,
    required this.route,
    this.imageUrl = '',
    this.productIds = const [],
    this.visible = true,
  });

  final String id;
  final String name;
  final String route;
  final String imageUrl;
  final List<String> productIds;
  final bool visible;

  ShopCollection copyWith({
    String? name,
    String? route,
    String? imageUrl,
    List<String>? productIds,
    bool? visible,
  }) =>
      ShopCollection(
        id: id,
        name: name ?? this.name,
        route: route ?? this.route,
        imageUrl: imageUrl ?? this.imageUrl,
        productIds: productIds ?? this.productIds,
        visible: visible ?? this.visible,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'route': route,
        'imageUrl': imageUrl,
        'productIds': productIds,
        'visible': visible,
      };

  factory ShopCollection.fromJson(Map<String, Object?> json) => ShopCollection(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        route: json['route'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        productIds: (json['productIds'] as List? ?? const [])
            .map((e) => e as String)
            .toList(),
        visible: json['visible'] as bool? ?? true,
      );
}

/// A customer record for the owner's Customers screen (SPEC-18). Seeded rows
/// carry contact details; rows derived from orders are created on demand.
@immutable
class ShopCustomer {
  const ShopCustomer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.points = 0,
    required this.joinedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final int points;
  final DateTime joinedAt;

  ShopCustomer copyWith({
    String? name,
    String? phone,
    String? email,
    int? points,
  }) =>
      ShopCustomer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        points: points ?? this.points,
        joinedAt: joinedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'points': points,
        'joinedAt': joinedAt.toIso8601String(),
      };

  factory ShopCustomer.fromJson(Map<String, Object?> json) => ShopCustomer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        points: (json['points'] as num?)?.toInt() ?? 0,
        joinedAt: DateTime.tryParse(json['joinedAt'] as String? ?? '') ??
            DateTime(2026),
      );
}

/// One loyalty-point adjustment, shown in the customer's ledger (SPEC-18).
@immutable
class LoyaltyAdjustment {
  const LoyaltyAdjustment({
    required this.customerId,
    required this.delta,
    required this.reason,
    required this.at,
  });

  final String customerId;
  final int delta;
  final String reason;
  final DateTime at;

  Map<String, Object?> toJson() => {
        'customerId': customerId,
        'delta': delta,
        'reason': reason,
        'at': at.toIso8601String(),
      };

  factory LoyaltyAdjustment.fromJson(Map<String, Object?> json) =>
      LoyaltyAdjustment(
        customerId: json['customerId'] as String? ?? '',
        delta: (json['delta'] as num?)?.toInt() ?? 0,
        reason: json['reason'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime(2026),
      );
}
