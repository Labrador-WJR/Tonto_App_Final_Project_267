import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';
import 'admin/admin_shell_page.dart';   // <-- new admin import

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  // ---------- Hardcoded admin credentials ----------
  static const String _adminEmail = 'admin@tonto.com';
  static const String _adminPassword = 'admin123';

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Admin check – bypass Supabase
    if (email == _adminEmail && password == _adminPassword) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminShellPage()),
        );
      }
      return;
    }

    // Normal Supabase login
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... rest of the build method stays EXACTLY the same as the original you provided ...
    // (I'm omitting it for brevity – just keep the original build code.)
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand / Logo
                Image.asset(
                  'assets/images/tonto_splash_screen.png',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    'TONTO®',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFF383E46)),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF383E46))),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email', hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF383E46), width: 1.5)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    hintText: 'Password', hintStyle: const TextStyle(color: Colors.grey),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF383E46), width: 1.5)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Log In', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                  child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF383E46), fontWeight: FontWeight.w500, decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? ", style: TextStyle(color: Color(0xFF666666))),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                      child: const Text('Sign up', style: TextStyle(color: Color(0xFF383E46), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('Sign up with', style: TextStyle(color: Colors.grey, fontSize: 13))),
                    Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(Icons.g_mobiledata, 'Google'),
                    const SizedBox(width: 20),
                    _socialButton(Icons.facebook, 'Facebook'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Icon(icon, size: 32, color: const Color(0xFF383E46)),
      ),
    );
  }
}