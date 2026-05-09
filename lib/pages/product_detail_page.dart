import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 1. ADDED SUPABASE IMPORT
import '../models/data_models.dart';
import 'cart_page.dart';
import 'checkout_page.dart';

// --- 10. PRODUCT DETAIL PAGE SECTION (Switchable Tabs Updated) ---

class ProductDetailPage extends StatefulWidget {
  final int id;
  final String name;
  final double price;
  final String description;
  final String image;
  final double rating;       // ADDED: For the stars
  final int sales;      // ADDED: For the "Sold" text

  const ProductDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
    required this.rating,       // ADDED
    required this.sales,   // ADDED
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // Changing these to 'int?' (nullable) means they start entirely blank!
  int? _selectedColorIndex; 
  int? _selectedSizeIndex;

  // Supabase Client & Loading State
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

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


  // --- SUPABASE: ADD TO CART ---
  Future<void> _addToCart({bool isBuyNow = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first!')));
      return;
    }

    // Validation: Force them to pick variants!
    if (_selectedSizeIndex == null || _selectedColorIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a size and color first!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.from('cart_items').insert({
        'user_id': user.id,
        'product_id': widget.id,
        'quantity': 1,
        'size': _sizes[_selectedSizeIndex!],
        'color_index': _selectedColorIndex,
      });
      
      if (mounted) {
        if (isBuyNow) {
          // If Buy Now, go to checkout with the item details
          final buyNowItem = CartItem(
            id: DateTime.now().millisecondsSinceEpoch, 
            name: widget.name,
            imagePath: widget.image, // Passed the real image here!
            price: widget.price,
            quantity: 1,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(checkoutItems: [buyNowItem]),
            ),
          );
        } else {
          // If just Add to Cart, show your beautiful custom popup
          _showAddedPopup(context, 'Item added to Cart');
        }
      }
    } catch (e) {
      // Catch if it's already in the cart (due to our UNIQUE constraint)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This exact item is already in your cart!')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SUPABASE: ADD TO FAVORITES ---
  Future<void> _addToFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first!')));
      return;
    }

    try {
      await _supabase.from('favorites').insert({
        'user_id': user.id,
        'product_id': widget.id,
      });
      if (mounted) {
        _showAddedPopup(context, 'Item added to Favorites');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already in your favorites! ❤️')));
      }
    }
  }


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
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: darkThemeColor,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
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

    BoxDecoration getVariantDecoration(bool isSelected) {
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
              height: 300, 
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFD5D5D5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.image_not_supported, 
                          size: 80, 
                          color: Colors.grey
                        ),
                      ),
                    )
                  : const Icon(Icons.image, size: 80, color: Colors.black),
            ),

            // --- 2. Product Name & Price ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded( 
                  child: Text(
                    widget.name, 
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    maxLines: 2, 
                    overflow: TextOverflow.ellipsis, 
                  ),
                ),
                const SizedBox(width: 16), 
                Text(
                  'P ${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // --- 3. Color Variants ---
           Row(
              children: List.generate(4, (index) {
                bool isSelected = _selectedColorIndex == index;
                Color currentColor = _circleColors[index]; // 1. Grab the current color
                
                // 2. Check how bright the color is to decide the border color!
                Color borderColor = currentColor.computeLuminance() > 0.5 
                    ? Colors.black87 // Use dark border for light colors
                    : Colors.white;  // Use light border for dark colors

                return GestureDetector(
                  onTap: () { setState(() { _selectedColorIndex = index; }); },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: currentColor,
                        shape: BoxShape.circle,
                        // 3. Apply our smart border color
                        border: isSelected ? Border.all(color: borderColor, width: 5) : null,
                        
                        // Optional: Add a tiny shadow so white circles don't blend into the grey background
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(1), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // --- 4. Size Selector ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Size',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Text(
                      '${widget.sales} Sold', 
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(
                      ' ${widget.rating.toStringAsFixed(1)}', 
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _sizes.map((size) {
                bool isSelected = _selectedSizeIndex == _sizes.indexOf(size);
                return GestureDetector(
                  onTap: () { setState(() { _selectedSizeIndex = _sizes.indexOf(size); }); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: getVariantDecoration(isSelected), 
                    child: Text(
                      size, 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // --- 5. Switchable Tabs Row ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabButton('Description'), 
                _buildTabButton('Reviews'), 
              ],
            ),
            const SizedBox(height: 20),

            // --- 6. Conditional Tab Content Area ---
            if (_activeTab == 'Description') ...[
              Text(
                widget.description, 
                style: const TextStyle(height: 1.5), 
              ),
            ] else ...[
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
            const SizedBox(height: 100), 
          ],
        ),
      ),

      // --- Bottom Bar Button Section ---
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
                onPressed: _addToFavorites, // TRIGGER SUPABASE FAVORITES
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
                onPressed: _isLoading ? null : () => _addToCart(isBuyNow: false), // TRIGGER SUPABASE CART
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF383E46),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: _isLoading 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
              ),
            ),
            SizedBox(
              width: 180, height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _addToCart(isBuyNow: true), // TRIGGER SUPABASE CART + NAVIGATE
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