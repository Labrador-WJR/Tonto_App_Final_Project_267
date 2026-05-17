import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminInventoryPage extends StatefulWidget {
  const AdminInventoryPage({super.key});

  @override
  State<AdminInventoryPage> createState() => _AdminInventoryPageState();
}

class _AdminInventoryPageState extends State<AdminInventoryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('products')
          .select('id, name, stock, category')
          .order('name');
      if (mounted) {
        setState(() {
          _products = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Inventory fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ---------- Add product dialog ----------
  Future<void> _showAddProductDialog() async {
    final nameCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Casual'); // comma separated

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price'), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Categories (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (result == true) {
      final name = nameCtrl.text.trim();
      final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      final categories = categoryCtrl.text
          .split(',')
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();

      if (name.isEmpty || categories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and at least one category required')));
        return;
      }

      try {
        await _supabase.from('products').insert({
          'name': name,
          'description': descCtrl.text.trim(),
          'price': price,
          'stock': stock,
          'category': categories,
        });
        _fetchInventory();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  // ---------- Category stock for chart ----------
  Map<String, int> _categoryStock() {
    final map = <String, int>{};
    for (final p in _products) {
      final cats = p['category'];
      if (cats is List) {
        for (var c in cats) {
          final cat = c.toString();
          map[cat] = (map[cat] ?? 0) + ((p['stock'] as int?) ?? 0);
        }
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final catStock = _categoryStock();
    final categories = catStock.keys.toList();
    final stocks = catStock.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF30363D)))
            : RefreshIndicator(
                onRefresh: _fetchInventory,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('INVENTORY',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                          ElevatedButton.icon(
                            onPressed: _showAddProductDialog,
                            icon: const Icon(Icons.add, color: Colors.black, size: 20),
                            label: const Text('ADD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE2E2E2),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (categories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E2E2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STOCK BY CATEGORY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 150,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: InventoryBarChartPainter(categories: categories, stocks: stocks),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('ALL PRODUCTS (${_products.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          final name = p['name'] ?? 'Unnamed';
                          final stock = (p['stock'] as int?) ?? 0;
                          final categories = (p['category'] as List?)?.join(', ') ?? 'No category';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: const Color(0xFFD1D1D1), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.checkroom, color: Color(0xFF4A4A4A)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                        Text(categories, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Text('$stock pcs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class InventoryBarChartPainter extends CustomPainter {
  final List<String> categories;
  final List<int> stocks;
  InventoryBarChartPainter({required this.categories, required this.stocks});

  @override
  void paint(Canvas canvas, Size size) {
    if (categories.isEmpty) return;
    final gridPaint = Paint()..color = Colors.black12..strokeWidth = 1;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final barPaint = Paint()..color = const Color(0xFF30363D)..style = PaintingStyle.fill;

    final maxStock = stocks.reduce((a, b) => a > b ? a : b).toDouble();
    if (maxStock == 0) return;

    for (int i = 0; i <= 4; i++) {
      final y = size.height - (size.height / 4) * i;
      canvas.drawLine(Offset(30, y), Offset(size.width, y), gridPaint);
      textPainter.text = TextSpan(text: '${(maxStock * i / 4).round()}', style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - 8));
    }

    final barCount = categories.length;
    final barWidth = 40.0;
    final spacing = (size.width - 30 - (barWidth * barCount)) / (barCount + 1);
    for (int i = 0; i < barCount; i++) {
      final x = 30 + spacing + i * (barWidth + spacing);
      final barHeight = (stocks[i] / maxStock) * size.height;
      final y = size.height - barHeight;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, barWidth, barHeight), const Radius.circular(8)), barPaint);
      textPainter.text = TextSpan(text: categories[i].length > 5 ? '${categories[i].substring(0, 5)}..' : categories[i], style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500));
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - 2, size.height + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}