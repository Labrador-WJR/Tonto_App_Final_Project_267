import 'package:flutter/material.dart';
import '../models/data_models.dart';
import 'cart_page.dart';
import 'checkout_page.dart';

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