import 'package:flutter/material.dart';
import '../models/data_models.dart';

class CustomSectionRootWidget extends StatefulWidget {
  const CustomSectionRootWidget({super.key});

  @override
  State<CustomSectionRootWidget> createState() => _CustomSectionRootWidgetState();
}

class _CustomSectionRootWidgetState extends State<CustomSectionRootWidget> {
  final List<CartItem> _userDesigns = [
    CartItem(id: 101, name: "Summer Hoodie v1", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
    CartItem(id: 102, name: "Classic Tee (Red)", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
    CartItem(id: 103, name: "Graphic Design 03", imagePath: 'placeholder_front', price: 0.00, quantity: 1),
  ];

  int _nextUniqueId = 104; 

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (context) => CustomDesignListPage(
          designs: _userDesigns,
          onAddDesignClicked: () async {
            final newDesignItem = await Navigator.of(context).push<CartItem>(
              MaterialPageRoute(builder: (context) => const EditingDetailsPage()),
            );
            if (newDesignItem != null) {
              setState(() {
                newDesignItem.id = _nextUniqueId++; 
                _userDesigns.add(newDesignItem);
              });
            }
          },
          onDeleteDesignClicked: (CartItem itemToDelete) {
            setState(() {
              _userDesigns.remove(itemToDelete);
            });
          },
        ),
      ),
    );
  }
}

class CustomDesignListPage extends StatelessWidget {
  final List<CartItem> designs;
  final VoidCallback onAddDesignClicked;
  final Function(CartItem) onDeleteDesignClicked; 

  const CustomDesignListPage({
    super.key,
    required this.designs,
    required this.onAddDesignClicked,
    required this.onDeleteDesignClicked, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Designs'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: const Icon(Icons.arrow_back), 
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: ListView.builder(
              itemCount: designs.length,
              itemBuilder: (context, index) {
                final item = designs[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Dismissible(
                    key: ValueKey(item.id), 
                    direction: DismissDirection.horizontal,
                    background: _buildTrashCanBackground(Alignment.centerLeft),
                    secondaryBackground: _buildTrashCanBackground(Alignment.centerRight),
                    onDismissed: (direction) {
                      onDeleteDesignClicked(item); 
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} removed'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: _buildDesignItemCard(item),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: onAddDesignClicked,
              backgroundColor: const Color(0xFF383E46),
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashCanBackground(Alignment alignment) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF383E46),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete_forever, color: Colors.white, size: 36),
    );
  }

  Widget _buildDesignItemCard(CartItem item) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.reorder, color: Color(0xFF2D3238), size: 24),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF383E46),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image, size: 36, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(color: Color(0xFF2D3238), fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class EditingDetailsPage extends StatefulWidget {
  const EditingDetailsPage({super.key});

  @override
  State<EditingDetailsPage> createState() => _EditingDetailsPageState();
}

class _EditingDetailsPageState extends State<EditingDetailsPage> {
  final List<GarmentView> _views = [
    GarmentView(label: 'Front', imagePath: 'placeholder_front'),
    GarmentView(label: 'Side', imagePath: 'placeholder_side'),
    GarmentView(label: 'Back', imagePath: 'placeholder_back'),
  ];

  int _currentViewIndex = 0;
  bool _isProcessing = false;

  Future<String?> _showNameDialog() async {
    TextEditingController nameController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF383E46), 
          title: const Text('Name Your Design', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'e.g., Summer Vibes Logo',
              hintStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
            ),
            autofocus: true, 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null), 
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              onPressed: () {
                String name = nameController.text.trim();
                if (name.isEmpty) name = "Unnamed Design"; 
                Navigator.pop(context, name); 
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSuccessPopup() async {
    await showDialog(
      context: context,
      barrierDismissible: false, 
      useRootNavigator: false, 
      builder: (BuildContext dialogContext) { 
        Future.delayed(const Duration(seconds: 1), () {
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          child: Center(
            child: Container(
              width: 220, 
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF383E46), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.black, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text('Design Saved', style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentView = _views[_currentViewIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editing Details'),
        backgroundColor: const Color(0xFF2D3238),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), 
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentViewIndex = (_currentViewIndex + 1) % _views.length;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFD5D5D5), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(currentView.label, style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16, fontWeight: FontWeight.bold)),
                        const Icon(Icons.refresh, color: Color(0xFF2D3238)), 
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: const Color(0xFFD9D9D9), borderRadius: BorderRadius.circular(12)),
                    child: const Center(child: Icon(Icons.image, size: 80, color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 100), 
              ],
            ),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery function not yet implemented.')));
                  },
                  backgroundColor: const Color(0xFFD5D5D5),
                  foregroundColor: const Color(0xFF2D3238),
                  child: const Icon(Icons.add, size: 36),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setState(() { _isProcessing = true; });
                    final String? customName = await _showNameDialog();
                    if (customName == null) {
                      setState(() { _isProcessing = false; });
                      return;
                    }
                    await _showSuccessPopup();
                    if (!context.mounted) return;
                    final newDesign = CartItem(id: 0, name: customName, imagePath: _views[0].imagePath, price: 0.00, quantity: 1);
                    Navigator.pop(context, newDesign); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF383E46), 
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF383E46).withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}