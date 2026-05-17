import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/data_models.dart';
import 'admin_analytics_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  double _totalRevenue = 0;
  int _totalOrders = 0;
  int _totalCustomers = 0;
  int _pendingOrders = 0;
  final int _refunds = 0;
  List<AdminOrder> _recentOrders = [];
  bool _loading = true;

  // 7‑day revenue for the chart
  List<double> _salesChartData = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final ordersRes = await _supabase
          .from('orders')
          .select('id, total_price, status, user_id, created_at');
      final orders = ordersRes as List<dynamic>;

      if (orders.isNotEmpty) {
        _totalOrders = orders.length;
        _pendingOrders = orders.where((o) => o['status'] == 'Pending').length;
        _totalRevenue = orders.fold(0.0, (sum, o) => sum + (o['total_price'] ?? 0.0));
        final userIds = orders.map((o) => o['user_id']).toSet();
        _totalCustomers = userIds.length;

        final recentRaw = orders.cast<Map<String, dynamic>>().toList()
          ..sort((a, b) =>
              (b['created_at'] as String).compareTo(a['created_at'] as String));
        final recentList = recentRaw.take(5).toList();

        List<AdminOrder> recentOrdersWithDetails = [];
        for (var order in recentList) {
          recentOrdersWithDetails.add(AdminOrder(
            id: order['id'],
            customerName: 'Customer', // will be replaced by real name later
            productName: 'Casual Jersey',
            quantity: 3,
            totalPrice: (order['total_price'] ?? 0).toDouble(),
            status: order['status'] ?? 'Pending',
            createdAt: DateTime.parse(order['created_at']),
          ));
        }
        _recentOrders = recentOrdersWithDetails;

        // Fetch 7‑day chart data
        _salesChartData = await _fetchLast7DaysRevenue();
      } else {
        _loadMockData();
      }
    } catch (e) {
      _loadMockData();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<List<double>> _fetchLast7DaysRevenue() async {
    try {
      final now = DateTime.now();
      final dates = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
      List<double> dailyTotals = [];
      for (var date in dates) {
        final next = date.add(const Duration(days: 1));
        final res = await _supabase
            .from('orders')
            .select('total_price')
            .gte('created_at', date.toIso8601String())
            .lt('created_at', next.toIso8601String());
        double sum = 0;
        for (var row in res) {
          sum += (row['total_price'] ?? 0).toDouble();
        }
        dailyTotals.add(sum);
      }
      // if all zero, use a small mock so the chart shows a flat line
      if (dailyTotals.every((d) => d == 0)) {
        return List.filled(7, 100.0);
      }
      return dailyTotals;
    } catch (_) {
      // fallback
      return [100, 250, 180, 320, 280, 400, 380];
    }
  }

  void _loadMockData() {
    _recentOrders = [
      AdminOrder(
          id: 1234,
          customerName: 'Admin',
          productName: 'Casual Jersey',
          quantity: 3,
          totalPrice: 1234,
          status: 'Pending',
          createdAt: DateTime.now()),
      AdminOrder(
          id: 1235,
          customerName: 'Admin',
          productName: 'Casual Jersey',
          quantity: 3,
          totalPrice: 1234,
          status: 'Shipped',
          createdAt: DateTime.now()),
    ];
    _salesChartData = [100, 250, 180, 320, 280, 400, 380];
  }

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBgColor = Color(0xFFE2E2E2);
    const Color textDarkColor = Colors.black;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back, Admin!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4A4A4A)),
                    ),
                    const Text(
                      'DASHBOARD',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: textDarkColor),
                    ),
                    const SizedBox(height: 16),

                    _buildStatCard('Total Revenue:',
                        '₱ ${_formatNumber(_totalRevenue)}',
                        isFullWidth: true,
                        bgColor: cardBgColor),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard('Total Orders:',
                                _totalOrders.toString(),
                                bgColor: cardBgColor)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildStatCard('Total Customers:',
                                _totalCustomers.toString(),
                                bgColor: cardBgColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _buildStatCard('Pending Orders:',
                                _pendingOrders.toString(),
                                bgColor: cardBgColor)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _buildStatCard(
                                'Refunds:', _refunds.toString(),
                                bgColor: cardBgColor)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('SALES (last 7 days)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textDarkColor)),
                    const SizedBox(height: 8),

                    // Chart – now driven by _salesChartData
                    _buildSalesChartCard(cardBgColor),

                    const SizedBox(height: 24),

                    const Text('RECENT ORDERS',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textDarkColor)),
                    const SizedBox(height: 12),
                    if (_recentOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No recent orders',
                            style: TextStyle(color: Colors.black54)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: Colors.transparent, height: 8),
                        itemBuilder: (context, index) =>
                            _buildOrderRow(_recentOrders[index]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value,
      {bool isFullWidth = false, required Color bgColor}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B6B6B),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Center(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: isFullWidth ? 36 : 30,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF30363D)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChartCard(Color bgColor) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Stack(
        children: [
          _salesChartData.isEmpty
              ? const Center(
                  child: Text('No sales data yet',
                      style: TextStyle(color: Colors.black54)))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: SalesLineChartPainter(data: _salesChartData),
                  ),
                ),
          // Optional: still show expand icon (points to analytics tab)
          const Positioned(
            bottom: 12,
            right: 12,
            child: Icon(Icons.open_in_full_rounded,
                size: 18, color: Colors.black54),
          )
        ],
      ),
    );
  }

  Widget _buildOrderRow(AdminOrder order) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
          color: const Color(0xFFE2E2E2),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFFD1D1D1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.checkroom,
                color: Color(0xFF4A4A4A), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#ORD - ${order.id}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${order.productName} x${order.quantity}',
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 14)),
              ],
            ),
          ),
          _buildStatusBadge(order.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color labelColor = status == 'Pending'
        ? const Color(0xFFA02B2B)
        : const Color(0xFF2B5B84);
    Color bgColor = status == 'Pending'
        ? const Color(0xFFE5B5B5)
        : const Color(0xFFB5D1E5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Text(status,
          style: TextStyle(
              color: labelColor, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }
}

// ---------- Chart painter for dashboard ----------
class SalesLineChartPainter extends CustomPainter {
  final List<double> data;
  SalesLineChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 0.5;
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;

    // Grid lines
    for (int i = 0; i <= 4; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = List.generate(data.length, (i) {
      final x = size.width * i / (data.length - 1);
      final y = size.height - (data[i] / maxVal * size.height);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots on first, middle and last
    for (final idx in [0, points.length ~/ 2, points.length - 1]) {
      canvas.drawCircle(points[idx], 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}