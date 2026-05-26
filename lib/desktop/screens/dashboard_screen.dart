import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? stats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final data = await apiService.getDashboardStats();
    setState(() { stats = data; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng Quan', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // 4 Stat Cards (từ slides: phải thể hiện bằng số liệu)
          Row(
            children: [
              _StatCard(
                title: 'Tổng Doanh Thu',
                value: _formatCurrency(stats!['total_revenue']),
                icon: Icons.attach_money,
                color: Colors.green,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Tổng Đơn Hàng',
                value: '${stats!['total_orders']}',
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Tổng Công Nợ',
                value: _formatCurrency(stats!['total_debt']),
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Tổng Sản Phẩm',
                value: '${stats!['total_products']}',
                icon: Icons.inventory,
                color: Colors.purple,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Biểu đồ doanh thu (cập nhật theo từng đơn)
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doanh Thu Theo Thời Gian',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: _buildChartSpots(stats!['revenue_by_day']),
                              isCurved: true,
                              color: Colors.blue,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) => Text(
                                  _formatCurrencyShort(value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildChartSpots(List<dynamic> data) {
    return data.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble()))
        .toList();
  }

  String _formatCurrency(dynamic value) {
    // Đã đổi tên biến 'num' thành 'number' để tránh xung đột với kiểu dữ liệu num
    final number = (value as num).toDouble();
    return '${number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
  }

  String _formatCurrencyShort(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(0)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title, required this.value,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.grey)),
                  Text(value, style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}