import 'package:flutter/material.dart';

import 'settings_page.dart';
import 'checkout_page.dart';

// Data model for an order item, reusing the CartItem structure but adding a status
class OrderItem {
  final int id;
  final String name;
  final String imagePath;
  final double price;
  final int quantity;
  final String status; // Special for the profile page view

  OrderItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.price,
    required this.quantity,
    this.status = "Status: Lorem, Ipsum, Dolar", // Default as per image_20.png/image_21.png
  });
}

// Global list of mock orders, categorized for the different tabs
List<OrderItem> mockPendingOrders = [
  OrderItem(id: 301, name: "Pending Hoodie v1", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 302, name: "Pending Tee (Red)", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockShippingOrders = [
  OrderItem(id: 401, name: "Shipping Design 03", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockDeliveredOrders = [
  OrderItem(id: 501, name: "Delivered Cap (Blue)", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

List<OrderItem> mockCompletedOrders = [
  OrderItem(id: 601, name: "Completed Watch (Gold)", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 602, name: "Completed Shoes (White)", imagePath: 'placeholder', price: 200.00, quantity: 1),
  OrderItem(id: 603, name: "Completed Design 04", imagePath: 'placeholder', price: 200.00, quantity: 1),
];

// Profile Page Widget with State to handle tab switching
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // State to track the currently selected tab index
  int _selectedTabIndex = 0;

  // The tabs as a simple list of strings
  final List<String> _tabs = ['Pending', 'Shipping', 'Deliver', 'Completed'];

  // Reuse card styling for grey containers
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

    // Dynamic data loading based on selected tab
    List<OrderItem> currentOrders = [];
    switch (_selectedTabIndex) {
      case 0:
        currentOrders = mockPendingOrders;
        break;
      case 1:
        currentOrders = mockShippingOrders;
        break;
      case 2:
        currentOrders = mockDeliveredOrders;
        break;
      case 3:
        currentOrders = mockCompletedOrders;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/icons/logo.png', // The Tonto logo from image_18.png
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          // UPDATED: Settings icon now uses custom PNG and navigates to the SettingsPage
          IconButton(
            icon: Image.asset(
              'assets/icons/setting.png', // Uses the new asset
              width: 30, 
              height: 30, 
              fit: BoxFit.contain,
              // Fallback Material Icon if the asset isn't found
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.settings, color: Colors.white),
            ),
            onPressed: () {
              // Navigates to the new SettingsPage
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            
           // 1. User Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Circular Avatar Placeholder
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFD5D5D5),
                    child: Icon(Icons.person, size: 60, color: darkThemeColor),
                  ),
                  const SizedBox(width: 16),
                  
                  // Username
                  const Expanded(
                    child: Text(
                      'Username',
                      style: TextStyle(color: darkThemeColor, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  
                  // UPDATED: Uses the custom voucher.png asset instead of the % icon
                  IconButton(
                    icon: Image.asset(
                      'assets/icons/voucher.png', 
                      width: 60, // Perfect size for a header icon
                      height: 60,
                      fit: BoxFit.contain,
                      // Fallback icon just in case the image asset fails to load
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_offer, color: darkThemeColor, size: 28),
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
            
            // 2. Tab Selection Section (Pending, Shipping, etc.)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // Horizontal tab buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(_tabs.length, (index) {
                      final tabName = _tabs[index];
                      final isSelected = _selectedTabIndex == index;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTabIndex = index; // Rebuild with new data
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
                            // Line indicator below the selected tab
                            Container(
                              height: 2,
                              width: 60, // Width can be dynamic or static
                              color: isSelected ? darkThemeColor : Colors.transparent,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Divider line as per image_18.png
                  const Divider(color: darkThemeColor, thickness: 1),
                ],
              ),
            ),
            
            // 3. Conditional Content Section based on Tab Type
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: currentOrders.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'No orders in this state.',
                          style: TextStyle(color: darkThemeColor, fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true, // List is inside a ScrollView
                      physics: const NeverScrollableScrollPhysics(), // ScrollView handles scrolling
                      itemCount: currentOrders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: ProfileItemCard(
                            orderItem: currentOrders[index],
                            isCompletedTab: _selectedTabIndex == 3, // True if 'Completed' tab is selected
                            cardDecoration: cardDecoration, // Pass the shared decoration
                          ),
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

// Reusable card component for an individual order item
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
      decoration: cardDecoration, // Shared grey container decoration
      child: Row(
        children: [
          // Grey Image Placeholder from product designs
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46), // Darker grey for image container
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          
          // Order information and conditional action
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name from previous design
                Text(
                  orderItem.name,
                  style: const TextStyle(color: darkThemeColor, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16), // Spacing below name
                
                // --- Conditional Render based on Tab Type (referencing input images) ---
                if (isCompletedTab) ...[
                  // 1. Child for 'Completed' Tab: Dark "Rate" Button from image_22.png
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Align to right like image_22.png
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: darkThemeColor, // Dark button color
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
                            // Placeholder rating action
                            print('Rate button clicked for order ${orderItem.id}');
                          },
                          child: const Text(
                            'Rate',
                            style: TextStyle(
                              color: Colors.white, // White text for rate button
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // 2. Child for other Tabs: "Status: ..." Text from image_20.png and image_21.png
                  Text(
                    orderItem.status, // Uses status string from OrderItem data model
                    style: TextStyle(
                      color: darkThemeColor.withOpacity(0.7), // Faded status text
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