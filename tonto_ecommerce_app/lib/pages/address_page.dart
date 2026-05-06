import 'package:flutter/material.dart';
import '../models/data_models.dart';

class AddressPage extends StatefulWidget {
  final String initialSelectedAddress;
  const AddressPage({super.key, required this.initialSelectedAddress});
  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  late String _currentSelectedAddress;
  bool _showAddForm = false;

  final cardDecorationLight = BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);
  final cardDecorationDark = BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]);

  @override
  void initState() {
    super.initState();
    _currentSelectedAddress = widget.initialSelectedAddress;
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
      body: SingleChildScrollView(
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
                    bottom: 12, // CHANGED: Moved to the bottom
                    right: 12, 
                    child: Container(
                      decoration: const BoxDecoration(
                        color: darkThemeColor, 
                        shape: BoxShape.circle // CHANGED: Made it a perfect circle
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
              ListView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: mockSavedAddresses.length,
                itemBuilder: (context, index) {
                  final addressItem = mockSavedAddresses[index];
                  bool isSelected = addressItem.addressString == _currentSelectedAddress;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Dismissible(
                      key: ValueKey(addressItem.id), direction: DismissDirection.horizontal,
                      background: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerLeft, padding: const EdgeInsets.only(left: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                      secondaryBackground: Container(decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20.0), child: const Icon(Icons.delete_forever, color: Colors.white, size: 36)),
                      onDismissed: (direction) {
                        setState(() {
                          mockSavedAddresses.removeAt(index);
                          if (_currentSelectedAddress == addressItem.addressString) _currentSelectedAddress = 'No address selected';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address removed.'), duration: Duration(seconds: 2)));
                      },
                      child: GestureDetector(
                        onTap: () { setState(() { _currentSelectedAddress = addressItem.addressString; }); },
                        child: Container(
                          padding: const EdgeInsets.all(12.0), decoration: isSelected ? cardDecorationDark : cardDecorationLight,
                          child: Row(children: [Icon(Icons.location_on, color: isSelected ? Colors.white : darkThemeColor, size: 24), const SizedBox(width: 12), Expanded(child: Text(addressItem.addressString, style: TextStyle(color: isSelected ? Colors.white : darkThemeColor, fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))), const SizedBox(width: 12), Icon(Icons.chevron_right, color: isSelected ? Colors.white : darkThemeColor)]),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ] else ...[
              NewAddressFormWidget(
                onSave: (newAddressString) {
                  setState(() {
                    mockSavedAddresses.insert(0, SavedAddress(id: DateTime.now().millisecondsSinceEpoch, addressString: newAddressString));
                    _currentSelectedAddress = newAddressString; 
                    _showAddForm = false; 
                  });
                  Navigator.pop(context, newAddressString);
                },
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
      floatingActionButton: (!_showAddForm && mockSavedAddresses.length < 5) ? FloatingActionButton(onPressed: () { setState(() { _showAddForm = true; }); }, backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, child: const Icon(Icons.add, size: 36)) : null,
    );
  }
}

class NewAddressFormWidget extends StatefulWidget {
  final Function(String) onSave;
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
                widget.onSave(newAddressString); 
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