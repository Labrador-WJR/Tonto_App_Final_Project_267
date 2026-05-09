import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ADDED: Supabase
import 'cart_page.dart';
import 'product_detail_page.dart';

// ============================================================================
// 12. FAVORITES PAGE SECTION (Supabase Connected)
// ============================================================================

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // ADDED: Supabase Setup
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  // ADDED: Fetch favorites from database
  Future<void> _fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // The Join Query: Get the favorite row AND the full product details
      final response = await _supabase
          .from('favorites')
          .select('id, products(*)') 
          .eq('user_id', user.id);
          
      if (mounted) {
        setState(() {
          _favoriteItems = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/logo.png', 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white),
          ),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search Favorites...',
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/cart.png',
              width: 24,
              height: 24,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: darkThemeColor))
          : RefreshIndicator(
              onRefresh: _fetchFavorites,
              color: darkThemeColor,
              child: _favoriteItems.isEmpty
                  // If empty, we still need a scrollable list to trigger the pull-to-refresh!
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(child: Text('No favorites yet! ❤️', style: TextStyle(color: Colors.grey, fontSize: 16))),
                      ],
                    )
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // Force scrolling
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      child: Column(
                        children: [
                          GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _favoriteItems.length,
                        itemBuilder: (context, index) {
                          // Extract nested product data
                          final product = _favoriteItems[index]['products'];

                          return FavoriteProductCard(
                            id: product['id'],
                            name: product['name'] ?? 'Unknown Item',
                            price: double.tryParse(product['price'].toString()) ?? 0.0,
                            description: product['description'] ?? 'No description available',
                            image: product['image'] ?? '',
                            rating: double.tryParse(product['rating'].toString()) ?? 5.0,
                            sales: int.tryParse(product['sales'].toString()) ?? 0,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    )
    );
  }
}

// UPDATED: Reusable card for the Favorites grid (Now accepts real data!)
class FavoriteProductCard extends StatelessWidget {
  final int id;
  final String name;
  final double price;
  final String description;
  final String image;
  final double rating;
  final int sales;
  
  const FavoriteProductCard({
    super.key, 
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
    required this.rating,
    required this.sales,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              id: id, 
              name: name,
              price: price,     
              description: description, 
              image: image, 
              rating: rating, 
              sales: sales, 
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF383E46), 
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upper Image Section
            Expanded(
              child: Stack( 
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9), 
                      borderRadius: BorderRadius.circular(4),
                    ),
                    // Use real image if available
                    child: image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                            ),
                          )
                        : const Center(child: Icon(Icons.image, size: 50, color: Colors.black)),
                  ),
                  Positioned(
                    bottom: 12, 
                    right: 12,  
                    child: Image.asset(
                      'assets/icons/favorite_badge.png', 
                      width: 28, 
                      height: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 28, height: 28,
                        decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite, size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Lower Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sales Sold',
                    style: const TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < rating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 10,
                          );
                        }),
                      ),
                      Text(
                        'P ${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}