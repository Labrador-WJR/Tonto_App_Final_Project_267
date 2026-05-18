import 'dart:typed_data'; // --- CHANGED: Used for cross-platform bytes instead of dart:io ---
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audioplayers/audioplayers.dart';

// ============================================================================
// 1. CUSTOM DESIGN LIST PAGE (Shows history of user requests)
// ============================================================================
class CustomSectionRootWidget extends StatefulWidget {
  const CustomSectionRootWidget({super.key});

  @override
  State<CustomSectionRootWidget> createState() => _CustomSectionRootWidgetState();
}

class _CustomSectionRootWidgetState extends State<CustomSectionRootWidget> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _myDesigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomDesigns();
  }

  Future<void> _fetchCustomDesigns() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await _supabase
          .from('custom_designs')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myDesigns = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching custom designs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDesign(int id) async {
    try {
      await _supabase.from('custom_designs').delete().eq('id', id);
      _fetchCustomDesigns(); 
    } catch (e) {
      debugPrint('Error deleting custom design: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Custom Requests'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D3238)))
          : RefreshIndicator(
              onRefresh: _fetchCustomDesigns,
              color: const Color(0xFF2D3238),
              child: _myDesigns.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        const Center(
                          child: Text(
                            'No custom designs requested yet.\nTap the + button to create one!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _myDesigns.length,
                      itemBuilder: (context, index) {
                        final item = _myDesigns[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Dismissible(
                            key: ValueKey(item['id']),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12)),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(Icons.delete_forever, color: Colors.white, size: 36),
                            ),
                            onDismissed: (direction) {
                              _deleteDesign(item['id']);
                              setState(() => _myDesigns.removeAt(index));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request removed'), duration: Duration(seconds: 2)));
                            },
                            child: _buildDesignItemCard(item),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewCustomDesignPage()),
          );
          _fetchCustomDesigns();
        },
        backgroundColor: const Color(0xFF383E46),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 36),
      ),
    );
  }

  Widget _buildDesignItemCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'Pending';
    Color statusColor = Colors.orange;
    if (status == 'Approved') statusColor = Colors.green;
    if (status == 'Rejected') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['image_url'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 30)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Request Status:', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: statusColor)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['description'] ?? 'No description provided',
                  style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// 2. NEW CUSTOM DESIGN PAGE (The Form)
// ============================================================================
class NewCustomDesignPage extends StatefulWidget {
  const NewCustomDesignPage({super.key});

  @override
  State<NewCustomDesignPage> createState() => _NewCustomDesignPageState();
}

class _NewCustomDesignPageState extends State<NewCustomDesignPage> {
  final _supabase = Supabase.instance.client;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _descController = TextEditingController();
  
  // --- CHANGED: Use Bytes for Web/Mobile compatibility! ---
  Uint8List? _imageBytes;
  String? _fileName;
  bool _isProcessing = false;

  @override
  void dispose() {
    _descController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // --- CROSS-PLATFORM IMAGE PICKER ---
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    
    if (pickedFile != null) {
      // Read as bytes so it works on Chrome AND Android
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _fileName = pickedFile.name; // Keep the name to know if it's a png/jpg
      });
    }
  }

  void _showErrorPopup(String message) {
    () async {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    }();
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Center(
            child: Container(
              width: 250, padding: const EdgeInsets.all(24.0), decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 50, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Center(child: Text('!', style: TextStyle(color: Color(0xFF383E46), fontSize: 28, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 16), const Text('Oops!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(height: 24),
                  SizedBox(width: 120, height: 40, child: ElevatedButton(onPressed: () => Navigator.pop(dialogContext), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF383E46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSuccessPopupAndNavigate(String message) {
    () async {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/checkout.mp3')); 
    }();

    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        Future.delayed(const Duration(seconds: 2), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext); 
          }
          if (mounted) {
            Navigator.pop(context); 
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent, elevation: 0,
          child: Center(
            child: Container(
              width: 250, padding: const EdgeInsets.all(24.0), decoration: BoxDecoration(color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.black, size: 40)),
                  const SizedBox(height: 24),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- CROSS-PLATFORM SUBMIT LOGIC ---
  Future<void> _submitCustomRequest() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _showErrorPopup("You must be logged in.");
      return;
    }

    if (_imageBytes == null) {
      _showErrorPopup("Please upload an image of your design idea.");
      return;
    }

    if (_descController.text.trim().isEmpty) {
      _showErrorPopup("Please provide a brief description.");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // 1. Upload Bytes to Supabase Storage
      final fileExt = _fileName?.split('.').last ?? 'png'; // Fallback to png if unknown
      final storageFileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final storagePath = 'requests/$storageFileName'; 

      // Use uploadBinary instead of standard upload to support Web
      await _supabase.storage.from('custom_designs').uploadBinary(
        storagePath, 
        _imageBytes!,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );
      
      // 2. Get the public URL
      final publicUrl = _supabase.storage.from('custom_designs').getPublicUrl(storagePath);

      // 3. Insert into database
      await _supabase.from('custom_designs').insert({
        'user_id': user.id,
        'description': _descController.text.trim(),
        'image_url': publicUrl,
        'status': 'Pending',
      });

      if (mounted) {
        _showSuccessPopupAndNavigate('Custom Design Request Submitted! 🎉');
      }
    } catch (e) {
      debugPrint('Submission Error: $e');
      if (mounted) _showErrorPopup('Failed to submit request.\nPlease try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('New Request'),
        backgroundColor: darkThemeColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), 
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload your design idea and give us a brief description. We will review it and get back to you!',
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // 1. Image Picker Area
            GestureDetector(
              onTap: _isProcessing ? null : _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5D5D5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: darkThemeColor, width: 2, style: BorderStyle.solid),
                ),
                // --- CHANGED: Use Image.memory for bytes ---
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 60, color: darkThemeColor),
                          SizedBox(height: 12),
                          Text('Tap to upload an image', style: TextStyle(color: darkThemeColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Description Text Box
            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkThemeColor)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), spreadRadius: 1, blurRadius: 4)],
              ),
              child: TextField(
                controller: _descController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Describe colors, materials, or specific adjustments you want...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 3. Submit Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _submitCustomRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkThemeColor, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}