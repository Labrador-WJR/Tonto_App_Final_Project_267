import 'package:flutter/material.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';
import '../models/data_models.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Mock list of favorite products – in the future, you can fetch real products
  final List<Product> _favoriteProducts = [
    Product(
      id: 'mock1',
      name: 'Summer Hoodie v1',
      price: 200.00,
      category: 'hoodie',
    ),
    Product(
      id: 'mock2',
      name: 'Classic Tee (Red)',
      price: 200.00,
      category: 'tee',
    ),
    Product(
      id: 'mock3',
      name: 'Graphic Design 03',
      price: 200.00,
      category: 'hoodie',
    ),
    Product(
      id: 'mock4',
      name: 'Cap (Blue)',
      price: 200.00,
      category: 'cap',
    ),
  ];

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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.pets, color: Colors.white),
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
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shopping_cart, color: Colors.white),
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
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: _favoriteProducts.length,
              itemBuilder: (context, index) {
                return FavoriteProductCard(
                  product: _favoriteProducts[index],
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

class FavoriteProductCard extends StatelessWidget {
  final Product product;
  const FavoriteProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product),
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
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image,
                                      size: 50, color: Colors.black),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image,
                                size: 50, color: Colors.black),
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
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                            color: Colors.white70, shape: BoxShape.circle),
                        child: const Icon(Icons.favorite,
                            size: 18, color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
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
                      Text(
                        product.formattedPrice,
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