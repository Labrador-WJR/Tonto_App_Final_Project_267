import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import 'settings_page.dart';
import 'checkout_page.dart';

class OrderItem {
  final int id;
  final String name;
  final String image; 
  final double price;
  final int quantity;
  final String status;

  OrderItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.status = "Status: Pending", 
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  List<OrderItem> _allOrderItems = [];
  String _userName = 'Loading...';
  bool _isLoading = true;

  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Pending', 'Shipping', 'Deliver', 'Completed'];

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
  void initState() {
    super.initState();
    _fetchProfileAndOrders();
  }

  // --- SUPABASE FETCH FUNCTION (Used for initial load AND pull-to-refresh) ---
  Future<void> _fetchProfileAndOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profileResponse = await _supabase.from('profiles').select('full_name').eq('id', user.id).single();

      final ordersResponse = await _supabase
          .from('orders')
          .select('*, order_items(*, products(*))')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      List<OrderItem> loadedItems = [];

      for (var order in ordersResponse) {
        final status = order['status']; 
        final items = order['order_items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final product = item['products'] ?? {};
          final dbImageUrl = product['image_url'] ?? product['image'] ?? product['imageUrl'] ?? '';

          loadedItems.add(OrderItem(
            id: item['id'],
            name: product['name'] ?? 'Unknown Item',
            image: dbImageUrl, 
            price: double.tryParse(item['price'].toString()) ?? 0.0,
            quantity: item['quantity'] ?? 1,
            status: 'Status: $status',
          ));
        }
      }

      if (mounted) {
        setState(() {
          _userName = profileResponse['full_name'] ?? 'Shopper';
          _allOrderItems = loadedItems;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile/orders: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    List<OrderItem> currentOrders = [];
    if (!_isLoading) {
      switch (_selectedTabIndex) {
        case 0:
          currentOrders = _allOrderItems.where((item) => item.status.contains('Pending')).toList();
          break;
        case 1:
          currentOrders = _allOrderItems.where((item) => item.status.contains('Shipping')).toList();
          break;
        case 2:
          currentOrders = _allOrderItems.where((item) => item.status.contains('Deliver')).toList();
          break;
        case 3:
          currentOrders = _allOrderItems.where((item) => item.status.contains('Completed')).toList();
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white),
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png', 
              width: 30, 
              height: 30, 
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          // --- ADDED: RefreshIndicator wrapping the scroll view ---
          : RefreshIndicator(
              onRefresh: _fetchProfileAndOrders,
              color: darkThemeColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // --- ADDED: Forces scrollability for refresh ---
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Color(0xFFD5D5D5),
                            child: Icon(Icons.person, size: 60, color: darkThemeColor),
                          ),
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Text(
                              _userName,
                              style: const TextStyle(color: darkThemeColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          
                          IconButton(
                            icon: Image.asset(
                              'assets/icons/voucher.png', 
                              width: 60, 
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_offer, color: darkThemeColor, size: 28),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const VoucherPage()));
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: List.generate(_tabs.length, (index) {
                              final tabName = _tabs[index];
                              final isSelected = _selectedTabIndex == index;
                              
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedTabIndex = index;
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
                                    Container(
                                      height: 2,
                                      width: 60, 
                                      color: isSelected ? darkThemeColor : Colors.transparent,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: darkThemeColor, thickness: 1),
                        ],
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: currentOrders.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 80.0), // Increased padding to make empty state look better
                                child: Text(
                                  'No orders in this state.',
                                  style: TextStyle(color: darkThemeColor, fontSize: 16),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true, 
                              physics: const NeverScrollableScrollPhysics(), // Main SingleChildScrollView handles the scrolling
                              itemCount: currentOrders.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: ProfileItemCard(
                                    orderItem: currentOrders[index],
                                    isCompletedTab: _selectedTabIndex == 3, 
                                    cardDecoration: cardDecoration, 
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 100), // Added bottom spacing so content isn't hidden behind nav bar
                  ],
                ),
              ),
            ),
    );
  }
}

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
      decoration: cardDecoration, 
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46), 
              borderRadius: BorderRadius.circular(8),
            ),
            child: orderItem.image.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      orderItem.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  )
                : const Center(child: Icon(Icons.image, size: 36, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  orderItem.name,
                  style: const TextStyle(color: darkThemeColor, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16), 
                
                if (isCompletedTab) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, 
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: darkThemeColor, 
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
                            print('Rate button clicked for order item ${orderItem.id}');
                          },
                          child: const Text(
                            'Rate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    orderItem.status, 
                    style: TextStyle(
                      color: darkThemeColor.withOpacity(0.7), 
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