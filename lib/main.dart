import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_screen.dart';           // ← new import
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/favorites_page.dart';
import 'pages/custom_design_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bfpfmyupksojdhjmobqm.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmcGZteXVwa3NvamRoam1vYnFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNjcyOTQsImV4cCI6MjA5MzY0MzI5NH0.FGUZhw3Egn5CvbUFHxtLZIDN9ZziJzjZVTWySq1rzmA',
  );

  runApp(const ECommerceApp());
}

class ECommerceApp extends StatelessWidget {
  const ECommerceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TONTO - Local Wears Local',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: const Color(0xFF383E46),
      ),
      home: const SplashScreen(),   // ← splash screen first
    );
  }
}

// ======== MainScreen class (unchanged) ========
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
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (context) => const HomePage()),
          ),
          Navigator(
            key: _navigatorKeys[1],
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (context) => const CustomSectionRootWidget()),
          ),
          Navigator(
            key: _navigatorKeys[2],
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
          ),
          Navigator(
            key: _navigatorKeys[3],
            onGenerateRoute: (_) =>
                MaterialPageRoute(builder: (context) => const ProfilePage()),
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
            _buildNavItem('assets/icons/home.png', 'assets/icons/home_highlight.png', 0),
            _buildNavItem('assets/icons/custom.png', 'assets/icons/custom_highlight.png', 1),
            _buildNavItem('assets/icons/favorite.png', 'assets/icons/favorite_highlight.png', 2),
            _buildNavItem('assets/icons/profile.png', 'assets/icons/profile_highlight.png', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String defaultIcon, String highlightedIcon, int index) {
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
            isSelected ? highlightedIcon : defaultIcon,
            width: 26,
            height: 26,
            color: isSelected ? null : Colors.white,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.circle,
              size: 26,
              color: isSelected ? darkThemeColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}