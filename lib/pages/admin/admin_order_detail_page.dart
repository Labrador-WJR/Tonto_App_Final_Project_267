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

  // --- NEW: Function to update the status in the database ---
  Future<void> _updateOrderStatus(String newStatus) async {
    final oldStatus = _order!['status'];
    
    // Optimistic UI update (change it instantly on screen)
    setState(() {
      _order!['status'] = newStatus;
    });

    try {
      await _supabase.from('orders').update({'status': newStatus}).eq('id', widget.orderId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order #${widget.orderId} marked as $newStatus'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Update status error: $e');
      // If the database fails, revert back to the old status
      if (mounted) {
        setState(() {
          _order!['status'] = oldStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
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
                          // UPDATED: Now an interactive dropdown!
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

  // --- UPDATED: Turned the static badge into a functional Dropdown Button ---
  Widget _buildStatusBadge(String status) {
    Color labelColor;
    Color bgColor;
    
    switch (status) {
      case 'Pending':
        labelColor = const Color(0xFFA02B2B);
        bgColor = const Color(0xFFE5B5B5);
        break;
      case 'Processing':
        labelColor = const Color(0xFF8A6D2B);
        bgColor = const Color(0xFFE5DEB5);
        break;
      case 'Shipped':
        labelColor = const Color(0xFF2B5B84);
        bgColor = const Color(0xFFB5D1E5);
        break;
      case 'Cancelled':
        labelColor = Colors.white;
        bgColor = Colors.black54;
        break;
      case 'Delivered':
      default:
        labelColor = const Color(0xFF2B844A);
        bgColor = const Color(0xFFB5E5C4);
    }

    // List of standard statuses an admin can select
    List<String> validStatuses = ['Pending', 'Shipping', 'Deliver', 'Completed'];
    
    // Safety check just in case the database has a weird custom status saved
    if (!validStatuses.contains(status)) {
      validStatuses.add(status);
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          dropdownColor: bgColor,
          icon: Icon(Icons.arrow_drop_down, color: labelColor),
          isDense: true,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 14),
          items: validStatuses.map((String s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s, style: TextStyle(color: labelColor, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (String? newStatus) {
            if (newStatus != null && newStatus != status) {
              _updateOrderStatus(newStatus);
            }
          },
        ),
      ),
    );
  }
}