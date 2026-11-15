import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_manager.dart';
import 'api_constants.dart';

class ApiService {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/login');
    final body = jsonEncode({'email': email, 'password': password});
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await TokenManager.saveToken(data['token']);
      return data;
    }
    throw Exception('Login failed: ${response.reasonPhrase}');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> request) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/auth/register');
    final body = jsonEncode(request);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await TokenManager.saveToken(data['token']);
      return data;
    }
    throw Exception('Registration failed: ${response.reasonPhrase}');
  }

  Future<Map<String, dynamic>?> getMe() async {
    final token = await TokenManager.getToken();
    if (token == null) return null;
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/me');
    final response = await _client.get(uri, headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>> fetchProducts({
    String? search,
    String? category,
    String? sort,
    int limit = 24,
  }) async {
    final uri = Uri.http(
      ApiConstants.baseUrl.split('//')[1].split(':')[0],
      '/api/v1/products',
      {
        if (search != null) 'q': search,
        if (category != null) 'category': category,
        'sort': sort,
        'limit': limit.toString(),
      },
    );
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to fetch products: ${response.reasonPhrase}');
  }

  Future<Map<String, dynamic>?> getProductById(String productId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/products/$productId');
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> orderData) async {
    final token = await TokenManager.getToken();
    if (token == null) throw Exception('No authentication token');
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/orders');
    final response = await _client.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await TokenManager.saveToken(data['token'] ?? token);
      return data;
    }
    throw Exception('Order failed: ${response.reasonPhrase}');
  }

  String getProductImageUrl(String? storageKey) {
    if (storageKey == null) return '';
    return '$ApiConstants.baseUrl/api/v1/media?key=$storageKey';
  }

  Future<List<dynamic>?> getCategories() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/categories');
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<List<dynamic>?> getTrending({int limit = 20}) async {
    final uri = Uri.http(
      ApiConstants.baseUrl.split('//')[1].split(':')[0],
      '/api/v1/trending',
      {'limit': limit.toString()},
    );
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<List<dynamic>?> getGoldRates() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/v1/meta/gold-rates');
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Future<Map<String, dynamic>?> searchProducts(String query) async {
    final uri = Uri.http(
      ApiConstants.baseUrl.split('//')[1].split(':')[0],
      '/api/v1/search',
      {'q': query, 'sort': 'featured', 'limit': '8'},
    );
    final response = await _client.get(uri, headers: _authHeaders()).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  Map<String, String> _authHeaders() {
    final token = TokenManager.getToken();
    if (token == null) return {'Content-Type': 'application/json'};
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
}