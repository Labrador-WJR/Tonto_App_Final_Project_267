import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ADDED: Supabase import
import '../models/data_models.dart';

class AddressPage extends StatefulWidget {
  final String initialSelectedAddress;
  const AddressPage({super.key, required this.initialSelectedAddress});
  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  // --- SUPABASE STATE ---
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _savedAddresses = [];
  bool _isLoading = true;

  late String _currentSelectedAddress;
  bool _showAddForm = false;

  final cardDecorationLight = BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);
  final cardDecorationDark = BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);

  @override
  void initState() {
    super.initState();
    _currentSelectedAddress = widget.initialSelectedAddress;
    _fetchAddresses();
  }

  // --- FETCH ADDRESSES FROM DB ---
  Future<void> _fetchAddresses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('user_addresses')
          .select('*')
          .eq('user_id', user.id)
          .order('is_default', ascending: false) // Puts default address at the top!
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _savedAddresses = List<Map<String, dynamic>>.from(response);
          // If they don't have a selected address but have a default, auto-select it
          if (_currentSelectedAddress == 'No address selected' && _savedAddresses.isNotEmpty) {
            _currentSelectedAddress = _savedAddresses[0]['address_string'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- SAVE NEW ADDRESS TO DB ---
  Future<void> _saveNewAddress(String newAddressString, bool isDefault) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // If setting as default, remove default status from all their other addresses first
      if (isDefault) {
        await _supabase.from('user_addresses').update({'is_default': false}).eq('user_id', user.id);
      }

      await _supabase.from('user_addresses').insert({
        'user_id': user.id,
        'address_string': newAddressString,
        'is_default': isDefault,
      });

      // Refresh the list from the database
      await _fetchAddresses();
      
      setState(() {
        _currentSelectedAddress = newAddressString; 
        _showAddForm = false; 
      });

      // Go back to checkout with the new address selected
      if (mounted) {
        Navigator.pop(context, newAddressString);
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DELETE ADDRESS FROM DB ---
  Future<void> _deleteAddress(int addressId, int index) async {
    try {
      await _supabase.from('user_addresses').delete().eq('id', addressId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
      // If it fails, refresh the list to fix the UI
      _fetchAddresses();
    }
  }


  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text('Address'), backgroundColor: darkThemeColor, foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showAddForm) { setState(() { _showAddForm = false; }); } else { Navigator.pop(context, _currentSelectedAddress); }
          },
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                 // Map Placeholder
                  Container(
                    height: 180, padding: const EdgeInsets.all(16.0), decoration: cardDecorationLight,
                    child: Stack(
                      children: [
                        const Center(child: Text('Give access to location', style: TextStyle(color: darkThemeColor, fontSize: 16))),
                        Positioned(
                          bottom: 12, 
                          right: 12, 
                          child: Container(
                            decoration: const BoxDecoration(
                              color: darkThemeColor, 
                              shape: BoxShape.circle 
                            ), 
                            child: IconButton(
                              icon: const Icon(Icons.location_on, color: Colors.white), 
                              onPressed: () {}
                            )
                          )
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!_showAddForm) ...[
                    if (_savedAddresses.isEmpty)
                       const Padding(
                         padding: EdgeInsets.all(32.0),
                         child: Text('No saved addresses yet.', style: TextStyle(color: Colors.grey)),
                       )
                    else
                      ListView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _savedAddresses.length,
                        itemBuilder: (context, index) {
                          final addressItem = _savedAddresses[index];
                          final addressString = addressItem['address_string'];
                          final addressId = addressItem['id'];
                          bool isSelected = addressString == _currentSelectedAddress;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Dismissible(
                              key: ValueKey(addressId), direction: DismissDirection.horizontal,
                              background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                              secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                              onDismissed: (direction) {
                                // Trigger database delete
                                _deleteAddress(addressId, index);

                                setState(() {
                                  _savedAddresses.removeAt(index);
                                  if (_currentSelectedAddress == addressString) _currentSelectedAddress = 'No address selected';
                                });
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address removed.'), duration: Duration(seconds: 2)));
                              },
                              child: GestureDetector(
                                onTap: () { setState(() { _currentSelectedAddress = addressString; }); },
                                child: Container(
                                  padding: const EdgeInsets.all(12.0), decoration: isSelected ? cardDecorationDark : cardDecorationLight,
                                  child: Row(children: [
                                    Icon(Icons.location_on, color: isSelected ? Colors.white : darkThemeColor, size: 24), 
                                    const SizedBox(width: 12), 
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(addressString, style: TextStyle(color: isSelected ? Colors.white : darkThemeColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                          if (addressItem['is_default'] == true)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(color: isSelected ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(4)),
                                              child: Text('Default', style: TextStyle(color: isSelected ? Colors.white : darkThemeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                            )
                                        ],
                                      )
                                    ), 
                                    const SizedBox(width: 12), 
                                    Icon(Icons.chevron_right, color: isSelected ? Colors.white : darkThemeColor)
                                  ]),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ] else ...[
                    NewAddressFormWidget(
                      // UPDATED: Now passes back the string AND the boolean
                      onSave: (newAddressString, isDefault) {
                        _saveNewAddress(newAddressString, isDefault);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
      // Prevent users from adding more than 5 addresses
      floatingActionButton: (!_showAddForm && _savedAddresses.length < 5) ? FloatingActionButton(onPressed: () { setState(() { _showAddForm = true; }); }, backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, child: const Icon(Icons.add, size: 36)) : null,
    );
  }
}

class NewAddressFormWidget extends StatefulWidget {
  // UPDATED: Expects both the string and the boolean
  final Function(String, bool) onSave;
  const NewAddressFormWidget({super.key, required this.onSave});
  @override
  State<NewAddressFormWidget> createState() => _NewAddressFormWidgetState();
}

class _NewAddressFormWidgetState extends State<NewAddressFormWidget> {
  final _fullNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _streetController = TextEditingController();
  bool _setAsDefault = false; 

  @override
  void dispose() {
    _fullNameController.dispose(); _contactNumberController.dispose(); _provinceController.dispose(); _postalCodeController.dispose(); _streetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Note: Only 5 addresses can be created', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 12),
        const Text('New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkThemeColor)), const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12.0), decoration: BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [_buildFormInput(_fullNameController, 'Full Name'), _buildFormInput(_contactNumberController, 'Contact Number'), _buildFormInput(_provinceController, 'Province, Municipality, Barangay'), _buildFormInput(_postalCodeController, 'Postal Code'), _buildFormInput(_streetController, 'Street Name/House Number')]),
        ),
        const SizedBox(height: 12),
        Row(children: [Checkbox(value: _setAsDefault, onChanged: (bool? newValue) { setState(() { _setAsDefault = newValue ?? false; }); }, activeColor: darkThemeColor), const Text('Set as Default Address', style: TextStyle(color: darkThemeColor, fontSize: 14))]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final fullName = _fullNameController.text; final street = _streetController.text; final province = _provinceController.text; final postalCode = _postalCodeController.text; final contact = _contactNumberController.text;
              if (fullName.isNotEmpty && street.isNotEmpty) {
                final newAddressString = '$fullName, $street, $province $postalCode, $contact';
                // Trigger the save function and pass both values
                widget.onSave(newAddressString, _setAsDefault); 
              } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all address details.'))); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
            child: const Text('Save Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormInput(TextEditingController controller, String placeholderText) {
    return Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: TextField(controller: controller, decoration: InputDecoration(hintText: placeholderText, border: InputBorder.none, contentPadding: const EdgeInsets.all(16.0)))));
  }
}

// ============================================================================
// 8. MISC
// ============================================================================

class PlaceholderPage extends StatelessWidget {
  final String title; 
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}