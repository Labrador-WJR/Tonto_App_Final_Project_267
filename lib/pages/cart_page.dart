import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // --- FETCH FROM DB ---
  Future<void> _fetchCartItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('cart_items')
          .select('*, products(*)') 
          .eq('user_id', user.id);
          
      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(response).map((item) {
            item['isChecked'] = true; 
            return item;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UPDATE QTY ---
  Future<void> _updateQuantity(int cartItemId, int index, int newQty) async {
    if (newQty < 1) return;
    setState(() { _cartItems[index]['quantity'] = newQty; });

    try {
      await _supabase.from('cart_items').update({'quantity': newQty}).eq('id', cartItemId);
    } catch (e) {
      debugPrint('Failed to update qty: $e');
      _fetchCartItems(); 
    }
  }

  // --- DELETE ITEM ---
  Future<void> _deleteItem(int cartItemId) async {
    try {
      await _supabase.from('cart_items').delete().eq('id', cartItemId);
    } catch (e) {
      debugPrint('Failed to delete item: $e');
    }
  }

  // --- CALCULATE TOTAL ---
  double _calculateTotal() {
    double total = 0.0;
    for (var item in _cartItems) {
      if (item['isChecked'] == true) {
        final price = double.tryParse(item['products']['price'].toString()) ?? 0.0;
        final qty = item['quantity'] as int;
        total += price * qty;
      }
    }
    return total; 
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Your Shopping Cart'), 
        backgroundColor: darkThemeColor, 
        foregroundColor: Colors.white, 
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/icons/logo.png', width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: darkThemeColor))
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0), 
                    // --- REFRESH INDICATOR ---
                    child: RefreshIndicator(
                      onRefresh: _fetchCartItems,
                      color: darkThemeColor,
                      child: _cartItems.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                                const Center(child: Text('Your cart is empty! 🛒', style: TextStyle(color: Colors.grey, fontSize: 16))),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _cartItems.length, 
                              itemBuilder: (context, index) {
                                final item = _cartItems[index]; 
                                final product = item['products'] ?? {};

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Dismissible(
                                    key: ValueKey(item['id']), 
                                    direction: DismissDirection.horizontal, 
                                    background: Container(
                                      decoration: BoxDecoration(color: darkThemeColor, borderRadius: BorderRadius.circular(12)),
                                      alignment: Alignment.centerLeft, 
                                      padding: const EdgeInsets.only(left: 20.0), 
                                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 36), 
                                    ),
                                    secondaryBackground: Container(
                                      decoration: BoxDecoration(color: darkThemeColor, borderRadius: BorderRadius.circular(12)),
                                      alignment: Alignment.centerRight, 
                                      padding: const EdgeInsets.only(right: 20.0), 
                                      child: const Icon(Icons.delete_forever, color: Colors.white, size: 36), 
                                    ),
                                    onDismissed: (direction) {
                                      _deleteItem(item['id']);
                                      setState(() { _cartItems.removeAt(index); });
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product['name'] ?? 'Item'} removed'), duration: const Duration(seconds: 2)));
                                    },
                                    child: _buildCartItemCard(item, index),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                _buildBottomSummaryBar(),
              ],
            ),
    );
  }

  // --- ITEM CARD WIDGET ---
  Widget _buildCartItemCard(Map<String, dynamic> item, int index) {
    final product = item['products'] ?? {};
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
    
    // Safety check for image
    final imageUrl = product['image_url'] ?? product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '';
    final colorIndex = item['color_index'] as int?;

    final List<Color> circleColors = [
      const Color(0xFF2D3238), 
      const Color(0xFFD5D5D5), 
      const Color(0xFF383E46), 
      const Color(0xFF1A1D21)
    ];

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
            value: item['isChecked'] ?? true, 
            onChanged: (bool? newValue) { setState(() { item['isChecked'] = newValue ?? true; }); },
            activeColor: const Color(0xFF2D3238), checkColor: Colors.white, side: const BorderSide(color: Color(0xFF2D3238)), 
          ),
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 8), 
          
          Container(
            width: 70, height: 70, 
            decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)),
            child: imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8), 
                    child: Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.image_not_supported, size: 30, color: Colors.grey)),
                    ),
                  )
                : const Center(child: Icon(Icons.image, size: 36, color: Colors.white)),
          ),
          const SizedBox(width: 12), 
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(product['name'] ?? 'Unknown', style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (item['size'] != null)
                  Text('Size: ${item['size']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                if (colorIndex != null && colorIndex < circleColors.length)
                  Row(
                    children: [
                      const Text('Color: ', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: circleColors[colorIndex], shape: BoxShape.circle))
                    ]
                  ),
                const SizedBox(height: 8), 
                Text('P ${price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(item['id'], index, (item['quantity'] ?? 1) - 1),
                    child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.remove, color: Color(0xFF2D3238), size: 18)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), 
                      decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(4)),
                      child: Text('${item['quantity'] ?? 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _updateQuantity(item['id'], index, (item['quantity'] ?? 1) + 1),
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

  // --- BOTTOM CHECKOUT BAR ---
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
              final itemsToCheckout = _cartItems.where((item) => item['isChecked'] == true).map((item) {
                final product = item['products'] ?? {};
                return CartItem(
                  id: item['id'],
                  name: product['name'] ?? 'Unknown',
                  imagePath: product['image_url'] ?? product['image'] ?? product['imageUrl'] ?? product['imagePath'] ?? '',
                  price: double.tryParse(product['price']?.toString() ?? '0') ?? 0.0,
                  quantity: item['quantity'] ?? 1,
                );
              }).toList();

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