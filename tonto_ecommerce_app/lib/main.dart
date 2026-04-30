// Imports the core Flutter Material Design library
import 'package:flutter/material.dart';
import 'dart:async'; // <--- ADD THIS LINE FOR THE TIMER

// The main entry point of the Flutter application. 
void main() {
  runApp(const ECommerceApp());
}

// --- DATA MODEL ---
// --- DATA MODEL ---
class CartItem {
  int id; // CHANGED: Removed 'final' so we can update the ID later
  final String name; 
  final String imagePath; 
  final double price; 
  int quantity; 
  bool isChecked; 

  CartItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    this.isChecked = true, 
  });
}

// --- ROOT WIDGET ---
class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce UI', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), 
        primaryColor: const Color(0xFF2D3238), 
      ),
      home: const MainScreen(), 
    );
  }
}

// --- MAIN SCREEN (GLOBAL HUB WITH NESTED NAVIGATION) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238); 

    return Scaffold(
      // The AppBar is removed from here so it doesn't double-stack on the Cart/Checkout pages
      
      // IndexedStack keeps all nested navigators alive in the background
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const HomePage())),
          // CHANGED: The mini Navigator for the Custom section has its own State
          Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const CustomSectionRootWidget(),
            ),
          ),
          Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const PlaceholderPage(title: 'Wishlist / Favorites Page'))),
          Navigator(onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const PlaceholderPage(title: 'Profile Page'))),
        ],
      ),

      // Your Global Bottom Navigation Bar
     // Replace your current bottomNavigationBar with this:
      bottomNavigationBar: Container(
        height: 65, // Fixed height for the whole bar
        color: darkThemeColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Spaces tabs evenly
          crossAxisAlignment: CrossAxisAlignment.end, // CRITICAL: Forces tabs to touch the absolute bottom edge
          children: [
            _buildCustomNavItem('assets/icons/home.png', 'assets/icons/home_highlight.png', 0),
            _buildCustomNavItem('assets/icons/custom.png', 'assets/icons/custom_highlight.png', 1),
            _buildCustomNavItem('assets/icons/favorite.png', 'assets/icons/favorite_highlight.png', 2),
            _buildCustomNavItem('assets/icons/profile.png', 'assets/icons/profile_highlight.png', 3),
          ],
        ),
      ),
    );
  }

 // --- HELPER METHOD: Custom Bottom Nav Item ---
  // Notice the return type is now 'Widget' instead of 'BottomNavigationBarItem'
  Widget _buildCustomNavItem(String defaultPath, String highlightPath, int index) {
    bool isSelected = _currentIndex == index; 
    
    // GestureDetector makes our custom container clickable
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index; 
        });
      },
      child: Container(
        // Controls the width and height of the grey tab
        padding: const EdgeInsets.only(left: 24, right: 24, top: 14, bottom: 14), 
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9D9D9) : Colors.transparent,
          // Rounds only the top corners
          borderRadius: isSelected 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
              : BorderRadius.zero,
        ),
       child: Transform.scale(
          scale: isSelected ? 1.6 : 1.0, // <-- Tweak this number (1.4, 1.6, etc.) if it needs to be slightly bigger/smaller
          child: Image.asset(
            isSelected ? highlightPath : defaultPath, 
            width: 26,
            height: 26,
            color: isSelected ? null : Colors.white, 
          ),
       ),  
      ),
    );
  }
}

