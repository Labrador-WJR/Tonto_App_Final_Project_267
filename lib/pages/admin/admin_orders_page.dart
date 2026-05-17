import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_order_detail_page.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Priority', 'Pending', 'Shipped', 'Done'];

  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
  }

  Future<void> _fetchLiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('orders')
          .select('id, status, total_price, user_id, created_at')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> fetchedOrders = [];
      for (var order in response) {
        String customerName = 'Unknown Customer';
        String productDesc = 'Custom Order';

        if (order['user_id'] != null) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('id', order['user_id'])
                .maybeSingle();
            if (profile != null) customerName = profile['full_name'] ?? customerName;
          } catch (_) {}
        }

        try {
          final items = await _supabase
              .from('order_items')
              .select('quantity, product:products(name)')
              .eq('order_id', order['id'])
              .limit(1);
          if (items.isNotEmpty) {
            final item = items[0];
            final qty = item['quantity'] ?? 1;
            final product = item['product'];
            if (product is Map<String, dynamic>) {
              productDesc = '${product['name'] ?? 'Item'} x$qty';
            }
          }
        } catch (_) {}

        fetchedOrders.add({
          'id': order['id'].toString(),
          'name': customerName,
          'product': productDesc,
          'status': order['status'] ?? 'Pending',
          'price': (order['total_price'] ?? 0).toDouble(),
        });
      }

      if (mounted) {
        setState(() {
          _allOrders = fetchedOrders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching live orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _selectedFilter == 'All'
        ? _allOrders
        : _allOrders.where((o) => o['status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ORDERS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  Text('Total: ${_allOrders.length} Orders',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter,
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF30363D),
                      backgroundColor: const Color(0xFFE2E2E2),
                      onSelected: (bool selected) {
                        setState(() => _selectedFilter = filter);
                      },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      showCheckmark: false,
                      side: BorderSide.none,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchLiveOrders,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF30363D)))
                    : filteredOrders.isEmpty
                        ? ListView(children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Center(
                                child: Text('No $_selectedFilter orders found.',
                                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
                              ),
                            )
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              bool isDarkCard = order['status'] == 'Shipped';
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderDetailPage(orderId: int.parse(order['id'])),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDarkCard ? const Color(0xFF30363D) : const Color(0xFFE2E2E2),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ORD - ${order['id']}',
                                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDarkCard ? Colors.white : Colors.black)),
                                          const SizedBox(height: 2),
                                          Text(order['name'],
                                              style: TextStyle(fontSize: 15, color: isDarkCard ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                                          Text(order['product'],
                                              style: TextStyle(fontSize: 15, color: isDarkCard ? Colors.white70 : Colors.black54)),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          _buildStatusBadge(order['status']),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isDarkCard ? Colors.white : const Color(0xFF30363D),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text('₱ ${_formatCurrency(order['price'])}',
                                                style: TextStyle(fontWeight: FontWeight.bold, color: isDarkCard ? Colors.black : Colors.white)),
                                          )
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
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
        labelColor = const Color(0xFFA02B2B); bgColor = const Color(0xFFE5B5B5); break;
      case 'Shipped':
        labelColor = const Color(0xFF2B5B84); bgColor = const Color(0xFFB5D1E5); break;
      case 'Priority':
        labelColor = const Color(0xFFB8781B); bgColor = const Color(0xFFFBE0B2); break;
      default:
        labelColor = const Color(0xFF2B844A); bgColor = const Color(0xFFB5E5C4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}