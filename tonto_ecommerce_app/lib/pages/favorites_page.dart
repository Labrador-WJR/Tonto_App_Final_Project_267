import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';

// ============================================================================
// 12. FAVORITES PAGE SECTION
// ============================================================================

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  
  // Mock list of favorite products. Reuse the structure from HomePage mock.
  final List<String> _favoriteProductNames = [
    'Summer Hoodie v1',
    'Classic Tee (Red)',
    'Graphic Design 03',
    'Cap (Blue)',
  ];

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // Mimic Home Page AppBar
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/logo.png', // Logo from Home Page design
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
              'assets/icons/cart.png', // Cart Icon from Home Page
              width: 24,
              height: 24,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_cart, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Product Grid Section mimicking Home Page
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // ScrollView handles scrolling
              shrinkWrap: true, // Crucial for embedding inside SingleChildScrollView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Aspect ratio from original design
              ),
              itemCount: _favoriteProductNames.length,
              itemBuilder: (context, index) {
                // New custom card for Favorites Page
                return FavoriteProductCard(
                  productName: _favoriteProductNames[index],
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Reusable card for the Favorites grid
// Reusable card for the Favorites grid
// Reusable card for the Favorites grid
class FavoriteProductCard extends StatelessWidget {
  final String productName;
  
  const FavoriteProductCard({super.key, required this.productName});

  @override
  Widget build(BuildContext context) {
    // 1. ADDED: Wrap the entire container in a GestureDetector
    return GestureDetector(
      onTap: () {
        // 2. ADDED: Navigate to ProductDetailPage when clicked
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              name: productName, // Pass the actual name of the clicked favorite
              price: 200.00,     // Mock price for the wireframe
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
                    child: const Center(
                      child: Icon(Icons.image, size: 50, color: Colors.black),
                    ),
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
                    productName,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Product Sold',
                    style: TextStyle(color: Colors.grey, fontSize: 8),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < 3 ? Icons.star : Icons.star_border,
                            color: Colors.white,
                            size: 10,
                          );
                        }),
                      ),
                      const Text(
                        'P 200.00',
                        style: TextStyle(
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
