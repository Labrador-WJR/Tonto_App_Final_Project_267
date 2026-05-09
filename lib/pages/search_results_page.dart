import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_page.dart';
import 'home_page.dart'; // We import this to reuse your beautiful ProductCard!

class SearchResultsPage extends StatefulWidget {
  final String searchQuery;
  final List<String> activeFilters;

  const SearchResultsPage({
    super.key,
    required this.searchQuery,
    required this.activeFilters,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final _supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _searchResultsFuture;
  Set<int> _favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    _searchResultsFuture = _performSearch();
    _fetchFavorites();
  }

  // Fetch favorites so the Heart Badge works on the search results too!
  Future<void> _fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      final response = await _supabase.from('favorites').select('product_id').eq('user_id', user.id);
      if (mounted) {
        setState(() {
          _favoriteProductIds = response.map<int>((fav) => int.tryParse(fav['product_id'].toString()) ?? 0).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

 // The Magic Search Query
  Future<List<Map<String, dynamic>>> _performSearch() async {
    // Start building the query
    var query = _supabase.from('products').select('*');

    // 1. If they typed a search word, find products with names that match
    if (widget.searchQuery.isNotEmpty) {
      query = query.ilike('name', '%${widget.searchQuery}%'); 
    }

    // 2. THE UPGRADE: Use '.overlaps()' for Array columns!
    if (widget.activeFilters.isNotEmpty) {
      // This tells Supabase: "Only return this product if its category array 
      // contains AT LEAST ONE of the filters the user clicked."
      query = query.overlaps('category', widget.activeFilters);
    }

    return await query;
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        title: Text(widget.searchQuery.isEmpty ? 'Filtered Results' : 'Search: "${widget.searchQuery}"'),
        actions: [
          IconButton(
            icon: Image.asset('assets/icons/cart.png', width: 24, height: 24, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.shopping_cart)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() { _searchResultsFuture = _performSearch(); });
          await _fetchFavorites();
        },
        color: darkThemeColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _searchResultsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator(color: darkThemeColor)));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: const Center(child: Text('No products match your search 😔', style: TextStyle(fontSize: 16, color: Colors.grey))),
                );
              }

              final products = snapshot.data!;

              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final productId = int.tryParse(product['id'].toString()) ?? 0;
                  final price = double.tryParse(product['price'].toString()) ?? 0.0;
                  final rating = double.tryParse(product['rating'].toString()) ?? 5.0;
                  final sales = int.tryParse(product['sales'].toString()) ?? 0;
                  final isFav = _favoriteProductIds.contains(productId);

                  // We reuse the exact ProductCard from your Home Page!
                  return ProductCard(
                    id: productId,
                    name: product['name'] ?? 'Unknown Item',
                    price: price,
                    image: product['image_url'] ?? product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '',
                    description: product['description'] ?? '',
                    rating: rating,
                    sales: sales,
                    isFavorite: isFav,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}