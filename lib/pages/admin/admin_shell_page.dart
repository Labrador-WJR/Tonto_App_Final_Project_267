import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_inventory_page.dart';
import 'admin_orders_page.dart';
import 'admin_analytics_page.dart';       // Added
import 'admin_profile_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key});

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _currentIndex = 0;

  // Now 5 pages: Dashboard, Analytics, Inventory, Orders, Profile
  final List<Widget> _pages = const [
    AdminDashboardPage(),
    AdminAnalyticsPage(),
    AdminInventoryPage(),
    AdminOrdersPage(),
    AdminProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color darkBarColor = Color(0xFF30363D);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: darkBarColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ADMIN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/icons/logo.png',  
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.sports_esports, color: Colors.white, size: 28),
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: darkBarColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 28,
          items: [
            BottomNavigationBarItem(
              icon: _currentIndex == 0
                  ? Icon(Icons.home, color: Colors.white)
                  : Icon(Icons.home_outlined, color: Colors.white54),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 1
                  ? Icon(Icons.bar_chart, color: Colors.white)
                  : Icon(Icons.bar_chart_outlined, color: Colors.white54),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 2
                  ? Icon(Icons.inventory_2, color: Colors.white)
                  : Icon(Icons.inventory_2_outlined, color: Colors.white54),
              label: 'Inventory',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 3
                  ? Icon(Icons.receipt_long, color: Colors.white)
                  : Icon(Icons.receipt_long_outlined, color: Colors.white54),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: _currentIndex == 4
                  ? Icon(Icons.account_circle, color: Colors.white)
                  : Icon(Icons.account_circle_outlined, color: Colors.white54),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}