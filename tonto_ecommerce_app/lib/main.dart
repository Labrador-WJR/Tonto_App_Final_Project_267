import 'package:flutter/material.dart';
import 'dart:async'; 

void main() {
  runApp(const ECommerceApp());
}

// ============================================================================
// 1. DATA MODELS & MOCK DATA
// ============================================================================

class CartItem {
  int id; 
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

class GarmentView {
  final String label; 
  final String imagePath; 
  GarmentView({required this.label, required this.imagePath});
}

class SavedAddress {
  final int id;
  final String addressString;
  SavedAddress({required this.id, required this.addressString});
}

// Global list of mock saved addresses
List<SavedAddress> mockSavedAddresses = [
  SavedAddress(id: 1, addressString: '123 Main St, Springfield, IL 62704, (555) 123-4567'),
  SavedAddress(id: 2, addressString: '456 Oak Ave, Metropolis, NY 10001, (555) 987-6543'),
  SavedAddress(id: 3, addressString: 'Lorem, Ipsum, Dolar, (Placeholder Address)'),
];

// ============================================================================
// 2. ROOT APP & MAIN NAVIGATION
// ============================================================================

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

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
  ];

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238); 

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Navigator(
            key: _navigatorKeys[0], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[1], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const CustomSectionRootWidget(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[2], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const FavoritesPage(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[3], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65, 
        color: darkThemeColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, 
          crossAxisAlignment: CrossAxisAlignment.end, 
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

  Widget _buildCustomNavItem(String defaultPath, String highlightPath, int index) {
    bool isSelected = _currentIndex == index; 
    const darkThemeColor = Color(0xFF2D3238); 
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_currentIndex != index) {
            // MAGIC FIX: Completely destroy the memory of the tab we are LEAVING
            _navigatorKeys[_currentIndex] = GlobalKey<NavigatorState>();
            // Then switch to the new tab
            _currentIndex = index; 
          } else {
            // If they tap the tab they are already on, pop to root
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 14, bottom: 14), 
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9D9D9) : Colors.transparent,
          borderRadius: isSelected 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
              : BorderRadius.zero,
        ),
       child: Transform.scale(
          scale: isSelected ? 1.6 : 1.0, 
          child: Image.asset(
            isSelected ? highlightPath : defaultPath, 
            width: 26,
            height: 26,
            color: isSelected ? null : Colors.white, 
            errorBuilder: (context, error, stackTrace) => Icon(Icons.circle, size: 26, color: isSelected ? darkThemeColor : Colors.white),
          ),
       ),  
      ),
    );
  }
}

// ============================================================================
// 3. HOME SECTION
// ============================================================================

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

// ============================================================================
// 4. CUSTOM DESIGN SECTION
// ============================================================================

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

  int _nextUniqueId = 104; 

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => CustomDesignListPage(
          designs: _userDesigns,
          onAddDesignClicked: () async {
            final newDesignItem = await Navigator.of(context).push<CartItem>(
              MaterialPageRoute(builder: (context) => const EditingDetailsPage()),
            );
            if (newDesignItem != null) {
              setState(() {
                newDesignItem.id = _nextUniqueId++; 
                _userDesigns.add(newDesignItem);
              });
            }
          },
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

class CustomDesignListPage extends StatelessWidget {
  final List<CartItem> designs;
  final VoidCallback onAddDesignClicked;
  final Function(CartItem) onDeleteDesignClicked; 

  const CustomDesignListPage({
    super.key,
    required this.designs,
    required this.onAddDesignClicked,
    required this.onDeleteDesignClicked, 
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
                    key: ValueKey(item.id), 
                    direction: DismissDirection.horizontal,
                    background: _buildTrashCanBackground(Alignment.centerLeft),
                    secondaryBackground: _buildTrashCanBackground(Alignment.centerRight),
                    onDismissed: (direction) {
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

  Future<String?> _showNameDialog() async {
    TextEditingController nameController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, 
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
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
            autofocus: true, 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), 
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
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

  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, 
      builder: (BuildContext dialogContext) { 
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
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.black, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Design Saved', style: TextStyle(color: Colors.white, fontSize: 18)),
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
                    decoration: BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentView.label, style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16, fontWeight: FontWeight.bold)),
                        const Icon(Icons.refresh, color: Color(0xFF2D3238)), 
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 100), 
              ],
            ),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery function not yet implemented.')));
                  },
                  backgroundColor: const Color(0xFFD5D5D5),
                  foregroundColor: const Color(0xFF2D3238),
                  child: const Icon(Icons.add, size: 36),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setState(() { _isProcessing = true; });
                    final String? customName = await _showNameDialog();
                    if (customName == null) {
                      setState(() { _isProcessing = false; });
                      return;
                    }
                    await _showSuccessPopup();
                    if (!context.mounted) return;
                    final newDesign = CartItem(id: 0, name: customName, imagePath: _views[0].imagePath, price: 0.00, quantity: 1);
                    Navigator.pop(context, newDesign); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF383E46), 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF383E46).withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. CART SECTION
