import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _address;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetail();
  }

  Future<void> _fetchOrderDetail() async {
    try {
      final orderRes = await _supabase
          .from('orders')
          .select('*, profiles:user_id(full_name)')
          .eq('id', widget.orderId)
          .maybeSingle();

      if (orderRes != null) {
        _order = orderRes;
      }

      // Fetch default address
      if (orderRes != null && orderRes['user_id'] != null) {
        final addrRes = await _supabase
            .from('user_addresses')
            .select('address_string')
            .eq('user_id', orderRes['user_id'])
            .eq('is_default', true)
            .maybeSingle();
        _address = addrRes;
      }

      // Fetch order items
      final itemsRes = await _supabase
          .from('order_items')
          .select('quantity, price, product:products(name, image)')
          .eq('order_id', widget.orderId);
      _items = itemsRes;
    } catch (e) {
      debugPrint('Order detail error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF30363D),
        title: const Text('Order Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Order not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Order #${_order!['id']}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                          _buildStatusBadge(_order!['status'] ?? 'Pending'),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Customer info
                      Builder(builder: (_) {
                        final profile = _order!['profiles'];
                        final customerName = (profile != null && profile is Map)
                            ? (profile['full_name'] ?? 'N/A')
                            : 'N/A';
                        return Text('Customer: $customerName',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
                      }),
                      const SizedBox(height: 8),
                      Text('Address: ${_address?['address_string'] ?? 'No address provided'}',
                          style: const TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 8),
                      const Text('Payment Method: Not specified',
                          style: TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 20),

                      const Text('Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),

                      // Items list – fixed syntax
                      if (_items.isEmpty)
                        const Text('No items found')
                      else
                        ..._items.map((item) {
                          final product = item['product'] is Map ? item['product'] : null;
                          final name = product?['name'] ?? 'Product';
                          final qty = item['quantity'] ?? 0;
                          final price = (item['price'] ?? 0).toDouble();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: product?['image'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            product!['image'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image, color: Colors.black54),
                                          ),
                                        )
                                      : const Icon(Icons.image, color: Colors.black54),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('Qty: $qty  •  ₱ ${price.toStringAsFixed(0)}',
                                          style: const TextStyle(color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                Text('₱ ${(price * qty).toStringAsFixed(0)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }).toList(),

                      const Divider(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          Text(
                            '₱ ${(_order!['total_price'] ?? 0).toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF30363D)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color labelColor;
    Color bgColor;
    switch (status) {
      case 'Pending':
        labelColor = const Color(0xFFA02B2B);
        bgColor = const Color(0xFFE5B5B5);
        break;
      case 'Shipped':
        labelColor = const Color(0xFF2B5B84);
        bgColor = const Color(0xFFB5D1E5);
        break;
      default:
        labelColor = const Color(0xFF2B844A);
        bgColor = const Color(0xFFB5E5C4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(status,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}