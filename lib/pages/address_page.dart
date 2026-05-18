import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // --- ADDED: For input formatters ---
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';

// ============================================================================
// 1. FULL SCREEN MAP PICKER
// ============================================================================
class AddressLocationPickerMap extends StatefulWidget {
  const AddressLocationPickerMap({super.key});

  @override
  State<AddressLocationPickerMap> createState() => _AddressLocationPickerMapState();
}

class _AddressLocationPickerMapState extends State<AddressLocationPickerMap> {
  late MapController _mapController;
  LatLng? _pickedPoint;
  LatLng _currentCenter = const LatLng(14.5995, 120.9842);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _centerOnCurrentLocation() async {
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission not granted.')));
      return;
    }

    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable location services.')));
        return;
      }
    }

    final locData = await location.getLocation();
    if (locData.latitude != null && locData.longitude != null) {
      final newLatLng = LatLng(locData.latitude!, locData.longitude!);
      setState(() {
        _pickedPoint = newLatLng;
        _currentCenter = newLatLng;
      });
      _mapController.move(newLatLng, 15.0);
    }
  }

  void _onMapTap(TapPosition _, LatLng point) {
    setState(() {
      _pickedPoint = point;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Location'),
        backgroundColor: const Color(0xFF383E46),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _pickedPoint == null ? null : () => Navigator.pop(context, _pickedPoint),
            child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentCenter,
          initialZoom: 13.0,
          onTap: _onMapTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.tonto_ecommerce', 
          ),
          if (_pickedPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80, height: 80, point: _pickedPoint!,
                  child: const Icon(Icons.location_pin, color: Colors.red, size: 50),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF383E46),
        child: const Icon(Icons.my_location, color: Colors.white),
        onPressed: _centerOnCurrentLocation,
      ),
    );
  }
}

// ============================================================================
// 2. MAIN ADDRESS PAGE
// ============================================================================
class AddressPage extends StatefulWidget {
  final String initialSelectedAddress;
  const AddressPage({super.key, required this.initialSelectedAddress});
  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
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
          .order('is_default', ascending: false) 
          .order('created_at', ascending: false);
          
      if (mounted) {
        setState(() {
          _savedAddresses = List<Map<String, dynamic>>.from(response);
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

  Future<void> _saveNewAddress(String newAddressString, bool isDefault, double? lat, double? lng) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      if (isDefault) {
        await _supabase.from('user_addresses').update({'is_default': false}).eq('user_id', user.id);
      }

      await _supabase.from('user_addresses').insert({
        'user_id': user.id,
        'address_string': newAddressString,
        'is_default': isDefault,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      });

      await _fetchAddresses();
      
      setState(() {
        _currentSelectedAddress = newAddressString; 
        _showAddForm = false; 
      });

      if (mounted) {
        Navigator.pop(context, newAddressString);
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(int addressId, int index) async {
    try {
      await _supabase.from('user_addresses').delete().eq('id', addressId);
    } catch (e) {
      debugPrint('Error deleting address: $e');
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
                      onSave: (newAddressString, isDefault, lat, lng) {
                        _saveNewAddress(newAddressString, isDefault, lat, lng);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
      floatingActionButton: (!_showAddForm && _savedAddresses.length < 5) ? FloatingActionButton(onPressed: () { setState(() { _showAddForm = true; }); }, backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, child: const Icon(Icons.add, size: 36)) : null,
    );
  }
}

// ============================================================================
// 3. NEW ADDRESS FORM WIDGET 
// ============================================================================
class NewAddressFormWidget extends StatefulWidget {
  final Function(String, bool, double?, double?) onSave;
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

  LatLng? _selectedLocation;
  bool _locationPicked = false;

  @override
  void dispose() {
    _fullNameController.dispose(); _contactNumberController.dispose(); _provinceController.dispose(); _postalCodeController.dispose(); _streetController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
      return;
    }

    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    final locData = await location.getLocation();
    if (locData.latitude != null && locData.longitude != null) {
      final lat = locData.latitude!;
      final lng = locData.longitude!;
      setState(() {
        _selectedLocation = LatLng(lat, lng);
        _locationPicked = true;
      });
      await _updateAddressFromCoordinates(lat, lng);
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const AddressLocationPickerMap(),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _locationPicked = true;
      });
      await _updateAddressFromCoordinates(result.latitude, result.longitude);
    }
  }

 Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        setState(() {
          String street = [pm.street, pm.thoroughfare, pm.subThoroughfare, pm.name]
              .where((p) => p != null && p.isNotEmpty).join(', ');
              
          String province = [
            pm.subLocality,
            pm.locality,
            pm.subAdministrativeArea,
            pm.administrativeArea,
            pm.country
          ].where((part) => part != null && part.isNotEmpty).join(', ');
          
          _streetController.text = street.isNotEmpty ? street : 'Unknown Street';
          _provinceController.text = province.isNotEmpty ? province : 'Unknown Location';
          _postalCodeController.text = pm.postalCode ?? '';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not auto-fetch address names (GPS/Network Error). Please type them manually.'))
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Note: Only 5 addresses can be created', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 12)), 
        const SizedBox(height: 12),
        const Text('New Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: darkThemeColor)), 
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location, size: 18, color: darkThemeColor),
                label: const Text('Use Current Location', style: TextStyle(color: darkThemeColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: darkThemeColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map, size: 18, color: darkThemeColor),
                label: const Text('Pick on Map', style: TextStyle(color: darkThemeColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: darkThemeColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        if (_locationPicked)
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 6),
                Text('Location set and text fields auto-filled!', style: TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ),
          ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(12.0), decoration: BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [
            _buildFormInput(_fullNameController, 'Full Name'), 
            
            // --- FIXED: Uses the isPhone flag to lock the +63 prefix ---
            _buildFormInput(_contactNumberController, '912 345 6789', isPhone: true), 
            
            _buildFormInput(_provinceController, 'Province, Municipality, Barangay'), 
            _buildFormInput(_postalCodeController, 'Postal Code'), 
            _buildFormInput(_streetController, 'Street Name/House Number')
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [Checkbox(value: _setAsDefault, onChanged: (bool? newValue) { setState(() { _setAsDefault = newValue ?? false; }); }, activeColor: darkThemeColor), const Text('Set as Default Address', style: TextStyle(color: darkThemeColor, fontSize: 14))]),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final fullName = _fullNameController.text; 
              final street = _streetController.text; 
              final province = _provinceController.text; 
              final postalCode = _postalCodeController.text; 
              
              // --- FIXED: Stitches the +63 when saving to the database ---
              final contact = _contactNumberController.text.isNotEmpty ? '+63${_contactNumberController.text.trim()}' : '';
              
              if (fullName.isNotEmpty && street.isNotEmpty) {
                final newAddressString = '$fullName, $street, $province $postalCode, $contact';
                
                widget.onSave(newAddressString, _setAsDefault, _selectedLocation?.latitude, _selectedLocation?.longitude); 
              } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all address details.'))); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF383E46), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 4),
            child: const Text('Save Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- FIXED: Updated the builder to handle the isPhone condition ---
  Widget _buildFormInput(TextEditingController controller, String placeholderText, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: controller,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10), // Limit to exactly 10 digits
                ]
              : null,
          decoration: InputDecoration(
            prefixText: isPhone ? '+63 ' : null, // The locked prefix
            prefixStyle: isPhone 
                ? const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold) 
                : null,
            hintText: placeholderText,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16.0),
          ),
        ),
      ),
    );
  }
}