// ============================================================================

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
            child: Image.asset('assets/icons/logo.png', width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white)),
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
                        setState(() { _cartItems.removeAt(index); });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} removed'), duration: const Duration(seconds: 2)));
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.isChecked, 
            onChanged: (bool? newValue) { setState(() { item.isChecked = newValue ?? true; }); },
            activeColor: const Color(0xFF2D3238), checkColor: Colors.white, side: const BorderSide(color: Color(0xFF2D3238)), 
          ),
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 8), 
          Container(
            width: 70, height: 70, 
            decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.image, size: 36, color: Colors.white)),
          ),
          const SizedBox(width: 12), 
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(item.name, style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16), 
                Text('P ${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () { if (item.quantity > 1) setState(() { item.quantity--; }); },
                    child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.remove, color: Color(0xFF2D3238), size: 18)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                      decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(4)),
                      child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () { setState(() { item.quantity++; }); },
                    child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.add, color: Color(0xFF2D3238), size: 18)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, -3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, 
            children: [
              const Text('Total:', style: TextStyle(color: Colors.black87, fontSize: 14)),
              Text('P ${_calculateTotal().toStringAsFixed(2)}', style: const TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final itemsToCheckout = _cartItems.where((item) => item.isChecked).toList();
              if (itemsToCheckout.isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select items to checkout.')));
                return;
              }
              Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutPage(checkoutItems: itemsToCheckout)));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Checkout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. CHECKOUT & VOUCHER SECTION
// ============================================================================

class CheckoutPage extends StatefulWidget {
  final List<CartItem> checkoutItems;
  const CheckoutPage({super.key, required this.checkoutItems});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late List<CartItem> _activeItems;
  String selectedAddress = 'No address selected';
  
  String _selectedPaymentMethod = 'Cash on Delivery';
  bool _isPaymentExpanded = false;
  final List<String> _allPaymentMethods = ['Cash on Delivery', 'GCash', 'PayMaya', 'Palawan'];
  String _selectedVoucherTitle = 'Select a Voucher';

  @override
  void initState() {
    super.initState();
    _activeItems = List.from(widget.checkoutItems);
    // Initialize address from mock data
    selectedAddress = mockSavedAddresses.isNotEmpty ? mockSavedAddresses[0].addressString : 'No address selected';
  }

