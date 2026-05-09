import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_page.dart';
import 'search_page.dart';
import 'product_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  // Supabase client reference
  final _supabase = Supabase.instance.client;

  // A variable to store our download task
  late Future<List<Map<String, dynamic>>> _productsFuture;

  // Set to store favorited product IDs
  Set<int> _favoriteProductIds = {};

  final List<String> _bannerImages = [
    'assets/images/cover_image1.png',
    'assets/images/cover_image2.png',
    'assets/images/cover_image3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide(); 
    _productsFuture = _fetchProducts(); 
    _fetchFavorites(); 
  }

  // Function to fetch products from Supabase
  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await _supabase.from('products').select('*');
    return response;
  }

  // Function to fetch user's favorites from Supabase
  Future<void> _fetchFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', user.id);
          
      if (mounted) {
        setState(() {
          // Store all favorited IDs in a Set for super-fast checking
          _favoriteProductIds = response.map<int>((fav) => int.tryParse(fav['product_id'].toString()) ?? 0).toSet();
        });
      }
    } catch (e) {
      debugPrint('Error fetching favorites for home page: $e');
    }
  }

  // Pull to Refresh Function
  Future<void> _refreshData() async {
    setState(() {
      _productsFuture = _fetchProducts();
    });
    await _fetchFavorites();
  }

  void _startAutoSlide() {
    _timer?.cancel(); 
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _bannerImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0; 
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
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
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.black54),
                SizedBox(width: 8),
                Text(
                  'Search...',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ],
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: darkThemeColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), 
          child: Column(
            children: [
              // --- BANNER CAROUSEL ---
              SizedBox(
                height: 200,
                width: double.infinity,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() { _currentPage = page; });
                    _startAutoSlide();
                  },
                  itemCount: _bannerImages.length,
                  itemBuilder: (context, index) {
                    return Image.asset(
                      _bannerImages[index],
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFD9D9D9),
                          child: const Center(
                            child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_bannerImages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // --- SUPABASE DATA GRID ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
               child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _productsFuture, 
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator(color: darkThemeColor)),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No products available.'));
                    }

                    final products = snapshot.data!;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length, 
                      itemBuilder: (context, index) {
                        final product = products[index]; 
                        
                        final productId = int.tryParse(product['id'].toString()) ?? 0;
                        final price = double.tryParse(product['price'].toString()) ?? 0.0;
                        final rating = double.tryParse(product['rating'].toString()) ?? 5.0;
                        final sales = int.tryParse(product['sales'].toString()) ?? 0;

                        final isFav = _favoriteProductIds.contains(productId);

                        return ProductCard(
                          id: productId, 
                          name: product['name'] ?? 'Unknown Item',
                          price: price,
                          image: product['image_url'] ?? product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '',
                          description: product['description'] ?? 'No description available.',
                          rating: rating,         
                          sales: sales, 
                          isFavorite: isFav, 
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final int id;
  final String name;
  final double price;
  final String image;
  final String description;
  final double rating;       
  final int sales;      
  final bool isFavorite; 

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.rating,       
    required this.sales,   
    this.isFavorite = false, 
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand, // --- THE FIX: Forces children to stretch and fill the space ---
                children: [
                  Container(
                    margin: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9), 
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: image.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity, // --- THE FIX: Forces the image to fill the container height ---
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image, size: 50, color: Colors.black),
                          ),
                  ),
                  
                  if (isFavorite)
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