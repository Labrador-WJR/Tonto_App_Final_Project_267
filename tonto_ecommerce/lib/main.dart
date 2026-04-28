import 'package:flutter/material.dart';

void main() {
  runApp(const ECommerceApp());
}

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: const Color(0xFF2D3238), // Dark color from the image
      ),
      home: const MainScreen(),
    );
  }
}

// --- Main Screen with Sticky App Bar and Bottom Nav ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of pages for the bottom navigation
  final List<Widget> _pages = [
    const HomePage(),
    const PlaceholderPage(title: 'Sales Page'),
    const PlaceholderPage(title: 'Wishlist / Favorites Page'),
    const PlaceholderPage(title: 'Profile Page'),
  ];

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      // 1. Sticky App Bar
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        elevation: 0,
        titleSpacing: 0,
        leading: const Center(
          child: Text(
            'TONTO',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
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
              hintText: 'Search...',
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 9),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.white),
            onPressed: () {
              // Navigate to Cart Page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
            },
          ),
        ],
      ),

      // 2. Body changes based on selected tab
      body: _pages[_currentIndex],

      // 3. Sticky Bottom Navigation Bar
      bottomNavigationBar: Container(
        color: darkThemeColor,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: darkThemeColor,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          // Customizing the active state to have the grey box background
          items: [
            _buildNavItem(Icons.home, 0),
            _buildNavItem(Icons.checkroom, 1), // Shirt icon for sales/clothes
            _buildNavItem(Icons.favorite_border, 2),
            _buildNavItem(Icons.person_outline, 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, int index) {
    bool isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9D9D9) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.black : Colors.white,
          size: 28,
        ),
      ),
      label: '',
    );
  }
}

// --- Home Page (Matching the wireframe) ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Banner Section
          Container(
            height: 200,
            width: double.infinity,
            color: const Color(0xFFD9D9D9),
            child: const Center(
              child: Icon(Icons.image, size: 80, color: Colors.black),
            ),
          ),
          const SizedBox(height: 8),
          
          // Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: index == 0 ? Colors.black : Colors.grey,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Product Grid Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true, // Needed to work inside SingleChildScrollView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75, // Adjusts height of the cards
              ),
              itemCount: 6, // Number of placeholder items
              itemBuilder: (context, index) {
                return const ProductCard();
              },
            ),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
    );
  }
}

// --- Reusable Product Card Widget ---
class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF383E46), // Dark card background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
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
          
          // Product Details
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
                    // Star Ratings
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < 3 ? Icons.star : Icons.star_border,
                          color: Colors.white,
                          size: 10,
                        );
                      }),
                    ),
                    // Price
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
    );
  }
}

// --- Placeholder Page for Sales, Wishlist, Profile ---
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// --- Cart Page (Pushed on top of MainScreen) ---
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Your Cart is Empty',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}