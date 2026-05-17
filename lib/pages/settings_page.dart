import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'address_page.dart';
import 'login_page.dart'; // --- ADDED: Import for login page routing ---

// ============================================================================
// 12. SETTINGS PAGE SECTION
// ============================================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

// --- NEW: Log Out Function with Confirmation Dialog ---
  Future<void> _handleLogout(BuildContext context) async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF383E46),
        title: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      // Tell Supabase to end the active session
      await Supabase.instance.client.auth.signOut();
      
      if (context.mounted) {
        // --- FIXED: rootNavigator: true forces the app to destroy the Bottom Navigation Bar ---
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false, 
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error logging out. Please try again.')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238); 

    final cardDecoration = BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          spreadRadius: 1,
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/icons/logo.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.pets, color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Edit Profile Details Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: cardDecoration,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditingProfilePage()));
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, size: 28, color: darkThemeColor), 
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Profile Details',
                        style: TextStyle(color: darkThemeColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: darkThemeColor), 
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. NEW: Log Out Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: cardDecoration,
              child: GestureDetector(
                onTap: () => _handleLogout(context), // Triggers the logout confirmation
                child: const Row(
                  children: [
                    Icon(Icons.logout, size: 28, color: Colors.redAccent), 
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Log Out',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 13. EDITING PROFILE PAGE SECTION
// ============================================================================

class EditingProfilePage extends StatefulWidget {
  const EditingProfilePage({super.key});

  @override
  State<EditingProfilePage> createState() => _EditingProfilePageState();
}

class _EditingProfilePageState extends State<EditingProfilePage> {
  // --- SUPABASE & DATA STATE ---
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;

  String _currentAddress = 'Loading...'; 
  bool _isPasswordExpanded = false; 
  bool _isPasswordVisible = false; 
  
  // Controllers for our text fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  final Color darkThemeColor = const Color(0xFF2D3238);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FETCH USER DATA FROM SUPABASE ---
  Future<void> _fetchUserData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch Profile Data
      final profile = await _supabase.from('profiles').select().eq('id', user.id).single();
      
      // 2. Fetch their Default Address
      final addressRes = await _supabase.from('user_addresses').select('address_string').eq('user_id', user.id).eq('is_default', true).maybeSingle();

      if (mounted) {
        setState(() {
          // Split full name into first and last
          final fullName = profile['full_name'] as String? ?? '';
          final nameParts = fullName.split(' ');
          _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
          _lastNameController.text = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          _contactNumberController.text = profile['contact_number'] ?? '';
          _emailController.text = profile['email'] ?? user.email ?? '';

          _currentAddress = addressRes != null ? addressRes['address_string'] : 'No default address set';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SAVE UPDATED DATA TO SUPABASE ---
  Future<void> _saveChanges() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Combine names and update public.profiles table
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      
      await _supabase.from('profiles').update({
        'full_name': fullName.trim(),
        'contact_number': _contactNumberController.text.trim(),
        'email': _emailController.text.trim(), 
      }).eq('id', user.id);

      // 2. Update Password (if they typed a new one)
      if (_newPasswordController.text.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(
          password: _newPasswordController.text,
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details Saved Successfully! 🎉')));
        Navigator.pop(context); 
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Error updating profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update details.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
    );
  }

  Widget _buildDetailInputField(String label, String hintText, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12)),
          const SizedBox(height: 6),
          Container(
            decoration: _getCardDecoration(), 
            child: TextField(
              controller: controller,
              style: TextStyle(color: darkThemeColor),
              decoration: InputDecoration(hintText: hintText, border: InputBorder.none, contentPadding: const EdgeInsets.all(16.0)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCardHeader({required IconData icon, required String label, required String contentText, required VoidCallback onTap, bool isBoldContent = false, required IconData suffixIcon}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: _getCardDecoration().copyWith(border: Border.all(color: Colors.black45)), 
          child: Row(
            children: [
              Icon(icon, size: 28, color: darkThemeColor), const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label:', style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12)), const SizedBox(height: 2),
                    Text(contentText, style: TextStyle(color: darkThemeColor, fontSize: 14, fontWeight: isBoldContent ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              Icon(suffixIcon, size: 20, color: darkThemeColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        titleSpacing: 0, backgroundColor: darkThemeColor, foregroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Editing Details'),
        actions: [Padding(padding: const EdgeInsets.only(right: 16.0), child: Image.asset('assets/icons/logo.png', width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.pets, color: Colors.white)))],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                // 1. Profile Field Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                  decoration: _getCardDecoration().copyWith(borderRadius: BorderRadius.circular(16)), 
                  child: Column(
                    children: [
                      _buildDetailInputField('First Name', 'Enter first name', _firstNameController),
                      _buildDetailInputField('Last Name', 'Enter last name', _lastNameController),
                      _buildDetailInputField('Contact Number', 'e.g. +639123456789', _contactNumberController),
                      _buildDetailInputField('Email', 'your.email@example.com', _emailController),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 2. Dynamic Shipping Address
                _buildInteractiveCardHeader(
                  icon: Icons.location_on, label: 'Shipping Address', contentText: _currentAddress, isBoldContent: true, suffixIcon: Icons.arrow_forward_ios,
                  onTap: () async {
                    final newAddress = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddressPage(initialSelectedAddress: _currentAddress)));
                    if (newAddress != null && newAddress is String) {
                      setState(() { _currentAddress = newAddress; });
                    }
                  },
                ),

                // 3. Expandable Password Section 
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300), sizeCurve: Curves.easeInOut, firstCurve: Curves.easeInOut,
                  crossFadeState: _isPasswordExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  
                  firstChild: _buildInteractiveCardHeader(
                    icon: Icons.lock, label: 'Details', contentText: 'Change Password', isBoldContent: false, suffixIcon: Icons.keyboard_arrow_down, 
                    onTap: () { setState(() { _isPasswordExpanded = true; }); },
                  ),
                  
                  secondChild: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0), 
                    child: Container(
                      padding: const EdgeInsets.all(16.0), decoration: _getCardDecoration().copyWith(border: Border.all(color: Colors.black45)), 
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () { setState(() { _isPasswordExpanded = false; }); },
                            child: Row(
                              children: [
                                Icon(Icons.lock, size: 28, color: darkThemeColor), const SizedBox(width: 16),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Details:', style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12)), const SizedBox(height: 2), Text('Change Password', style: TextStyle(color: darkThemeColor, fontSize: 14))])),
                                Icon(Icons.keyboard_arrow_up, size: 20, color: darkThemeColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20), const Divider(color: Colors.black45, thickness: 1), const SizedBox(height: 20),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Password:', style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12)), const SizedBox(height: 6),
                              Container(
                                decoration: _getCardDecoration(), 
                                child: TextField(
                                  controller: _newPasswordController, obscureText: !_isPasswordVisible, style: TextStyle(color: darkThemeColor),
                                  decoration: InputDecoration(
                                    hintText: 'Enter new password...', border: InputBorder.none, contentPadding: const EdgeInsets.all(16.0),
                                    suffixIcon: IconButton(
                                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: _isPasswordVisible ? const Color(0xFF383E46) : Colors.black45),
                                      onPressed: () { setState(() { _isPasswordVisible = !_isPasswordVisible; }); },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                
                // 4. Save Button
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(backgroundColor: darkThemeColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40), 
              ],
            ),
          ),
    );
  }
}