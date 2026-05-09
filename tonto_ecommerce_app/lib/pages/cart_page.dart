import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';
import '../services/supabase_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<CartItemModel>> _cartFuture;

  @override
  void initState() {
    super.initState();
    _refreshCart();
  }

  void _refreshCart() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _cartFuture = SupabaseService.getCartItems(userId);
    setState(() {});
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
            child: Image.asset('assets/icons/logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.pets, color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder<List<CartItemModel>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load cart'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFF383E46),
                              borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white, size: 36),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFF383E46),
                              borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete_forever,
                              color: Colors.white, size: 36),
                        ),
                        onDismissed: (direction) async {
                          await SupabaseService.removeCartItem(item.id);
                          _refreshCart();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${item.product?.name ?? 'Item'} removed')),
                            );
                          }
                        },
                        child: _buildCartItemCard(item),
                      ),
                    );
                  },
                ),
              ),
              _buildBottomSummaryBar(items),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    final product = item.product;
    final price = product?.price ?? 0.0;
    final name = product?.name ?? 'Unknown Product';
    final imageUrl = product?.imageUrl ?? '';

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
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 8),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
                color: const Color(0xFF383E46),
                borderRadius: BorderRadius.circular(8)),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover)
                : const Icon(Icons.image, size: 36, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Color(0xFF2D3238), fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                Text('P ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Color(0xFF2D3238),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (item.quantity > 1) {
                        await SupabaseService.updateCartQuantity(
                            item.id, item.quantity - 1);
                        _refreshCart();
                      }
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.remove,
                            color: Color(0xFF2D3238), size: 18)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFF383E46),
                          borderRadius: BorderRadius.circular(4)),
                      child: Text('${item.quantity}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      await SupabaseService.updateCartQuantity(
                          item.id, item.quantity + 1);
                      _refreshCart();
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.add,
                            color: Color(0xFF2D3238), size: 18)),
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

  Widget _buildBottomSummaryBar(List<CartItemModel> items) {
    double total = 0;
    for (var item in items) {
      total += (item.product?.price ?? 0) * item.quantity;
    }
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Total:',
                  style: TextStyle(color: Colors.black87, fontSize: 14)),
              Text('P ${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(checkoutItems: items),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF383E46),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Checkout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}