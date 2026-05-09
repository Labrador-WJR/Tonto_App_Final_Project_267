import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/favorites_page.dart';
import 'pages/custom_design_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ygscyfcvofdrpnwvblch.supabase.co',
    anonKey: 'sb_publishable_bUc4u1hzQWoDPNOKz-F4wA_NnJO5hqZ',
  );

  runApp(const ECommerceApp());
}

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
      home: const AuthGate(),
    );
  }
}

// This widget listens to auth state and shows LoginPage or MainScreen
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is logged in, skip splash and go directly to main screen later.
      // We'll still show splash briefly then navigate.
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      });
    } else {
      // Not logged in, show splash then login
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the same splash screen while checking auth
    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/Tonto_luancher_logo.png',
              width: 160,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.shopping_bag, size: 80, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              "Local Wears Local",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MAIN SCREEN (unchanged from your original, except it's now used from AuthGate)
// ============================================================================

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
            _navigatorKeys[_currentIndex] = GlobalKey<NavigatorState>();
            _currentIndex = index;
          } else {
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