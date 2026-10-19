import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/navigation/menu_data.dart';
import '../../core/product.dart';
import '../../core/store/commerce_store.dart';
import 'search_index.dart';

class SearchProvider extends ChangeNotifier {
  SearchProvider({required CommerceStore store}) : _store = store;

  static const int debounceMillis = 250;
  static const int maxRecent = 8;

  /// Session-scoped so terms survive closing and reopening the overlay.
  static final List<String> _recent = [];

  final CommerceStore _store;
  Timer? _debounce;

  String _query = '';
  String _settled = '';

  static void resetRecents() => _recent.clear();

  String get query => _query;

  String get settledQuery => _settled;

  List<String> get recentSearches => List.unmodifiable(_recent);

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
    notifyListeners();
  }

  void removeRecent(String value) {
    if (_recent.remove(value)) notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
