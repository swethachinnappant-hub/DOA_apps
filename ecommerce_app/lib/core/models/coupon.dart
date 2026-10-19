import 'package:flutter/foundation.dart';

@immutable
class Coupon {
  const Coupon({
    required this.code,
    required this.flatOffInr,
    required this.minSubtotal,
    this.description = '',
    this.startsAt,
    this.endsAt,
    this.usageLimit = 0,
    this.usedCount = 0,
  });

  final String code;
  final int flatOffInr;
  final int minSubtotal;
  final String description;
  final DateTime? startsAt;
  final DateTime? endsAt;

  /// Total redemptions allowed across all customers; 0 means unlimited.
  final int usageLimit;

  /// Redemptions so far, incremented when an order lands with this code.
  final int usedCount;

  bool isSatisfiedBy(int subtotal) => subtotal >= minSubtotal;

  bool get isLive {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt!)) return false;
    if (endsAt != null && now.isAfter(endsAt!)) return false;
    return true;
  }

  bool get isExhausted => usageLimit > 0 && usedCount >= usageLimit;

  int get remainingUses =>
      usageLimit <= 0 ? -1 : (usageLimit - usedCount).clamp(0, usageLimit);

  int missingFor(int subtotal) =>
      subtotal >= minSubtotal ? 0 : minSubtotal - subtotal;

  Coupon copyWith({
    String? code,
    int? flatOffInr,
    int? minSubtotal,
    String? description,
    DateTime? startsAt,
    DateTime? endsAt,
    int? usageLimit,
    int? usedCount,
  }) {
    return Coupon(
      code: code ?? this.code,
      flatOffInr: flatOffInr ?? this.flatOffInr,
      minSubtotal: minSubtotal ?? this.minSubtotal,
      description: description ?? this.description,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
    );
  }

  Map<String, Object?> toJson() => {
        'code': code,
        'flatOffInr': flatOffInr,
        'minSubtotal': minSubtotal,
        'description': description,
        'startsAt': startsAt?.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'usageLimit': usageLimit,
        'usedCount': usedCount,
      };

  factory Coupon.fromJson(Map<String, Object?> json) => Coupon(
        code: json['code'] as String? ?? '',
        flatOffInr: (json['flatOffInr'] as num?)?.toInt() ?? 0,
        minSubtotal: (json['minSubtotal'] as num?)?.toInt() ?? 0,
        description: json['description'] as String? ?? '',
        startsAt: DateTime.tryParse(json['startsAt'] as String? ?? ''),
        endsAt: DateTime.tryParse(json['endsAt'] as String? ?? ''),
        usageLimit: (json['usageLimit'] as num?)?.toInt() ?? 0,
        usedCount: (json['usedCount'] as num?)?.toInt() ?? 0,
      );
}

enum CouponStatus { needsMore, eligible, applied }

CouponStatus couponStatusOf({
  required Coupon coupon,
  required int subtotal,
  required bool isApplied,
}) {
  if (isApplied) return CouponStatus.applied;
  if (coupon.isSatisfiedBy(subtotal)) return CouponStatus.eligible;
  return CouponStatus.needsMore;
}
