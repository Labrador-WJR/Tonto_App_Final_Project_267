import 'package:flutter/material.dart';
import 'pages/custom_design_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/favorites_page.dart';

void main() {
  runApp(const ECommerceApp());
}

// ============================================================================
// 2. ROOT APP & MAIN NAVIGATION
// ============================================================================

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce UI', 
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), 
        primaryColor: const Color(0xFF2D3238), 
      ),
      home: const MainScreen(), 
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
    GlobalKey<NavigatorState>(), 
  ];

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238); 

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Navigator(
            key: _navigatorKeys[0], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[1], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const CustomSectionRootWidget(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[2], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const FavoritesPage(),
            ),
          ),
          Navigator(
            key: _navigatorKeys[3], 
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => const ProfilePage(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 65, 
        color: darkThemeColor,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, 
          crossAxisAlignment: CrossAxisAlignment.end, 
          children: [
            _buildCustomNavItem('assets/icons/home.png', 'assets/icons/home_highlight.png', 0),
            _buildCustomNavItem('assets/icons/custom.png', 'assets/icons/custom_highlight.png', 1),
            _buildCustomNavItem('assets/icons/favorite.png', 'assets/icons/favorite_highlight.png', 2),
            _buildCustomNavItem('assets/icons/profile.png', 'assets/icons/profile_highlight.png', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomNavItem(String defaultPath, String highlightPath, int index) {
    bool isSelected = _currentIndex == index; 
    const darkThemeColor = Color(0xFF2D3238); 
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_currentIndex != index) {
            // MAGIC FIX: Completely destroy the memory of the tab we are LEAVING
            _navigatorKeys[_currentIndex] = GlobalKey<NavigatorState>();
            // Then switch to the new tab
            _currentIndex = index; 
          } else {
            // If they tap the tab they are already on, pop to root
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 14, bottom: 14), 
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD9D9D9) : Colors.transparent,
          borderRadius: isSelected 
              ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                )
              : BorderRadius.zero,
        ),
       child: Transform.scale(
          scale: isSelected ? 1.6 : 1.0, 
          child: Image.asset(
            isSelected ? highlightPath : defaultPath, 
            width: 26,
            height: 26,
            color: isSelected ? null : Colors.white, 
            errorBuilder: (context, error, stackTrace) => Icon(Icons.circle, size: 26, color: isSelected ? darkThemeColor : Colors.white),
          ),
       ),  
      ),
    );
  }
}

