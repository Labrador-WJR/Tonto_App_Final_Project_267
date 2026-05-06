import 'package:flutter/material.dart';
import 'dart:async';
import '../models/data_models.dart';
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

  final List<String> _bannerImages = [
    'assets/images/cover_image1.png',
    'assets/images/cover_image2.png',
    'assets/images/cover_image3.png',
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide(); 
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
       // REPLACED: Make the search bar a clickable button that opens the SearchPage
        title: GestureDetector(
          onTap: () {
            // Push the new Search Page
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
      body: SingleChildScrollView(
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
               itemBuilder: (context, index) {
                  // CHANGED: Wrapped in GestureDetector to make the whole card clickable
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProductDetailPage(
                            // For wireframe demo, we pass mock data
                            name: 'Product Name',
                            price: 200.00,
                          ),
                        ),
                      );
                    },
                    child: const ProductCard(), // Content pulled into separate widget for cleanliness
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire card in a GestureDetector right here!
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductDetailPage(
              name: 'Product Name',
              price: 200.00,
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
              child: Container(
                margin: const EdgeInsets.all(8), 
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9), 
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 50, color: Colors.black),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Name',
                    style: TextStyle(color: Colors.white, fontSize: 12),
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