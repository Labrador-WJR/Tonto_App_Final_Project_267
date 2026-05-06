import 'package:flutter/material.dart';
import 'cart_page.dart';
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock data for the search history
  final List<String> _searchHistory = [
    'Suggestion',
    'Summer Hoodie v1',
    'Classic Tee (Red)',
    'Graphic Design 03',
  ];

  // Data for the filters
  final List<String> _allFilters = ['Men', 'Women', 'Child', 'Sports', 'Festival', 'Casual', 'Formal'];
  final List<String> _activeFilters = []; 

  // NEW: State variable to track if the dropdown is open
  bool _isDropdownOpen = false;

  // NEW: Function to toggle the dropdown instead of showing a popup
  void _toggleDropdown() {
    setState(() {
      _isDropdownOpen = !_isDropdownOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkThemeColor = Color(0xFF2D3238);
    final cardDecoration = BoxDecoration(
      color: const Color(0xFFD5D5D5),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: darkThemeColor,
        elevation: 0,
        automaticallyImplyLeading: false, 
        titleSpacing: 0,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.arrow_back, color: Colors.white), 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true, 
                  decoration: const InputDecoration(
                    hintText: 'Search Product',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Image.asset(
                'assets/icons/cart.png',
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Filter Bar Row (The Anchor)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                // PINNED: Main Filter Button
                GestureDetector(
                  // CHANGED: Now toggles the dropdown instead of opening a dialog
                  onTap: _toggleDropdown, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: cardDecoration,
                    child: const Row(
                      children: [
                        Icon(Icons.tune, size: 18, color: Color(0xFF2D3238)),
                        SizedBox(width: 6),
                        Text('Filter', style: TextStyle(color: Color(0xFF2D3238), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // SCROLLABLE: Active Filter Chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _activeFilters.map((filterName) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                          decoration: cardDecoration,
                          child: Row(
                            children: [
                              Text(filterName, style: const TextStyle(color: Color(0xFF2D3238))),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _activeFilters.remove(filterName);
                                  });
                                },
                                child: const Icon(Icons.close, size: 16, color: Color(0xFF2D3238)),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. The STACK (Holds the list AND the floating dropdown)
          Expanded(
            child: Stack(
              children: [
                // BASE LAYER: Search History Suggestions
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _searchHistory.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: cardDecoration,
                      child: Text(
                        _searchHistory[index],
                        style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16),
                      ),
                    );
                  },
                ),

                // INTERACTION LAYER: Invisible background to close dropdown when tapping outside
                if (_isDropdownOpen)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = false; // Close if they tap anywhere else
                      });
                    },
                    child: Container(
                      color: Colors.transparent, // Invisible but catches taps!
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),

                // TOP LAYER: The Floating Dropdown Menu
                if (_isDropdownOpen)
                  Positioned(
                    top: 0, // Sticks right below the filter bar
                    left: 16, // Aligns with the filter button
                    width: 250, // Fixed width for the menu
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF383E46), // Dark background
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4), // Drops shadow downwards
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Select Categories', 
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                          const SizedBox(height: 16),
                          // Wraps the filter chips so they flow onto the next line
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 12.0,
                            children: _allFilters.map((filter) {
                              final isSelected = _activeFilters.contains(filter);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _activeFilters.remove(filter);
                                    } else {
                                      _activeFilters.add(filter);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    // Light grey if selected, dark grey if unselected
                                    color: isSelected ? const Color(0xFFD5D5D5) : const Color(0xFF2D3238),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}