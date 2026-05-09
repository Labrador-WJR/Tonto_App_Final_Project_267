import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/data_models.dart';
import '../services/supabase_service.dart';
import 'settings_page.dart';
import 'checkout_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['pending', 'shipping', 'delivered', 'completed'];
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
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);
    final userId = Supabase.instance.client.auth.currentUser?.id;

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
          ),
        ),
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png',
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  const Expanded(
                    child: Text(
                      'Username',
                      style: TextStyle(
                          color: darkThemeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/voucher.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.local_offer, color: darkThemeColor, size: 28),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const VoucherPage()),
                      );
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
                              tabName[0].toUpperCase() + tabName.substring(1),
                              style: TextStyle(
                                fontSize: 14,
                                color: darkThemeColor,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
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
              child: userId == null
                  ? const Center(child: Text('Not logged in'))
                  : FutureBuilder<List<OrderModel>>(
                      future: SupabaseService.getOrders(userId,
                          status: _tabs[_selectedTabIndex]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(
                              child: Text('Failed to load orders'));
                        }
                        final orders = snapshot.data ?? [];
                        if (orders.isEmpty) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('No orders in this state.',
                                style: TextStyle(
                                    color: darkThemeColor, fontSize: 16)),
                          ));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            // Show first item's product name if available
                            final itemName = (order.items != null &&
                                    order.items!.isNotEmpty)
                                ? order.items!.first.product?.name ??
                                    'Unknown Product'
                                : 'Order #${order.id.substring(0, 8)}';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
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
                                      child: const Center(
                                        child: Icon(Icons.image,
                                            size: 36, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(itemName,
                                              style: const TextStyle(
                                                  color: darkThemeColor,
                                                  fontSize: 14)),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Total: P ${order.totalAmount?.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                                color: darkThemeColor
                                                    .withOpacity(0.7),
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedTabIndex == 3)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: darkThemeColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: TextButton(
                                          onPressed: () {
                                            // Rate function could be implemented here
                                          },
                                          child: const Text('Rate',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}