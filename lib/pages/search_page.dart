import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_page.dart';
import 'search_results_page.dart'; 

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  List<String> _searchHistory = [];
  bool _isLoadingHistory = true;

  final List<String> _allFilters = ['Men', 'Women', 'Child', 'Sports', 'Festival', 'Casual', 'Formal'];
  final List<String> _activeFilters = []; 
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchSearchHistory();
  }

  // --- 1. Fetch History from Supabase ---
  Future<void> _fetchSearchHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final response = await _supabase
          .from('search_history')
          .select('query')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10); 

      if (mounted) {
        setState(() {
          _searchHistory = response.map<String>((row) => row['query'] as String).toList();
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching search history: $e');
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  // --- 2. Execute Search and Save History ---
  Future<void> _executeSearch(String queryText) async {
    final user = _supabase.auth.currentUser;
    
    if (queryText.trim().isNotEmpty && user != null) {
      try {
        await _supabase.from('search_history').insert({
          'user_id': user.id,
          'query': queryText.trim(),
        });
        _fetchSearchHistory();
      } catch (e) {
        debugPrint('Error saving search: $e');
      }
    }

    setState(() { _isDropdownOpen = false; });

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsPage(
            searchQuery: queryText.trim(),
            activeFilters: _activeFilters,
          ),
        ),
      );
    }
  }

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
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
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
                  width: 40, height: 40, fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.arrow_back, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 36,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: TextField(
                  controller: _searchController,
                  autofocus: true, 
                  onSubmitted: (value) => _executeSearch(value),
                  decoration: const InputDecoration(
                    hintText: 'Search Product', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Image.asset('assets/icons/cart.png', width: 24, height: 24, color: Colors.white, errorBuilder: (c, e, s) => const Icon(Icons.shopping_cart, color: Colors.white)),
              onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const CartPage())); },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 1. Filter Bar Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleDropdown, 
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: cardDecoration,
                    child: const Row(
                      children: [
                        Icon(Icons.tune, size: 18, color: Color(0xFF2D3238)), SizedBox(width: 6),
                        Text('Filter', style: TextStyle(color: Color(0xFF2D3238), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                              Text(filterName, style: const TextStyle(color: Color(0xFF2D3238))), const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () { setState(() { _activeFilters.remove(filterName); }); },
                                child: const Icon(Icons.close, size: 16, color: Color(0xFF2D3238)),
                              ),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                if (_activeFilters.isNotEmpty)
                  GestureDetector(
                    onTap: () => _executeSearch(_searchController.text),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(color: darkThemeColor, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.search, color: Colors.white, size: 20),
                    ),
                  )
              ],
            ),
          ),

          // 2. The STACK
          Expanded(
            child: Stack(
              children: [
                // BASE LAYER: Search History Suggestions
                _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: darkThemeColor))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: _searchHistory.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _searchController.text = _searchHistory[index];
                              _executeSearch(_searchHistory[index]);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              padding: const EdgeInsets.all(16.0),
                              decoration: cardDecoration,
                              child: Row(
                                children: [
                                  const Icon(Icons.history, color: Colors.black54, size: 20),
                                  const SizedBox(width: 12),
                                  
                                  // --- THE FIX: Expanded wrapper with TextOverflow ---
                                  Expanded(
                                    child: Text(
                                      _searchHistory[index], 
                                      style: const TextStyle(color: Color(0xFF2D3238), fontSize: 16),
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis, // Truncates with "..."
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                if (_isDropdownOpen)
                  GestureDetector(
                    onTap: () { setState(() { _isDropdownOpen = false; }); },
                    child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
                  ),

                // TOP LAYER: The Floating Dropdown Menu
                if (_isDropdownOpen)
                  Positioned(
                    top: 0, left: 16, width: 250, 
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF383E46), borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Select Categories', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8.0, runSpacing: 12.0,
                            children: _allFilters.map((filter) {
                              final isSelected = _activeFilters.contains(filter);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) { _activeFilters.remove(filter); } else { _activeFilters.add(filter); }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(color: isSelected ? const Color(0xFFD5D5D5) : const Color(0xFF2D3238), borderRadius: BorderRadius.circular(8)),
                                  child: Text(filter, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
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