import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce_app_clean/services/api_service.dart';
import 'package:ecommerce_app_clean/utils/token_manager.dart';
import 'package:ecommerce_app_clean/constants/api_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _productsFuture;
  String? _searchQuery;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadProducts() async {
    final api = ApiService();
    setState(() => _productsFuture = api.fetchProducts(search: _searchQuery, limit: 20, sort: 'featured'));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jewelry Store'),
        actions: [
          IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.of(context).pushNamed('/profile')),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: const InputDecoration(labelText: 'Search products', suffixIcon: Icon(Icons.search)),
          ),
        ),
        Expanded(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return const Center(child: Text('Error'));
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No products found'));
              final products = snapshot.data!['products'] as List?;
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemCount: products?.length ?? 0,
                itemBuilder: (context, index) {
                  final product = products![index];
                  return _ProductCard(product: product);
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final price = product['price'] ?? 0;
    final name = product['name'] ?? 'Unknown';
    final image = product['images'] != null && product['images'].isNotEmpty ? product['images'][0] : '';
    return Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1.5, child: CachedNetworkImage(imageUrl: '$ApiConstants.baseUrl/api/v1/media?key=$image', placeholder: (_, __) => Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 50)), errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 50))),
        Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text('\$${price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold))])),
      ]),
    );
  }
}