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

  // --- TOGGLE STATE ---
  bool _showCustomOrders = false;

  // --- STANDARD ORDERS STATE ---
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Shipping', 'Delivered', 'Completed'];
  List<Map<String, dynamic>> _allOrders = [];
  
  // --- CUSTOM ORDERS STATE ---
  List<Map<String, dynamic>> _customOrders = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveOrders();
    _fetchCustomOrders(); 
  }

  // ===========================================================================
  // FETCHING LOGIC
  // ===========================================================================

  Future<void> _fetchLiveOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('orders')
          .select('id, status, total_price, user_id, created_at')
          // --- CHANGED: ascending is now true for First In, First Out (FIFO) ---
          .order('created_at', ascending: true);

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
          if (!_showCustomOrders) _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching standard orders: $e');
      if (mounted && !_showCustomOrders) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCustomOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('custom_designs')
          .select('*')
          // --- CHANGED: ascending is now true for First In, First Out (FIFO) ---
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> fetchedCustoms = [];
      final List<dynamic> dataList = response; 

      for (var row in dataList) {
        final item = row as Map<String, dynamic>;
        String customerName = 'Unknown Customer';
        
        if (item['user_id'] != null) {
          try {
            final profile = await _supabase
                .from('profiles')
                .select('full_name')
                .eq('id', item['user_id'])
                .maybeSingle();
            if (profile != null) customerName = profile['full_name'] ?? customerName;
          } catch (_) {}
        }
        
        fetchedCustoms.add({
          'id': item['id'],
          'user_id': item['user_id'],
          'description': item['description'] ?? 'No description',
          'image_url': item['image_url'] ?? '',
          'status': item['status'] ?? 'Pending',
          'created_at': item['created_at'],
          'customer_name': customerName,
        });
      }

      if (mounted) {
        setState(() {
          _customOrders = fetchedCustoms;
          if (_showCustomOrders) _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching custom orders: $e');
      if (mounted) {
        if (_showCustomOrders) setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Load Error: $e')));
      }
    }
  }

  // ===========================================================================
  // UPDATING CUSTOM ORDER STATUS
  // ===========================================================================
  Future<void> _updateCustomStatus(int id, String newStatus) async {
    final index = _customOrders.indexWhere((o) => o['id'] == id);
    if (index == -1) return;
    
    final oldStatus = _customOrders[index]['status'];
    
    setState(() {
      _customOrders[index]['status'] = newStatus;
    });

    try {
      await _supabase.from('custom_designs').update({'status': newStatus}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Custom Request marked as $newStatus'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customOrders[index]['status'] = oldStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red)
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final filteredStandardOrders = _selectedFilter == 'All'
        ? _allOrders
        : _allOrders.where((o) => o['status'] == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ORDERS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  Text(
                    'Total: ${_showCustomOrders ? _customOrders.length : _allOrders.length} ${_showCustomOrders ? "Requests" : "Orders"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),

            // --- TOGGLE SWITCH ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _showCustomOrders = false);
                        _fetchLiveOrders();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showCustomOrders ? const Color(0xFF30363D) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Store Orders', 
                            style: TextStyle(color: !_showCustomOrders ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
                          )
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _showCustomOrders = true);
                        _fetchCustomOrders();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showCustomOrders ? const Color(0xFF30363D) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text('Custom Requests', 
                            style: TextStyle(color: _showCustomOrders ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)
                          )
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- STANDARD FILTERS ---
            if (!_showCustomOrders)
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

            // --- LIST VIEWS ---
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF30363D)))
                  : _showCustomOrders 
                      ? _buildCustomOrdersList() 
                      : _buildStandardOrdersList(filteredStandardOrders),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // STANDARD ORDERS UI
  // ===========================================================================
  Widget _buildStandardOrdersList(List<Map<String, dynamic>> filteredOrders) {
    return RefreshIndicator(
      onRefresh: _fetchLiveOrders,
      color: const Color(0xFF30363D),
      child: filteredOrders.isEmpty
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
                bool isDarkCard = order['status'] == 'Completed'; 
                
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailPage(orderId: int.parse(order['id'])),
                      ),
                    ).then((_) => _fetchLiveOrders());
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ORD - ${order['id']}',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDarkCard ? Colors.white : Colors.black)),
                              const SizedBox(height: 2),
                              Text(order['name'],
                                  overflow: TextOverflow.ellipsis, 
                                  style: TextStyle(fontSize: 15, color: isDarkCard ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                              Text(order['product'],
                                  overflow: TextOverflow.ellipsis, 
                                  style: TextStyle(fontSize: 15, color: isDarkCard ? Colors.white70 : Colors.black54)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color labelColor;
    Color bgColor;
    switch (status) {
      case 'Pending':
        labelColor = const Color(0xFFA02B2B); bgColor = const Color(0xFFE5B5B5); break;
      case 'Shipping':
        labelColor = const Color(0xFF2B5B84); bgColor = const Color(0xFFB5D1E5); break;
      case 'Delivered':
        labelColor = const Color(0xFFB8781B); bgColor = const Color(0xFFFBE0B2); break;
      case 'Completed':
      default:
        labelColor = const Color(0xFF2B844A); bgColor = const Color(0xFFB5E5C4);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  // ===========================================================================
  // CUSTOM ORDERS UI
  // ===========================================================================
  Widget _buildCustomOrdersList() {
    return RefreshIndicator(
      onRefresh: _fetchCustomOrders,
      color: const Color(0xFF30363D),
      child: _customOrders.isEmpty
          ? ListView(children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: Text('No custom requests found.',
                      style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold)),
                ),
              )
            ])
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _customOrders.length,
              itemBuilder: (context, index) {
                final order = _customOrders[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Image Thumbnail ---
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: const Color(0xFF30363D), borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            order['image_url'] ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 30)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // --- Text Info ---
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order['customer_name'] ?? 'Unknown', 
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(order['description'] ?? 'No description', 
                                maxLines: 3, overflow: TextOverflow.ellipsis, 
                                style: const TextStyle(color: Colors.black54, fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // --- Interactive Dropdown Badge ---
                      Column(
                        children: [
                          _buildCustomStatusBadge(order),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Dedicated interactive dropdown for custom requests
  Widget _buildCustomStatusBadge(Map<String, dynamic> request) {
    String status = request['status'] ?? 'Pending';
    Color labelColor;
    Color bgColor;
    
    switch (status) {
      case 'Pending':
        labelColor = const Color(0xFFA02B2B); bgColor = const Color(0xFFE5B5B5); break;
      case 'Approved':
        labelColor = const Color(0xFF2B5B84); bgColor = const Color(0xFFB5D1E5); break;
      case 'Rejected':
        labelColor = Colors.white; bgColor = Colors.black54; break;
      case 'Completed':
      default:
        labelColor = const Color(0xFF2B844A); bgColor = const Color(0xFFB5E5C4);
    }

    List<String> validStatuses = ['Pending', 'Approved', 'Rejected', 'Completed'];
    if (!validStatuses.contains(status)) {
      validStatuses.add(status);
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: status,
          dropdownColor: bgColor,
          icon: Icon(Icons.arrow_drop_down, color: labelColor),
          isDense: true,
          style: TextStyle(color: labelColor, fontWeight: FontWeight.bold, fontSize: 12),
          items: validStatuses.map((String s) {
            return DropdownMenuItem<String>(
              value: s,
              child: Text(s, style: TextStyle(color: labelColor, fontWeight: FontWeight.bold)),
            );
          }).toList(),
          onChanged: (String? newStatus) {
            if (newStatus != null && newStatus != status) {
              _updateCustomStatus(request['id'], newStatus);
            }
          },
        ),
      ),
    );
  }
}