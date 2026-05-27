import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
// SỬA TẠI ĐÂY: Thêm dòng import go_router để định nghĩa phương thức context.go()
import 'package:go_router/go_router.dart'; 
import '../../core/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? stats;
  bool loading = true;
  String? error;

  // Dữ liệu mẫu khi backend chưa chạy
  static const _mockStats = {
    'total_revenue':  0.0,
    'total_orders':   0,
    'total_debt':     0.0,
    'total_products': 0,
    'revenue_by_day': <Map<String, dynamic>>[],
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await apiService.getDashboardStats()
          .timeout(const Duration(seconds: 6));
      if (mounted) setState(() { stats = data; loading = false; });
    } catch (e) {
      // Backend chưa chạy → dùng mock data thay vì loading mãi
      if (mounted) {
        setState(() {
          stats   = _mockStats;
          loading = false;
          error   = 'Chưa kết nối được server. Đang hiển thị dữ liệu mẫu.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4F7FFA)),
            SizedBox(height: 16),
            Text('Đang tải dữ liệu...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final s = stats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Error banner ───────────────────────────────────
          if (error != null)
            _ErrorBanner(message: error!, onRetry: _loadStats),

          // ── Page header ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng Quan',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
                  const SizedBox(height: 4),
                  Text(
                    _todayLabel(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _loadStats,
                icon: const Text('🔄', style: TextStyle(fontSize: 14)),
                label: const Text('Làm mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F7FFA),
                  side: const BorderSide(color: Color(0xFF4F7FFA)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── 4 Stat Cards ───────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final cols = constraints.maxWidth > 900 ? 4 : 2;
            return Wrap(
              spacing: 16, runSpacing: 16,
              children: [
                _StatCard(
                  emoji: '💵',
                  title: 'Tổng Doanh Thu',
                  value: _vnd((s['total_revenue'] as num).toDouble()),
                  sub: 'Tích lũy toàn bộ đơn hàng',
                  color: const Color(0xFF2DBD8F),
                  width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                ),
                _StatCard(
                  emoji: '🧾',
                  title: 'Tổng Đơn Hàng',
                  value: '${s['total_orders']}',
                  sub: 'Đơn đã tạo',
                  color: const Color(0xFF4F7FFA),
                  width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                ),
                _StatCard(
                  emoji: '⚠️',
                  title: 'Tổng Công Nợ',
                  value: _vnd((s['total_debt'] as num).toDouble()),
                  sub: 'Chưa thanh toán',
                  color: const Color(0xFFFF6B6B),
                  width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                ),
                _StatCard(
                  emoji: '📦',
                  title: 'Sản Phẩm',
                  value: '${s['total_products']}',
                  sub: 'Đang kinh doanh',
                  color: const Color(0xFFFF9F43),
                  width: (constraints.maxWidth - (cols - 1) * 16) / cols,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Chart + Sidebar ────────────────────────────────
          LayoutBuilder(builder: (ctx, constraints) {
            final wide = constraints.maxWidth > 800;
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RevenueChart(data: s['revenue_by_day'] ?? [])),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: _QuickActions()),
                ],
              );
            }
            return Column(children: [
              _RevenueChart(data: s['revenue_by_day'] ?? []),
              const SizedBox(height: 16),
              _QuickActions(),
            ]);
          }),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','Chủ Nhật'];
    final day  = days[now.weekday - 1];
    return '$day, ${now.day}/${now.month}/${now.year}';
  }

  String _vnd(double v) {
    if (v == 0) return '0đ';
    final s = v.toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '${s}đ';
  }
}

// ─────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        border: Border.all(color: const Color(0xFFFFD700)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
              style: const TextStyle(color: Color(0xFF856404), fontSize: 13)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Thử lại', style: TextStyle(color: Color(0xFF856404))),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final String sub;
  final Color color;
  final double width;

  const _StatCard({
    required this.emoji, required this.title, required this.value,
    required this.sub,   required this.color,  required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBD8F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('+0%',
                    style: TextStyle(color: Color(0xFF2DBD8F),
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1D2E))),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<dynamic> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final hasData = data.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Doanh Thu 30 Ngày Gần Nhất',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 15, color: Color(0xFF1A1D2E))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F7FFA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('30 ngày',
                  style: TextStyle(color: Color(0xFF4F7FFA),
                      fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 220,
            child: hasData
                ? LineChart(_buildChart())
                : _EmptyChart(),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChart() {
    final spots = data.asMap().entries.map((e) {
      final v = (e.value['revenue'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), v);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey[100]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:  AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 56,
            getTitlesWidget: (v, _) => Text(
              _short(v), style: TextStyle(color: Colors.grey[400], fontSize: 10)),
          ),
        ),
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF4F7FFA),
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4F7FFA).withOpacity(0.2),
                const Color(0xFF4F7FFA).withOpacity(0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📈', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('Chưa có dữ liệu doanh thu',
          style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        const SizedBox(height: 4),
        Text('Tạo đơn hàng đầu tiên từ Mobile để xem biểu đồ',
          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Truy Cập Nhanh',
            style: TextStyle(fontWeight: FontWeight.bold,
                fontSize: 14, color: Color(0xFF1A1D2E))),
          const SizedBox(height: 16),
          _QuickBtn(emoji: '📦', label: 'Thêm sản phẩm',   route: '/products'),
          _QuickBtn(emoji: '🧾', label: 'Xem đơn hàng',    route: '/orders'),
          _QuickBtn(emoji: '💰', label: 'Quản lý sổ nợ',  route: '/debts'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F7FFA).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4F7FFA).withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Text('📱', style: TextStyle(fontSize: 16)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mở app Mobile để quét QR và tạo đơn hàng',
                    style: TextStyle(color: Color(0xFF4F7FFA), fontSize: 11),
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

class _QuickBtn extends StatelessWidget {
  final String emoji;
  final String label;
  final String route;
  const _QuickBtn({required this.emoji, required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(emoji, style: const TextStyle(fontSize: 18)),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: () => context.go(route),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      hoverColor: const Color(0xFF4F7FFA).withOpacity(0.05),
    );
  }
}