  double _getSubtotal() {
    return _activeItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  double _getMinRequirement(String title) {
    switch (title) {
      case '₱ 200.00 off': return 500.00;
      case '₱ 150.00 off': return 400.00;
      case '₱ 100.00 off': return 300.00;
      case '₱ 50.00 off':  return 200.00;
      default: return 0.00; 
    }
  }

  double _getDiscountValue() {
    switch (_selectedVoucherTitle) {
      case '₱ 200.00 off': return 200.00;
      case '₱ 150.00 off': return 150.00;
      case '₱ 100.00 off': return 100.00;
      case '₱ 50.00 off':  return 50.00;
      default: return 0.00; 
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalItems = _activeItems.fold(0, (sum, item) => sum + item.quantity);
    double subtotal = _getSubtotal();
    double discount = _getDiscountValue(); 
    double shipping = 50.00; 
    double adjustedSubtotal = subtotal - discount;
    if (adjustedSubtotal < 0) adjustedSubtotal = 0; 
    double grandTotal = adjustedSubtotal + shipping;

    final cardDecoration = BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Shipping Address (Now Clickable)
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddressPage(initialSelectedAddress: selectedAddress)),
                );
                if (result != null) {
                  setState(() { selectedAddress = result; });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF383E46),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Shipping Address:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(selectedAddress, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Product List (Swipeable)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _activeItems.length,
              itemBuilder: (context, index) {
                final item = _activeItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.horizontal,
                    background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                    onDismissed: (direction) {
                      setState(() {
                        _activeItems.removeAt(index);
                        if (_selectedVoucherTitle != 'Select a Voucher' && _getSubtotal() < _getMinRequirement(_selectedVoucherTitle)) {
                          _selectedVoucherTitle = 'Select a Voucher';
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher removed: Minimum spend no longer met.')));
                        }
                        if (_activeItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No Items left. Returning.')));
                          Navigator.pop(context); 
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: cardDecoration,
                      child: Row(
                        children: [
                          const Icon(Icons.menu, color: Color(0xFF2D3238)), 
                          const SizedBox(width: 12),
                          Container(width: 60, height: 60, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF383E46), width: 2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.image, color: Color(0xFF383E46), size: 30)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 16)])),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (item.quantity > 1) {
                                        setState(() {
                                          item.quantity--;
                                          if (_selectedVoucherTitle != 'Select a Voucher' && _getSubtotal() < _getMinRequirement(_selectedVoucherTitle)) {
                                            _selectedVoucherTitle = 'Select a Voucher';
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voucher removed: Minimum spend no longer met.')));
                                          }
                                        });
                                      }
                                    },
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                  Container(margin: const EdgeInsets.symmetric(horizontal: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: const Color(0xFF383E46), child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 12))),
                                  GestureDetector(onTap: () { setState(() { item.quantity++; }); }, child: const Icon(Icons.add, size: 16)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('₱ ${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 4),

            // 3. Voucher Selector
            GestureDetector(
              onTap: () async {
                final selected = await Navigator.push(context, MaterialPageRoute(builder: (context) => VoucherPage(currentVoucher: _selectedVoucherTitle)));
                if (!context.mounted) return;
                if (selected != null && selected != _selectedVoucherTitle) {
                  double minReq = _getMinRequirement(selected);
                  if (_getSubtotal() >= minReq) {
                    setState(() { _selectedVoucherTitle = selected; });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Minimum spend of ₱${minReq.toStringAsFixed(2)} required for this voucher.')));
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.discount, color: Color(0xFF2D3238)), const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Voucher:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedVoucherTitle, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))])),
                    const Icon(Icons.chevron_right, color: Color(0xFF2D3238)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 4. Payment Method Accordion
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, decoration: cardDecoration,
              child: Column(
                children: [
                  InkWell(
                    onTap: () { setState(() { _isPaymentExpanded = !_isPaymentExpanded; }); },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Payment Method:', style: TextStyle(fontSize: 10, color: Colors.black54)), Text(_selectedPaymentMethod, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3238)))]),
                          Icon(_isPaymentExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(0xFF2D3238)),
                        ],
                      ),
                    ),
                  ),
                  if (_isPaymentExpanded) ...[
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Divider(color: Colors.black45, thickness: 1, height: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        children: _allPaymentMethods.map((method) {
                          if (method == _selectedPaymentMethod) return const SizedBox.shrink();
                          return InkWell(
                            onTap: () { setState(() { _selectedPaymentMethod = method; _isPaymentExpanded = false; }); },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(children: [Container(width: 18, height: 18, decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(2))), const SizedBox(width: 12), Text(method, style: const TextStyle(fontSize: 16, color: Color(0xFF2D3238)))]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Payment Details Summary
            Container(
              padding: const EdgeInsets.all(16.0), decoration: cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 12),
                  _buildSummaryRow('Total Items:', '$totalItems'), _buildSummaryRow('Subtotal:', '₱ ${subtotal.toStringAsFixed(2)}'), _buildSummaryRow('Discount:', '- ₱ ${discount.toStringAsFixed(2)}'), _buildSummaryRow('Shipping Subtotal:', '₱ ${shipping.toStringAsFixed(2)}'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(color: Colors.black26, thickness: 1)),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text('₱ ${grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))]),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 6. Place Order Button
            ElevatedButton(
              onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order Placed! Total: ₱${grandTotal.toStringAsFixed(2)}'))); },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 4),
              child: const Text('Place Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30), 
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)), Text(value, style: const TextStyle(fontSize: 12, color: Colors.black87))]));
  }
}

class VoucherPage extends StatefulWidget {
  final String currentVoucher;
  const VoucherPage({super.key, required this.currentVoucher});
  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  late String _selectedVoucher;
  final List<Map<String, String>> _vouchers = [
    {'title': '₱ 200.00 off', 'min': 'min. ₱500', 'expiry': 'Expiring: 5 hours left'},
    {'title': '₱ 150.00 off', 'min': 'min. ₱400', 'expiry': 'Expiring: 2 hours left'},
    {'title': '₱ 100.00 off', 'min': 'min. ₱300', 'expiry': 'Expiring: 1 day left'},
    {'title': '₱ 50.00 off',  'min': 'min. ₱200', 'expiry': 'Expiring: 3 days left'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedVoucher = widget.currentVoucher;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Voucher'), backgroundColor: const Color(0xFF2D3238), foregroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, _selectedVoucher))),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(padding: EdgeInsets.only(bottom: 16.0), child: Text('Note: One voucher can be applied at a time', style: TextStyle(color: Colors.black54, fontSize: 12))),
            Expanded(
              child: ListView.builder(
                itemCount: _vouchers.length,
                itemBuilder: (context, index) {
                  final voucher = _vouchers[index];
                  final isSelected = _selectedVoucher == voucher['title'];
                  return GestureDetector(
                    onTap: () { setState(() { _selectedVoucher = voucher['title']!; }); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 16.0), padding: const EdgeInsets.all(16.0), decoration: BoxDecoration(color: isSelected ? const Color(0xFF383E46) : const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))]),
                      child: Row(
                        children: [
                          Icon(Icons.discount, size: 40, color: isSelected ? Colors.white : const Color(0xFF2D3238)), const SizedBox(width: 16),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(voucher['title']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : const Color(0xFF2D3238))), const SizedBox(height: 4), Text(voucher['min']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87)), Text(voucher['expiry']!, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white70 : Colors.black87))]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 7. ADDRESS SECTION
// ============================================================================

class AddressPage extends StatefulWidget {
  final String initialSelectedAddress;
  const AddressPage({super.key, required this.initialSelectedAddress});
  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  late String _currentSelectedAddress;
  bool _showAddForm = false;

  final cardDecorationLight = BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);
  final cardDecorationDark = BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);

  @override
  void initState() {
    super.initState();
    _currentSelectedAddress = widget.initialSelectedAddress;
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text('Address'), backgroundColor: darkThemeColor, foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showAddForm) { setState(() { _showAddForm = false; }); } else { Navigator.pop(context, _currentSelectedAddress); }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
           // Map Placeholder
            Container(
              height: 180, padding: const EdgeInsets.all(16.0), decoration: cardDecorationLight,
              child: Stack(
                children: [
                  const Center(child: Text('Give access to location', style: TextStyle(color: darkThemeColor, fontSize: 16))),
                  Positioned(
                    bottom: 12, // CHANGED: Moved to the bottom
                    right: 12, 
                    child: Container(
                      decoration: const BoxDecoration(
                        color: darkThemeColor, 
                        shape: BoxShape.circle // CHANGED: Made it a perfect circle
                      ), 
                      child: IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.white), 
                        onPressed: () {}
                      )
                    )
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!_showAddForm) ...[
              ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: mockSavedAddresses.length,
                itemBuilder: (context, index) {
                  final addressItem = mockSavedAddresses[index];
                  bool isSelected = addressItem.addressString == _currentSelectedAddress;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Dismissible(
                      key: ValueKey(addressItem.id), direction: DismissDirection.horizontal,
                      background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                      secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                      onDismissed: (direction) {
                        setState(() {
                          mockSavedAddresses.removeAt(index);
                          if (_currentSelectedAddress == addressItem.addressString) _currentSelectedAddress = 'No address selected';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address removed.'), duration: Duration(seconds: 2)));
                      },
                      child: GestureDetector(
                        onTap: () { setState(() { _currentSelectedAddress = addressItem.addressString; }); },
                        child: Container(
                          padding: const EdgeInsets.all(12.0), decoration: isSelected ? cardDecorationDark : cardDecorationLight,
                          child: Row(children: [Icon(Icons.location_on, color: isSelected ? Colors.white : darkThemeColor, size: 24), const SizedBox(width: 12), Expanded(child: Text(addressItem.addressString, style: TextStyle(color: isSelected ? Colors.white : darkThemeColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))), const SizedBox(width: 12), Icon(Icons.chevron_right, color: isSelected ? Colors.white : darkThemeColor)]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ] else ...[
              NewAddressFormWidget(
                onSave: (newAddressString) {
                  setState(() {
                    mockSavedAddresses.insert(0, SavedAddress(id: DateTime.now().millisecondsSinceEpoch, addressString: newAddressString));
                    _currentSelectedAddress = newAddressString; 
                    _showAddForm = false; 
                  });
                  Navigator.pop(context, newAddressString);
                },
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      floatingActionButton: (!_showAddForm && mockSavedAddresses.length < 5) ? FloatingActionButton(onPressed: () { setState(() { _showAddForm = true; }); }, backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, child: const Icon(Icons.add, size: 36)) : null,
    );
  }
}

class NewAddressFormWidget extends StatefulWidget {
  final Function(String) onSave;
  const NewAddressFormWidget({super.key, required this.onSave});
  @override
  State<NewAddressFormWidget> createState() => _NewAddressFormWidgetState();
}

class _NewAddressFormWidgetState extends State<NewAddressFormWidget> {
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetController = TextEditingController();
  bool _setAsDefault = false; 

  @override
  void dispose() {
    _fullNameController.dispose(); _contactNumberController.dispose(); _provinceController.dispose(); _postalCodeController.dispose(); _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Note: Only 5 addresses can be created', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 12),
        const Text('New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkThemeColor)), const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12.0), decoration: BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [_buildFormInput(_fullNameController, 'Full Name'), _buildFormInput(_contactNumberController, 'Contact Number'), _buildFormInput(_provinceController, 'Province, Municipality, Barangay'), _buildFormInput(_postalCodeController, 'Postal Code'), _buildFormInput(_streetController, 'Street Name/House Number')]),
        ),
        const SizedBox(height: 12),
        Row(children: [Checkbox(value: _setAsDefault, onChanged: (bool? newValue) { setState(() { _setAsDefault = newValue ?? false; }); }, activeColor: darkThemeColor), const Text('Set as Default Address', style: TextStyle(color: darkThemeColor, fontSize: 14))]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final fullName = _fullNameController.text; final street = _streetController.text; final province = _provinceController.text; final postalCode = _postalCodeController.text; final contact = _contactNumberController.text;
              if (fullName.isNotEmpty && street.isNotEmpty) {
                final newAddressString = '$fullName, $street, $province $postalCode, $contact';
                widget.onSave(newAddressString); 
              } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all address details.'))); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
            child: const Text('Save Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormInput(TextEditingController controller, String placeholderText) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: TextField(controller: controller, decoration: InputDecoration(hintText: placeholderText, border: InputBorder.none, contentPadding: const EdgeInsets.all(16.0)))));
  }
}

// ============================================================================
// 8. MISC
// ============================================================================

class PlaceholderPage extends StatelessWidget {
  final String title; 
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
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

// ============================================================================
// 9. SEARCH PAGE SECTION
// ============================================================================

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data for the search history
  final List<String> _searchHistory = [
    'Suggestion',
    'Summer Hoodie v1',
    'Classic Tee (Red)',
    'Graphic Design 03',
  ];

  // Data for the filters
  final List<String> _allFilters = ['Men', 'Women', 'Child', 'Sports', 'Festival', 'Casual', 'Formal'];
  final List<String> _activeFilters = []; 

  // NEW: State variable to track if the dropdown is open
  bool _isDropdownOpen = false;

  // NEW: Function to toggle the dropdown instead of showing a popup
  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);
    final cardDecoration = BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        elevation: 0,
        automaticallyImplyLeading: false, 
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.arrow_back, color: Colors.white), 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true, 
                  decoration: const InputDecoration(
                    hintText: 'Search Product',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
      ),
      body: Column(
        children: [
          // 1. Filter Bar Row (The Anchor)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // PINNED: Main Filter Button
                GestureDetector(
                  // CHANGED: Now toggles the dropdown instead of opening a dialog
                  onTap: _toggleDropdown, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: cardDecoration,
                    child: const Row(
                      children: [
                        Icon(Icons.tune, size: 18, color: Color(0xFF2D3238)),
                        SizedBox(width: 6),
                        Text('Filter', style: TextStyle(color: Color(0xFF2D3238), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // SCROLLABLE: Active Filter Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _activeFilters.map((filterName) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: cardDecoration,
                          child: Row(
                            children: [
                              Text(filterName, style: const TextStyle(color: Color(0xFF2D3238))),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeFilters.remove(filterName);
                                  });
                                },
                                child: const Icon(Icons.close, size: 16, color: Color(0xFF2D3238)),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. The STACK (Holds the list AND the floating dropdown)
          Expanded(
            child: Stack(
              children: [
                // BASE LAYER: Search History Suggestions
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _searchHistory.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: cardDecoration,
                      child: Text(
                        _searchHistory[index],
                        style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16),
                      ),
                    );
                  },
                ),

                // INTERACTION LAYER: Invisible background to close dropdown when tapping outside
                if (_isDropdownOpen)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = false; // Close if they tap anywhere else
                      });
                    },
                    child: Container(
                      color: Colors.transparent, // Invisible but catches taps!
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),

                // TOP LAYER: The Floating Dropdown Menu
                if (_isDropdownOpen)
                  Positioned(
                    top: 0, // Sticks right below the filter bar
                    left: 16, // Aligns with the filter button
                    width: 250, // Fixed width for the menu
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF383E46), // Dark background
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4), // Drops shadow downwards
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select Categories', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          const SizedBox(height: 16),
                          // Wraps the filter chips so they flow onto the next line
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 12.0,
                            children: _allFilters.map((filter) {
                              final isSelected = _activeFilters.contains(filter);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _activeFilters.remove(filter);
                                    } else {
                                      _activeFilters.add(filter);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    // Light grey if selected, dark grey if unselected
                                    color: isSelected ? const Color(0xFFD5D5D5) : const Color(0xFF2D3238),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
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
// ============================================================================
// 10. PRODUCT DETAIL PAGE SECTION
// ============================================================================

// --- 10. PRODUCT DETAIL PAGE SECTION (Switchable Tabs Updated) ---

class ProductDetailPage extends StatefulWidget {
  final String name;
  final double price;

  const ProductDetailPage({
    super.key,
    required this.name,
    required this.price,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // --- STATE VARIABLES ---
  
  // 1. Image gallery indicators
  int _currentImageIndex = 0;

  // 2. Variant selections
  int _selectedColorIndex = 1; // Default select the second color
  String _selectedSize = 'M'; // Default select M

  // Data for the variant selections
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', '2XL'];
  final List<Color> _circleColors = [
    const Color(0xFF2D3238), 
    const Color(0xFFD5D5D5), 
    const Color(0xFF383E46), 
    const Color(0xFF1A1D21)
  ];

  // 3. NEW: Switchable Tab Tracking
  String _activeTab = 'Description'; // The app will start showing Description

  // --- MOCK CONTENT ---

  // Large mock description string
  final String _mockDescription = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';

  // Helper to show self-closing popups
  void _showAddedPopup(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              width: 250,
              padding: const EdgeInsets.all(24.0),
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
                    child: const Icon(Icons.check, color: Colors.black, size: 40),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper function to build a dynamically switchable tab button
  Widget _buildTabButton(String tabName) {
    bool isSelected = _activeTab == tabName;
    const darkThemeColor = Color(0xFF2D3238);

    return GestureDetector(
      onTap: () {
        // Update the state to switch the active tab and trigger a rebuild
        setState(() {
          _activeTab = tabName; 
        });
      },
      child: Column(
        children: [
          Text(
            tabName,
            style: TextStyle(
              fontSize: 16,
              // Only the active tab gets a bold font weight
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: darkThemeColor,
            ),
          ),
          const SizedBox(height: 4),
          // Animate the underline bar widening when selected
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            // bar is only visible and wide on the selected tab
            width: isSelected ? 80 : 0, 
            color: isSelected ? darkThemeColor : Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);
    const cardColor = Color(0xFFD5D5D5);

    // Styling for size variant boxes
    BoxDecoration _getVariantDecoration(bool isSelected) {
      return BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: isSelected 
            ? Border.all(color: Colors.black, width: 2)
            : null,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Search Product',
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset('assets/icons/cart.png', width: 24, height: 24, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. Top Image Gallery ---
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 100, color: Colors.black),
              ),
            ),
            const SizedBox(height: 12),
            // Dynamic Dot Indicators (Now clickable)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return GestureDetector(
                  onTap: () { setState(() { _currentImageIndex = index; }); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index ? Colors.black : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // --- 2. Product Name & Price ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkThemeColor),
                ),
                Text(
                  'P ${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: darkThemeColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. Color Variants (Circles - Now Interactive) ---
            Row(
              children: List.generate(4, (index) {
                bool isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () { setState(() { _selectedColorIndex = index; }); },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _circleColors[index],
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.black45, width: 3) : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // --- 4. Size Selector (highlight on click) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Size', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkThemeColor)),
                const Row(
                  children: [
                    Text('9.8', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.star, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Sizes Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sizes.map((size) {
                bool isSelected = size == _selectedSize;
                return GestureDetector(
                  onTap: () { setState(() { _selectedSize = size; }); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: _getVariantDecoration(isSelected), // Highlights selected box
                    child: Text(
                      size, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // --- 5. UPDATED Switchable Tabs Row (Description / Reviews Header) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Description'), // Dynamic button
                _buildTabButton('Reviews'), // Dynamic button
              ],
            ),
            const SizedBox(height: 20),

            // --- 6. Conditional Tab Content Area ---
            // If activeTab is 'Description', show text. If not, show review list.
            if (_activeTab == 'Description') ...[
              // Child 0: Description content (Lorem ipsum string)
              Text(
                _mockDescription,
                style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5), // height increases line-height for readability
              ),
            ] else ...[
              // Child 1: Review content (Mock static list of reviews)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2,
                itemBuilder: (context, index) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_circle, size: 40),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('9.8 *'),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed sit amet odio at nisl iaculis aliquam.',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      // --- Bottom Bar Button Section Remains Identical ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 60, height: 50,
              child: ElevatedButton(
                onPressed: () { _showAddedPopup(context, 'Item added to Favorites'); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383E46),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 28),
              ),
            ),
            SizedBox(
              width: 60, height: 50,
              child: ElevatedButton(
                onPressed: () { _showAddedPopup(context, 'Item added to Cart'); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383E46),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
              ),
            ),
            SizedBox(
              width: 180, height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final buyNowItem = CartItem(
                    id: DateTime.now().millisecondsSinceEpoch, 
                    name: widget.name,
                    imagePath: 'placeholder', 
                    price: widget.price,
                    quantity: 1,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        checkoutItems: [buyNowItem], 
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383E46),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text('Buy Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 11. PROFILE PAGE SECTION ---

// Data model for an order item, reusing the CartItem structure but adding a status
class OrderItem {
  final int id;
  final String name;
  final String imagePath;
  final double price;
  final int quantity;
  final String status; // Special for the profile page view

  OrderItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    this.status = "Status: Lorem, Ipsum, Dolar", // Default as per image_20.png/image_21.png
  });
}

// Global list of mock orders, categorized for the different tabs
List<OrderItem> mockPendingOrders = [
  OrderItem(id: 301, name: "Pending Hoodie v1", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 302, name: "Pending Tee (Red)", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockShippingOrders = [
  OrderItem(id: 401, name: "Shipping Design 03", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockDeliveredOrders = [
  OrderItem(id: 501, name: "Delivered Cap (Blue)", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockCompletedOrders = [
  OrderItem(id: 601, name: "Completed Watch (Gold)", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 602, name: "Completed Shoes (White)", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 603, name: "Completed Design 04", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

// Profile Page Widget with State to handle tab switching
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State to track the currently selected tab index
  int _selectedTabIndex = 0;

  // The tabs as a simple list of strings
  final List<String> _tabs = ['Pending', 'Shipping', 'Deliver', 'Completed'];

  // Reuse card styling for grey containers
  final cardDecoration = BoxDecoration(
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
  );

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    // Dynamic data loading based on selected tab
    List<OrderItem> currentOrders = [];
    switch (_selectedTabIndex) {
      case 0:
        currentOrders = mockPendingOrders;
        break;
      case 1:
        currentOrders = mockShippingOrders;
        break;
      case 2:
        currentOrders = mockDeliveredOrders;
        break;
      case 3:
        currentOrders = mockCompletedOrders;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/logo.png', // The Tonto logo from image_18.png
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white), // Settings gear from image_18.png
            onPressed: () {
              // Placeholder settings action
              print('Settings clicked');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
            // 1. User Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Circular Avatar Placeholder from image_18.png
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFD5D5D5),
                    child: Icon(Icons.person, size: 60, color: darkThemeColor),
                  ),
                  const SizedBox(width: 16),
                  
                  // Username from image_18.png
                  const Expanded(
                    child: Text(
                      'Username',
                      style: TextStyle(color: darkThemeColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // Percentage Icon (discount/coupon) from image_18.png
                  IconButton(
                    icon: const Icon(Icons.percent, color: darkThemeColor, size: 30),
                    onPressed: () {
                      // Placeholder coupon action
                      print('Coupons clicked');
                    },
                  ),
                ],
              ),
            ),
            
            // 2. Tab Selection Section (Pending, Shipping, etc.)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Horizontal tab buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_tabs.length, (index) {
                      final tabName = _tabs[index];
                      final isSelected = _selectedTabIndex == index;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index; // Rebuild with new data
                          });
                        },
                        child: Column(
                          children: [
                            Text(
                              tabName,
                              style: TextStyle(
                                fontSize: 14,
                                color: darkThemeColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Line indicator below the selected tab
                            Container(
                              height: 2,
                              width: 60, // Width can be dynamic or static
                              color: isSelected ? darkThemeColor : Colors.transparent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Divider line as per image_18.png
                  const Divider(color: darkThemeColor, thickness: 1),
                ],
              ),
            ),
            
            // 3. Conditional Content Section based on Tab Type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: currentOrders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'No orders in this state.',
                          style: TextStyle(color: darkThemeColor, fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true, // List is inside a ScrollView
                      physics: const NeverScrollableScrollPhysics(), // ScrollView handles scrolling
                      itemCount: currentOrders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ProfileItemCard(
                            orderItem: currentOrders[index],
                            isCompletedTab: _selectedTabIndex == 3, // True if 'Completed' tab is selected
                            cardDecoration: cardDecoration, // Pass the shared decoration
                          ),
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

// Reusable card component for an individual order item
class ProfileItemCard extends StatelessWidget {
  final OrderItem orderItem;
  final bool isCompletedTab;
  final BoxDecoration cardDecoration;

  const ProfileItemCard({
    super.key,
    required this.orderItem,
    required this.isCompletedTab,
    required this.cardDecoration,
  });

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: cardDecoration, // Shared grey container decoration
      child: Row(
        children: [
          // Grey Image Placeholder from product designs
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46), // Darker grey for image container
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          
          // Order information and conditional action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name from previous design
                Text(
                  orderItem.name,
                  style: const TextStyle(color: darkThemeColor, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16), // Spacing below name
                
                // --- Conditional Render based on Tab Type (referencing input images) ---
                if (isCompletedTab) ...[
                  // 1. Child for 'Completed' Tab: Dark "Rate" Button from image_22.png
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Align to right like image_22.png
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: darkThemeColor, // Dark button color
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
                        child: TextButton(
                          onPressed: () {
                            // Placeholder rating action
                            print('Rate button clicked for order ${orderItem.id}');
                          },
                          child: const Text(
                            'Rate',
                            style: TextStyle(
                              color: Colors.white, // White text for rate button
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // 2. Child for other Tabs: "Status: ..." Text from image_20.png and image_21.png
                  Text(
                    orderItem.status, // Uses status string from OrderItem data model
                    style: TextStyle(
                      color: darkThemeColor.withOpacity(0.7), // Faded status text
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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