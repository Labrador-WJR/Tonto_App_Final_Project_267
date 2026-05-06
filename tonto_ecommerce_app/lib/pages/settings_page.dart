import 'package:flutter/material.dart';
import 'address_page.dart';

// ============================================================================
// 12. SETTINGS PAGE SECTION
// ============================================================================

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238); // Shared theme color

    // Reusable styling for the grey container (matches profile/favorites cards)
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
      backgroundColor: const Color(0xFFF5F5F5), // Light background
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
          // Custom Tonto Logo on the right per image_23.png
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/icons/logo.png', width: 40, height: 40, fit: BoxFit.contain),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Settings container per image_23.png
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: cardDecoration,
              child: GestureDetector(
                // Opens the EditingDetailsPage when clicked
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EditingProfilePage()));
                },
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, size: 28, color: darkThemeColor), // Edit icon
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Profile Details',
                        style: TextStyle(color: darkThemeColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: darkThemeColor), // Arrow icon
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // --- Standard Bottom Navigation Bar (reused for full consistency) ---
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
  // --- STATE VARIABLES ---
  String _currentAddress = 'Lorem, Ipsum, Dolar'; 
  bool _isPasswordExpanded = false; 
  bool _isCurrentPasswordVisible = false; 
  
  final TextEditingController _currentPasswordController = TextEditingController();

  // Shared theme color
  final Color darkThemeColor = const Color(0xFF2D3238);

  // Helper: Reusable grey shadow container styling
  BoxDecoration _getCardDecoration() {
    return BoxDecoration(
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
  }

  // Helper: Build a standard grey input field 
  Widget _buildDetailInputField(String label, String hintText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:', 
            style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: _getCardDecoration(), 
            child: TextField(
              style: TextStyle(color: darkThemeColor),
              decoration: InputDecoration(
                hintText: hintText, 
                border: InputBorder.none, 
                contentPadding: const EdgeInsets.all(16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Build the interactive cards (Address and Password Header)
  Widget _buildInteractiveCardHeader({
    required IconData icon,
    required String label,
    required String contentText,
    required VoidCallback onTap,
    bool isBoldContent = false,
    required IconData suffixIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: _getCardDecoration().copyWith(
            border: Border.all(color: Colors.black45),
          ), 
          child: Row(
            children: [
              Icon(icon, size: 28, color: darkThemeColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$label:',
                      style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contentText,
                      style: TextStyle(
                        color: darkThemeColor,
                        fontSize: 14,
                        fontWeight: isBoldContent ? FontWeight.bold : FontWeight.normal, 
                      ),
                    ),
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
        titleSpacing: 0,
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editing Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/icons/logo.png', width: 40, height: 40, fit: BoxFit.contain),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  _buildDetailInputField('Username', 'User Name'),
                  _buildDetailInputField('First Name', 'Lorem Ipsum'),
                  _buildDetailInputField('Last Name', 'Dolar'),
                  _buildDetailInputField('Contact Number', '+639123456789'),
                  _buildDetailInputField('Email', 'loremipsum.dolar@email.com'),
                  _buildDetailInputField('Email', 'loremipsum.dolar@email.com'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 2. Dynamic Shipping Address
            _buildInteractiveCardHeader(
              icon: Icons.location_on,
              label: 'Shipping Address',
              contentText: _currentAddress, 
              isBoldContent: true, 
              suffixIcon: Icons.arrow_forward_ios,
              onTap: () async {
                final newAddress = await Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => const AddressPage(
                      initialSelectedAddress: 'Lorem, Ipsum, Dolar', 
                    ),
                  ),
                );

                if (newAddress != null && newAddress is String) {
                  setState(() {
                    _currentAddress = newAddress; 
                  });
                }
              },
            ),

            // 3. Expandable Password Section 
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              // FIXED: Replaced 'curve' with 'sizeCurve' to fix the error
              sizeCurve: Curves.easeInOut, 
              firstCurve: Curves.easeInOut,
              crossFadeState: _isPasswordExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              
              // Child 1: Collapsed State
              firstChild: _buildInteractiveCardHeader(
                icon: Icons.lock,
                label: 'Details',
                contentText: 'Change Password',
                isBoldContent: false,
                suffixIcon: Icons.keyboard_arrow_down, 
                onTap: () {
                  setState(() { _isPasswordExpanded = true; }); 
                },
              ),
              
              // Child 2: Expanded State
              secondChild: Padding(
                padding: const EdgeInsets.only(bottom: 20.0), 
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: _getCardDecoration().copyWith(
                    border: Border.all(color: Colors.black45),
                  ), 
                  child: Column(
                    children: [
                      // Header Row (Click to collapse)
                      GestureDetector(
                        onTap: () {
                          setState(() { _isPasswordExpanded = false; }); 
                        },
                        child: Row(
                          children: [
                            Icon(Icons.lock, size: 28, color: darkThemeColor),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Details:',
                                    style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Change Password',
                                    style: TextStyle(color: darkThemeColor, fontSize: 14),
                                   ),
                                ],
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_up, size: 20, color: darkThemeColor),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      const Divider(color: Colors.black45, thickness: 1),
                      const SizedBox(height: 20),

                      // Current Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Password:', 
                            style: TextStyle(color: darkThemeColor.withOpacity(0.7), fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: _getCardDecoration(), 
                            child: TextField(
                              controller: _currentPasswordController, 
                              obscureText: !_isCurrentPasswordVisible, 
                              style: TextStyle(color: darkThemeColor),
                              decoration: InputDecoration(
                                hintText: '*************', 
                                border: InputBorder.none, 
                                contentPadding: const EdgeInsets.all(16.0),
                                suffixIcon: IconButton(
                                  icon: Image.asset(
                                    'assets/icons/eye.png', 
                                    width: 24, 
                                    height: 24,
                                    fit: BoxFit.contain,
                                    color: _isCurrentPasswordVisible ? const Color(0xFF383E46) : Colors.black45,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      _isCurrentPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: darkThemeColor,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                                    });
                                  },
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
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details Saved Successfully!')));
                  Navigator.pop(context); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkThemeColor, 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40), 
          ],
        ),
      ),
    );
  }
}