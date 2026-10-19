import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persistence boundary for the owner console's CMS state (SPEC-18).
///
/// `CommerceStore` owns the editable state and calls [read]/[write] through
/// this interface, so swapping the local preferences blob for a real backend
/// later means implementing this one class — no store or screen changes.
abstract class CatalogRepository {
  /// The last saved CMS payload, or null when nothing was saved yet.
  Future<Map<String, Object?>?> read();

  /// Replaces the saved payload.
  Future<void> write(Map<String, Object?> payload);

  /// Drops the saved payload (used by "reset to defaults").
  Future<void> clear();
}

/// [CatalogRepository] backed by a single JSON blob in SharedPreferences.
class LocalCatalogRepository implements CatalogRepository {
  const LocalCatalogRepository();

  static const String _key = 'cms.v1';

  @override
  Future<Map<String, Object?>?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return decoded.cast<String, Object?>();
    } catch (_) {
      // A corrupt blob behaves exactly like no blob: defaults stay.
    }
    return null;
  }

  @override
  Future<void> write(Map<String, Object?> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payload));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
