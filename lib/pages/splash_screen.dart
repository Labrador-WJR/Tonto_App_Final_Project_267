import 'package:flutter/material.dart';
import 'auth_landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to landing page after 3 seconds (static logo)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthLandingPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: Center(
        child: Image.asset(
          'assets/images/tonto_splash_screen.png',
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Text(
            'TONTO®',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Color(0xFF383E46),
            ),
          ),
        ),
      ),
    );
  }
}