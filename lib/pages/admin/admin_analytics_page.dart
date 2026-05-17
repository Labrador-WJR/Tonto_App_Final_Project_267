import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _timeframe = 'MONTH';

  double _totalRevenue = 0;
  List<Map<String, dynamic>> _categorySales = [];
  List<Map<String, dynamic>> _topSellers = [];

  List<double> _monthlyRevenue = [];
  List<double> _monthlyOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchYearlyChartData(),
        _applyTimeframe(),
      ]);
    } catch (e) {
      debugPrint('Analytics load error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // ---------- Yearly chart data ----------
  Future<void> _fetchYearlyChartData() async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);

    final orders = await _supabase
        .from('orders')
        .select('id, total_price, created_at')
        .gte('created_at', startOfYear.toIso8601String())
        .lt('created_at', DateTime(now.year + 1, 1, 1).toIso8601String());

    List<double> rev = List.filled(12, 0);
    List<double> cnt = List.filled(12, 0);

    for (var o in orders) {
      final date = DateTime.parse(o['created_at']);
      final monthIdx = date.month - 1;
      rev[monthIdx] += (o['total_price'] ?? 0).toDouble();
      cnt[monthIdx] += 1;
    }
    _monthlyRevenue = rev;
    _monthlyOrders = cnt;
  }

  // ---------- Timeframe filtered data ----------
  Future<void> _applyTimeframe() async {
    DateTime start;
    final now = DateTime.now();
    switch (_timeframe) {
      case 'DAY':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'MONTH':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'YEAR':
        start = DateTime(now.year, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, 1);
    }

    // Total revenue
    final revRes = await _supabase
        .from('orders')
        .select('total_price')
        .gte('created_at', start.toIso8601String())
        .lt('created_at', now.add(const Duration(days: 1)).toIso8601String());

    double revenue = 0;
    for (var r in revRes) {
      revenue += (r['total_price'] ?? 0).toDouble();
    }
    _totalRevenue = revenue;

    // Category percentages
    _categorySales = await _fetchCategoryPercentages(start, now);
    _topSellers = await _fetchTopSellers(start, now);
  }

  Future<List<Map<String, dynamic>>> _fetchCategoryPercentages(
      DateTime start, DateTime end) async {
    // Fetch order items within timeframe
    final items = await _supabase
        .from('order_items')
        .select('quantity, product:products(category)')
        .gte('order_id.created_at', start.toIso8601String())
        .lt('order_id.created_at', end.add(const Duration(days: 1)).toIso8601String());

    // Flatten categories (they are arrays)
    final Map<String, int> catCount = {};
    int totalQty = 0;
    for (var item in items) {
      final qty = (item['quantity'] as int?) ?? 0;
      if (qty == 0) continue;
      totalQty += qty;

      final product = item['product'];
      if (product != null && product is Map) {
        final cats = product['category'];
        if (cats is List) {
          for (var c in cats) {
            final cat = c.toString();
            catCount[cat] = (catCount[cat] ?? 0) + qty;
          }
        }
      } else {
        // fallback
        const unk = 'Uncategorized';
        catCount[unk] = (catCount[unk] ?? 0) + qty;
      }
    }

    if (totalQty == 0) return [];

    return catCount.entries
        .map((e) => {
              'category': e.key,
              'percentage': ((e.value / totalQty) * 100).round(),
            })
        .toList()
      ..sort((a, b) => (b['percentage'] as int).compareTo(a['percentage'] as int));
  }

  Future<List<Map<String, dynamic>>> _fetchTopSellers(
      DateTime start, DateTime end) async {
    final items = await _supabase
        .from('order_items')
        .select('quantity, product:products(name)')
        .gte('order_id.created_at', start.toIso8601String())
        .lt('order_id.created_at', end.add(const Duration(days: 1)).toIso8601String());

    final Map<String, int> soldMap = {};
    for (var item in items) {
      final qty = (item['quantity'] as int?) ?? 0;
      final product = item['product'];
      final name = (product != null && product is Map)
          ? (product['name'] as String? ?? 'Unknown')
          : 'Unknown';
      soldMap[name] = (soldMap[name] ?? 0) + qty;
    }

    final sorted = soldMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(3).map((e) => {
          'name': e.key,
          'sold': '${e.value} SOLD',
          // approximate price (you could improve this)
          'price': '₱ ${(_totalRevenue * e.value / (soldMap.values.isEmpty ? 1 : soldMap.values.reduce((a,b)=>a+b))).toStringAsFixed(0)}'
        }).toList();
  }

  void _changeTimeframe(String tf) {
    setState(() => _timeframe = tf);
    _applyTimeframe();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAllData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ANALYTICS',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: ['DAY', 'MONTH', 'YEAR'].map((tf) {
                                bool isActive = _timeframe == tf;
                                return GestureDetector(
                                  onTap: () => _changeTimeframe(tf),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFF30363D) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tf,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Revenue chart
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E2E2),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('REVENUE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            Text(
                              '₱ ${_totalRevenue.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 36),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: _monthlyRevenue.isEmpty
                                  ? const Center(child: Text('No data'))
                                  : CustomPaint(
                                      painter: AnalyticsLineChartPainter(
                                        revenueData: _monthlyRevenue,
                                        ordersData: _monthlyOrders,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text('SALES BY CATEGORY',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      if (_categorySales.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text('No category data yet', style: TextStyle(color: Colors.black54)),
                        )
                      else
                        ..._categorySales.map((c) => _buildCategoryBar(
                            c['category'], c['percentage'] / 100, '${c['percentage']} %')),

                      const SizedBox(height: 24),
                      const Text('TOP SELLERS',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 16),
                      if (_topSellers.isEmpty)
                        const Text('No top sellers yet', style: TextStyle(color: Colors.black54))
                      else
                        ..._topSellers.map((t) => _buildTopSellerRow(t['sold'], t['price'])),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCategoryBar(String title, double percentage, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage,
                minHeight: 12,
                backgroundColor: Colors.white,
                color: const Color(0xFF30363D),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTopSellerRow(String sold, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E2E2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFD1D1D1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.checkroom, color: Color(0xFF4A4A4A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AKLAN LEAGUE JERSEY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                Text(sold, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black87)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFF8C95A0), borderRadius: BorderRadius.circular(6)),
            child: Text(price, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// ---------- Chart painter ----------
class AnalyticsLineChartPainter extends CustomPainter {
  final List<double> revenueData;
  final List<double> ordersData;
  AnalyticsLineChartPainter({required this.revenueData, required this.ordersData});

  @override
  void paint(Canvas canvas, Size size) {
    if (revenueData.isEmpty || ordersData.isEmpty) return;

    final solidPaint = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
    final dashPaint = Paint()..color = Colors.black87..strokeWidth = 1.5..style = PaintingStyle.stroke;
    final gridPaint = Paint()..color = Colors.black26..strokeWidth = 0.5;

    final maxRev = revenueData.reduce((a, b) => a > b ? a : b);
    final maxOrd = ordersData.reduce((a, b) => a > b ? a : b);
    final maxVal = maxRev > maxOrd ? maxRev : maxOrd;
    if (maxVal == 0) return;

    for (int i = 0; i <= 4; i++) {
      final y = (size.height * 0.85) / 4 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Revenue line (solid)
    final revPath = Path();
    for (int i = 0; i < revenueData.length; i++) {
      final x = size.width * i / (revenueData.length - 1);
      final y = size.height * 0.85 - (revenueData[i] / maxVal * size.height * 0.85);
      if (i == 0) {
        revPath.moveTo(x, y);
      } else {
        revPath.lineTo(x, y);
      }
    }
    canvas.drawPath(revPath, solidPaint);
    canvas.drawCircle(Offset(size.width * 3 / 11, size.height * 0.85 - (revenueData[3] / maxVal * size.height * 0.85)), 4, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(size.width * (revenueData.length - 1) / (revenueData.length - 1), size.height * 0.85 - (revenueData.last / maxVal * size.height * 0.85)), 4, Paint()..color = Colors.black);

    // Orders line (dashed)
    final ordPath = Path();
    for (int i = 0; i < ordersData.length; i++) {
      final x = size.width * i / (ordersData.length - 1);
      final y = size.height * 0.85 - (ordersData[i] / maxVal * size.height * 0.85);
      if (i == 0) {
        ordPath.moveTo(x, y);
      } else {
        ordPath.lineTo(x, y);
      }
    }
    _drawDashedLine(canvas, ordPath, dashPaint);

    // X-axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final step = size.width / 11;
    for (int i = 0; i < months.length; i++) {
      textPainter.text = TextSpan(text: months[i], style: const TextStyle(color: Colors.black54, fontSize: 8, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(i * step - 5, size.height * 0.92));
    }
  }

  void _drawDashedLine(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}