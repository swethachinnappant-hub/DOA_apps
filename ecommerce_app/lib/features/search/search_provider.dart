import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/menu_data.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import 'search_index.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({required CommerceStore store}) : _store = store {
    _restoreRecents();
  }

  static const int debounceMillis = 250;
  static const int maxRecent = 8;

  /// Survives restarts so a retailer picks up where they left off (§15).
  static const String recentsKey = 'search_recents';

  /// Session cache; the source of truth for cross-launch history lives in
  /// SharedPreferences under [recentsKey].
  static final List<String> _recent = [];
  static bool _restored = false;

  final CommerceStore _store;
  Timer? _debounce;

  String _query = '';
  String _settled = '';

  static void resetRecents() {
    _recent.clear();
    _restored = false;
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove(recentsKey),
    ).catchError((_) => false);
  }

  String get query => _query;

  String get settledQuery => _settled;

  List<String> get recentSearches => List.unmodifiable(_recent);

  /// Most-shopped categories first — real demand, not a static list (§15).
  List<String> get popularSearches {
    final counts = <String, int>{};
    for (final product in _store.shopProducts) {
      if (product.category.isEmpty) continue;
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final recents = _recent.map((term) => term.toLowerCase()).toSet();
    return ranked
        .map((entry) => entry.key)
        .where((label) => !recents.contains(label.toLowerCase()))
        .take(6)
        .toList();
  }

  List<NavFacet> get relatedSearches => SearchIndex.relatedSearches(_settled);

  List<Product> get productSuggestions =>
      SearchIndex.products(_settled, _store.shopProducts);

  bool get hasQuery => _settled.isNotEmpty;

  void type(String value) {
    _query = value;
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      _settled = '';
      notifyListeners();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: debounceMillis), () {
      _settled = trimmed;
      notifyListeners();
    });
    notifyListeners();
  }

  void settleNow() {
    _debounce?.cancel();
    final trimmed = _query.trim();
    _settled = trimmed.length < 2 ? '' : trimmed;
    notifyListeners();
  }

  void recordRecent(String value) {
    final q = value.trim();
    if (q.isEmpty) return;
    _recent.remove(q);
    _recent.insert(0, q);
    if (_recent.length > maxRecent) {
      _recent.removeRange(maxRecent, _recent.length);
    }
    _persistRecents();
    notifyListeners();
  }

  void removeRecent(String value) {
    if (_recent.remove(value)) {
      _persistRecents();
      notifyListeners();
    }
  }

  /// Merges any stored history into the session cache. Session entries stay
  /// on top (they are the newest); stored ones fill in underneath.
  Future<void> _restoreRecents() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(recentsKey);
      if (stored != null && stored.isNotEmpty) {
        final merged = <String>[
          ..._recent,
          ...stored.where((term) => !_recent.contains(term)),
        ].take(maxRecent);
        _recent
          ..clear()
          ..addAll(merged);
        if (!_disposed) notifyListeners();
      }
    } catch (_) {}
  }

  void _persistRecents() {
    final snapshot = List<String>.of(_recent);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setStringList(recentsKey, snapshot),
    ).catchError((_) => false);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
