import 'package:flutter/material.dart';

/// What a signed-in account is allowed to do.
///
/// The two roles get entirely separate navigation trees rather than one
/// dashboard with hidden controls, which is how Myntra, Amazon and Shopify
/// keep buyer and seller experiences from bleeding into each other.
enum UserRole {
  customer('Customer', 'Shop, track orders and manage your account'),
  owner('Shop Owner', 'List products, manage stock and fulfil orders');

  const UserRole(this.label, this.description);

  final String label;
  final String description;

  IconData get icon =>
      this == UserRole.owner ? Icons.storefront_outlined : Icons.shopping_bag_outlined;

  /// Where this role lands straight after login.
  String get homePath => this == UserRole.owner ? '/owner' : '/app';

  /// Prefix used to decide whether a route belongs to this role.
  String get routePrefix => this == UserRole.owner ? '/owner' : '/app';

  static UserRole fromName(String? name) {
    for (final role in UserRole.values) {
      if (role.name == name) return role;
    }
    return UserRole.customer;
  }
}

/// A signed-in account.
@immutable
class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Shop name, only meaningful for [UserRole.owner].
  final String? shopName;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.shopName,
  });

  /// Two-letter monogram for avatars, e.g. "Chirag Associates" -> "CA".
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  /// What to show as the display name for each role.
  String get displayName => role == UserRole.owner && (shopName?.isNotEmpty ?? false)
      ? shopName!
      : name;

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    String? shopName,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'shopName': shopName,
      };

  static AppUser fromJson(Map<String, Object?> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRole.fromName(json['role'] as String?),
      shopName: json['shopName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          other.id == id &&
          other.name == name &&
          other.email == email &&
          other.phone == phone &&
          other.role == role &&
          other.shopName == shopName;

  @override
  int get hashCode => Object.hash(id, name, email, phone, role, shopName);
}