// --- HOME PAGE TAB ---
// --- HOME PAGE TAB ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // PageController manages the swiping and animation of the PageView
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
    _startAutoSlide(); // Start the timer when the page first loads
  }

  // --- NEW: A dedicated method to handle the timer ---
  void _startAutoSlide() {
    // 1. Cancel any existing timer so we don't accidentally run two at once
    _timer?.cancel(); 
    
    // 2. Start a fresh 3-second countdown
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
        child: Column(
          children: [
            
            // --- 1. Top Banner Section (Slideshow) ---
            SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView.builder(
                controller: _pageController,
                // Triggers whenever the page changes (either manually or automatically)
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page; 
                  });
                  // CHANGED: Restart the timer every time they swipe, so it never interrupts them!
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

            // --- 2. Dynamic Carousel Dot Indicators ---
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
            
            // --- 3. Product Grid Section ---
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
                  return const ProductCard();
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

// --- REUSABLE PRODUCT CARD WIDGET ---
class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

// --- PLACEHOLDER PAGE ---
class PlaceholderPage extends StatelessWidget {
  final String title; 
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    // Wrapped in a Scaffold to inherit the background color within the nested navigator
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// --- CART PAGE ---
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Color darkCardColor = const Color(0xFF383E46);
  Color lightGray = const Color(0xFFD9D9D9);

  final List<CartItem> _cartItems = [
    CartItem(id: 1, name: 'Product Name', imagePath: 'placeholder', price: 200.00, quantity: 1),
    CartItem(id: 2, name: 'Product Name', imagePath: 'placeholder', price: 200.00, quantity: 1),
    CartItem(id: 3, name: 'Product Name', imagePath: 'placeholder', price: 200.00, quantity: 1), 
    CartItem(id: 4, name: 'Product Name', imagePath: 'placeholder', price: 200.00, quantity: 1),
    CartItem(id: 5, name: 'Product Name', imagePath: 'placeholder', price: 200.00, quantity: 1),
  ];

  double _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (item.isChecked) {
        total += item.price * item.quantity;
      }
    }
    return total; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Shopping Cart'), 
        backgroundColor: const Color(0xFF2D3238), 
        foregroundColor: Colors.white, 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/icons/logo.png', 
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), 
              child: ListView.builder(
                itemCount: _cartItems.length, 
                itemBuilder: (context, index) {
                  final item = _cartItems[index]; 

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Dismissible(
                      key: ValueKey(item.id), 
                      direction: DismissDirection.horizontal, 
                      
                      background: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF383E46), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft, 
                        padding: const EdgeInsets.only(left: 20.0), 
                        child: const Icon(Icons.delete_forever, color: Colors.white, size: 36), 
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF383E46), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight, 
                        padding: const EdgeInsets.only(right: 20.0), 
                        child: const Icon(Icons.delete_forever, color: Colors.white, size: 36), 
                      ),
                      onDismissed: (direction) {
                        setState(() {
                          _cartItems.removeAt(index); 
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} removed'),
                            duration: const Duration(seconds: 2), 
                          ),
                        );
                      },
                      child: _buildCartItemCard(item),
                    ),
                  );
                },
              ),
            ),
          ),
          _buildBottomSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12.0), 
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D5), 
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), 
            spreadRadius: 1, 
            blurRadius: 4, 
            offset: const Offset(0, 2), 
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isChecked, 
            onChanged: (bool? newValue) {
              setState(() {
                item.isChecked = newValue ?? true; 
              });
            },
            activeColor: const Color(0xFF2D3238), 
            checkColor: Colors.white, 
            side: const BorderSide(color: Color(0xFF2D3238)), 
          ),
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 8), 
          Container(
            width: 70, 
            height: 70, 
            decoration: BoxDecoration(
              color: const Color(0xFF383E46), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white), 
            ),
          ),
          const SizedBox(width: 12), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16), 
                Text(
                  'P ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (item.quantity > 1) {
                        setState(() {
                          item.quantity--; 
                        });
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0), 
                      child: Icon(Icons.remove, color: Color(0xFF2D3238), size: 18), 
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                      decoration: BoxDecoration(
                        color: const Color(0xFF383E46), 
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}', 
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), 
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        item.quantity++; 
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.add, color: Color(0xFF2D3238), size: 18), 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32), 
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(20.0), 
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3), 
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, 
            children: [
              const Text(
                'Total:',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
              Text(
                'P ${_calculateTotal().toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final itemsToCheckout = _cartItems.where((item) => item.isChecked).toList();
              
              if (itemsToCheckout.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select items to checkout.')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(
                    checkoutItems: itemsToCheckout,
                    totalAmount: _calculateTotal(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF383E46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Checkout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// --- CHECKOUT PAGE ---
class CheckoutPage extends StatefulWidget {
  final List<CartItem> checkoutItems;
  final double totalAmount;

  const CheckoutPage({
    super.key,
    required this.checkoutItems,
    required this.totalAmount,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late List<CartItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.checkoutItems);
  }

  double _calculateLocalTotal() {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset(
              'assets/icons/logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    margin: const EdgeInsets.only(bottom: 16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF383E46), 
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Shipping Address:',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Lorem, Ipsum, Dolar',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.horizontal,
                            background: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF383E46),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20.0),
                              child: const Icon(Icons.delete_forever,
                                  color: Colors.white, size: 36),
                            ),
                            secondaryBackground: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF383E46),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete_forever,
                                  color: Colors.white, size: 36),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                _items.removeAt(index);
                              });
                            },
                            child: _buildCheckoutItemCard(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildCheckoutItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14, fontWeight: FontWeight.bold), 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Text(
                  'P ${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (item.quantity > 1) {
                        setState(() {
                          item.quantity--;
                        });
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.remove, color: Color(0xFF2D3238), size: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF383E46),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        item.quantity++;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.add, color: Color(0xFF2D3238), size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total:',
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
              Text(
                'P ${_calculateLocalTotal().toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
               // Handle placing the order here
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF383E46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Place Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEW: Custom Design Flow Classes ---

// Simple data class for the garment views
class GarmentView {
  final String label; // e.g., 'Front', 'Back'
  final String imagePath; // Path to the view's image file
  GarmentView({required this.label, required this.imagePath});
}

// 1. The Controller widget for the custom section
// This keeps track of the designs and manages the transitions.
// 1. The Controller widget for the custom section
class CustomSectionRootWidget extends StatefulWidget {
  const CustomSectionRootWidget({super.key});

  @override
  State<CustomSectionRootWidget> createState() => _CustomSectionRootWidgetState();
}

class _CustomSectionRootWidgetState extends State<CustomSectionRootWidget> {
  final List<CartItem> _userDesigns = [
    CartItem(id: 101, name: "Summer Hoodie v1", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
    CartItem(id: 102, name: "Classic Tee (Red)", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
    CartItem(id: 103, name: "Graphic Design 03", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
  ];

  // FIX 1: We use a running counter to guarantee every new design gets a 100% unique ID, 
  // even if the list is completely emptied out.
  int _nextUniqueId = 104; 

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => CustomDesignListPage(
          designs: _userDesigns,
          
          // Method to pop this list page and push the design page
          onAddDesignClicked: () async {
            final newDesignItem = await Navigator.of(context).push<CartItem>(
              MaterialPageRoute(builder: (context) => const EditingDetailsPage()),
            );

            if (newDesignItem != null) {
              setState(() {
                newDesignItem.id = _nextUniqueId++; // Assigns the ID, then increases the counter
                _userDesigns.add(newDesignItem);
              });
            }
          },
          
          // FIX 2: A dedicated function to handle deletions with setState
          onDeleteDesignClicked: (CartItem itemToDelete) {
            setState(() {
              _userDesigns.remove(itemToDelete);
            });
          },
        ),
      ),
    );
  }
}

// 2. The List Screen (First screen of the custom flow)
class CustomDesignListPage extends StatelessWidget {
  final List<CartItem> designs;
  final VoidCallback onAddDesignClicked;
  final Function(CartItem) onDeleteDesignClicked; // NEW: Accepts the delete function

  const CustomDesignListPage({
    super.key,
    required this.designs,
    required this.onAddDesignClicked,
    required this.onDeleteDesignClicked, // Required here
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Designs'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: const Icon(Icons.arrow_back), 
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: ListView.builder(
              itemCount: designs.length,
              itemBuilder: (context, index) {
                final item = designs[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey(item.id), // This key is now guaranteed to never repeat!
                    direction: DismissDirection.horizontal,
                    background: _buildTrashCanBackground(Alignment.centerLeft),
                    secondaryBackground: _buildTrashCanBackground(Alignment.centerRight),
                    onDismissed: (direction) {
                      // Call the parent function so it cleanly rebuilds the tree
                      onDeleteDesignClicked(item); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} removed'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: _buildDesignItemCard(item),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: onAddDesignClicked,
              backgroundColor: const Color(0xFF383E46),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashCanBackground(Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF383E46),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete_forever, color: Colors.white, size: 36),
    );
  }

  Widget _buildDesignItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
// 3. The Design Screen (Second screen of the custom flow)
// Stateful because it manages which view (Front/Side/Back) is active
class EditingDetailsPage extends StatefulWidget {
  const EditingDetailsPage({super.key});

  @override
  State<EditingDetailsPage> createState() => _EditingDetailsPageState();
}

class _EditingDetailsPageState extends State<EditingDetailsPage> {
  final List<GarmentView> _views = [
    GarmentView(label: 'Front', imagePath: 'placeholder_front'),
    GarmentView(label: 'Side', imagePath: 'placeholder_side'),
    GarmentView(label: 'Back', imagePath: 'placeholder_back'),
  ];

  int _currentViewIndex = 0;
  bool _isProcessing = false;

  // 1. Name Dialog
  Future<String?> _showNameDialog() async {
    TextEditingController nameController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, // Fix: Keeps the dialog inside our nested tab
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF383E46), 
          title: const Text('Name Your Design', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g., Summer Vibes Logo',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            autofocus: true, 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), 
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                String name = nameController.text.trim();
                if (name.isEmpty) name = "Unnamed Design"; 
                Navigator.pop(context, name); 
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 2. Success Dialog (Now Self-Closing!)
  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, // Fix: Keeps the dialog inside our nested tab
      builder: (BuildContext dialogContext) { // Use a specific context for the dialog
        
        // Auto-close THIS exact dialog after 1 second
        Future.delayed(const Duration(seconds: 1), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          child: Center(
            child: Container(
              width: 220, 
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF383E46), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check, 
                      color: Colors.black, 
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Design Saved',
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: 18, 
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentView = _views[_currentViewIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editing Details'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), 
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentViewIndex = (_currentViewIndex + 1) % _views.length;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD5D5D5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentView.label, 
                          style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.refresh, color: Color(0xFF2D3238)), 
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.image, size: 80, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 100), 
              ],
            ),
          ),
          
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gallery function not yet implemented.')),
                    );
                  },
                  backgroundColor: const Color(0xFFD5D5D5),
                  foregroundColor: const Color(0xFF2D3238),
                  child: const Icon(Icons.add, size: 36),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setState(() {
                      _isProcessing = true;
                    });

                    // 1. Show the Name dialog
                    final String? customName = await _showNameDialog();

                    if (customName == null) {
                      setState(() {
                        _isProcessing = false;
                      });
                      return;
                    }

                    // 2. Show the Success Popup and wait for it to auto-close!
                    await _showSuccessPopup();

                    if (!context.mounted) return;

                    // 3. Generate the data object
                    final newDesign = CartItem(
                      id: 0, 
                      name: customName, 
                      imagePath: _views[0].imagePath, 
                      price: 0.00, 
                      quantity: 1,
                    );
                    
                    // 4. Pop this Editing screen safely
                    Navigator.pop(context, newDesign); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF383E46), 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF383E46).withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}