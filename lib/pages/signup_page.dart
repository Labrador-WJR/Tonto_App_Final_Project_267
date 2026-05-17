import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart';
import '../main.dart'; // adjust if your main screen is elsewhere

// ------------------- Location Picker Map -------------------
class LocationPickerMap extends StatefulWidget {
  const LocationPickerMap({super.key});

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng? _pickedPoint;
  LatLng _currentCenter = const LatLng(40.7128, -74.0060); // default

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _centerOnCurrentLocation() async {
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission not granted.')),
      );
      return;
    }

    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable location services.')),
        );
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retrieve current location.')),
      );
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
            onPressed: _pickedPoint == null
                ? null
                : () => Navigator.pop(context, _pickedPoint),
            child: const Text(
              'Confirm',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
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
            userAgentPackageName: 'com.example.tonto_ecommerce', // replace with your actual package name
          ),
          if (_pickedPoint != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: _pickedPoint!,
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

// ------------------- Main SignUpPage -------------------
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  final _supabase = Supabase.instance.client;

  // Location state
  LatLng? _selectedLocation;
  bool _locationPicked = false;

  // ------------------- Helper methods -------------------
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF383E46),
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  /// Geocode typed address to coordinates
  Future<void> _geocodeAddressAndSetLocation(String address) async {
    if (address.trim().isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        setState(() {
          _selectedLocation = LatLng(loc.latitude, loc.longitude);
          _locationPicked = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address found on map!'), duration: Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address not found. Please try again or pick on map.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geocoding failed. Check address or pick on map.')),
      );
    }
  }

  /// Get current GPS location and fill address field
  Future<void> _getCurrentLocation() async {
    PermissionStatus status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied.')),
      );
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get current location.')),
      );
    }
  }

  /// Reverse geocode coordinates to human-readable address
  Future<void> _updateAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        String address = [
          pm.street,
          pm.subLocality,
          pm.locality,
          pm.administrativeArea,
          pm.country
        ].where((part) => part != null && part.isNotEmpty).join(', ');
        if (address.isEmpty) address = pm.name ?? '';
        setState(() {
          _addressController.text = address;
        });
      }
    } catch (e) {
      print('Reverse geocoding error: $e');
    }
  }

  /// Open the full-screen map picker
  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const LocationPickerMap(),
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

  // ------------------- Sign Up with auto sign-in (Option 2) -------------------
  Future<void> _signUp() async {
  // Validate location
  if (!_locationPicked && _addressController.text.trim().isNotEmpty) {
    await _geocodeAddressAndSetLocation(_addressController.text);
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your address using the search button or pick on map.')),
      );
      return;
    }
  }

  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please provide your location (use current location, map picker, or search address).')),
    );
    return;
  }

  setState(() => _isLoading = true);
  try {
    // 1. Sign up
    final AuthResponse res = await _supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      data: {
        'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
      },
    );

    final user = res.user;
    if (user == null) throw Exception('User creation failed - user object is null.');

    print('✅ Auth user created with ID: ${user.id}');

    // 2. Auto sign in (in case email confirmation is ON)
    if (_supabase.auth.currentSession == null) {
      print('🟡 No session yet, signing in...');
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      print('✅ Signed in successfully');
    }

    // 3. Upsert into profiles (insert or update if exists)
    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    print('🟡 Upserting into profiles...');
    await _supabase.from('profiles').upsert({
      'id': user.id,
      'email': _emailController.text.trim(),
      'full_name': fullName,
      'contact_number': _phoneController.text.trim(),
      'date_of_birth': _dobController.text.trim(),
    });
    print('✅ Upserted into profiles.');

    // 4. Insert into user_addresses (always a new address)
    print('🟡 Inserting into user_addresses...');
    await _supabase.from('user_addresses').insert({
      'user_id': user.id,
      'address_string': _addressController.text.trim(),
      'is_default': true,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
    });
    print('✅ Inserted into user_addresses.');

    // 5. Navigate to home
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  } on AuthException catch (e) {
    print('❌ AuthException: ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e, stacktrace) {
    print('❌ Unexpected error: $e');
    print(stacktrace);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign up failed. Please check the console.')),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ------------------- UI Build (Original) -------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Back button and title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF383E46)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF383E46),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
                child: Column(
                  children: [
                    // ---- PERSONAL INFORMATION ----
                    _sectionTitle('Personal Information'),
                    const SizedBox(height: 12),
                    _buildField('First Name', _firstNameController),
                    const SizedBox(height: 14),
                    _buildField('Last Name', _lastNameController),
                    const SizedBox(height: 14),

                    // Address field with search icon
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        hintText: 'Home Address',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF383E46), width: 1.5),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search, color: Color(0xFF383E46)),
                          onPressed: () => _geocodeAddressAndSetLocation(_addressController.text),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Location action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text('Current Location'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF383E46)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _openMapPicker,
                            icon: const Icon(Icons.map, size: 18),
                            label: const Text('Pick on Map'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF383E46)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_locationPicked)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text('Location set', style: TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    _buildField(
                      'Date of Birth (MM/DD/YYYY)',
                      _dobController,
                      readOnly: true,
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: 30),

                    // ---- CONTACT INFORMATION ----
                    _sectionTitle('Contact Information'),
                    const SizedBox(height: 12),
                    _buildField('Phone Number', _phoneController,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 14),
                    _buildField('Email Address', _emailController,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 14),
                    _buildField('Password', _passwordController, obscure: true),
                    const SizedBox(height: 40),

                    // ---- SIGN UP BUTTON ----
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF383E46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Complete Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---- OR SIGN UP WITH SECTION ----
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Color(0xFFCCCCCC))),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or sign up with',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF383E46),
        ),
      ),
    );
  }

  Widget _buildField(
    String hint,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF383E46), width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        // TODO: implement social sign up
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 32, color: const Color(0xFF383E46)),
      ),
    );
  }
}