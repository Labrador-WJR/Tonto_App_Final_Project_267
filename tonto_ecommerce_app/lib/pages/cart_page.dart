import 'package:flutter/material.dart';
import '../models/data_models.dart';
import 'checkout_page.dart';

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
