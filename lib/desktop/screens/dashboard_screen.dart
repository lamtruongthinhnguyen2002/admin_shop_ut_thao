import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../shared/page_state.dart';
import '../../shared/widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // FIX: Mặc định initial, KHÔNG auto-load
  PageState<Map<String, dynamic>> _state =
      const PageState.initial();

  Future<void> _load() async {
    setState(() => _state = const PageState.loading());
    try {
      final data = await apiService.getDashboardStats()
          .timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _state = PageState.success(data));
    } catch (e) {
      if (mounted) {
        // FIX: Không hiện raw exception, chỉ hiện thông báo thân thiện
        setState(() => _state = PageState.failure(
          'Không kết nối được server.\nKiểm tra backend tại localhost:3000'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng Quan',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1D2E))),
              const SizedBox(height: 4),
              Text(_todayLabel(),
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ]),
            // FIX: Nút Refresh gắn vào đây
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Text('🔄', style: TextStyle(fontSize: 14)),
              label: const Text('Làm mới'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF4F7FFA),
                side: const BorderSide(color: Color(0xFF4F7FFA)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Initial: chưa load lần nào
    if (_state.isInitial) {
      return EmptyInitialWidget(
        emoji: '📊',
        title: 'Chưa có dữ liệu',
        subtitle: 'Bấm "Làm mới" hoặc nút bên dưới để tải dữ liệu\ntừ server',
        onRefresh: _load,
      );
    }

    // Loading
    if (_state.isLoading) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4F7FFA)),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu...', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }

    // Error
    if (_state.isFailure) {
      return ErrorRetryWidget(
        message: _state.errorMessage ?? 'Lỗi không xác định',
        onRetry: _load,
      );
    }

    // Success
    final s = _state.data!;
    return SingleChildScrollView(
      child: Column(children: [
        // 4 stat cards
        LayoutBuilder(builder: (ctx, c) {
          final cols = c.maxWidth > 900 ? 4 : 2;
          return Wrap(spacing: 16, runSpacing: 16, children: [
            _StatCard('💵', 'Tổng Doanh Thu',
                _vnd(_d(s['total_revenue'])), const Color(0xFF4F7FFA),
                'Tích lũy toàn bộ đơn hàng',
                (c.maxWidth - (cols-1)*16) / cols),
            _StatCard('🧾', 'Tổng Đơn Hàng',
                '${s['total_orders']}', const Color(0xFF2DBD8F),
                'Đơn đã tạo',
                (c.maxWidth - (cols-1)*16) / cols),
            _StatCard('⚠️', 'Tổng Công Nợ',
                _vnd(_d(s['total_debt'])), const Color(0xFFFF6B6B),
                'Chưa thanh toán',
                (c.maxWidth - (cols-1)*16) / cols),
            _StatCard('📦', 'Sản Phẩm',
                '${s['total_products']}', const Color(0xFFFF9F43),
                'Đang kinh doanh',
                (c.maxWidth - (cols-1)*16) / cols),
          ]);
        }),
        const SizedBox(height: 24),

        // Chart + Quick actions
        LayoutBuilder(builder: (ctx, c) {
          final wide = c.maxWidth > 800;
          return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3,
                      child: _RevenueChart(data: s['revenue_by_day'] ?? [])),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: _QuickActions()),
                ])
              : Column(children: [
                  _RevenueChart(data: s['revenue_by_day'] ?? []),
                  const SizedBox(height: 16),
                  _QuickActions(),
                ]);
        }),
      ]),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','Chủ Nhật'];
    return '${days[now.weekday - 1]}, ${now.day}/${now.month}/${now.year}';
  }

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _vnd(double v) => NumberFormat.currency(
      locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(v);
}

// ── Widgets ──────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji, title, value, sub;
  final Color color;
  final double width;

  const _StatCard(this.emoji, this.title, this.value,
      this.color, this.sub, this.width);

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
        ]),
        const SizedBox(height: 16),
        Text(value, style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1D2E))),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
      ]),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  final List<dynamic> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06), blurRadius: 10,
            offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Doanh Thu 30 Ngày Gần Nhất',
          style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 15, color: Color(0xFF1A1D2E))),
        const SizedBox(height: 20),
        SizedBox(
          height: 220,
          child: data.isEmpty
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📈', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  Text('Chưa có dữ liệu trong 30 ngày',
                      style: TextStyle(color: Colors.grey[400])),
                ])
              : LineChart(_chartData()),
        ),
      ]),
    );
  }

  LineChartData _chartData() {
    final spots = data.asMap().entries.map((e) =>
        FlSpot(e.key.toDouble(),
            (e.value['revenue'] as num?)?.toDouble() ?? 0)).toList();
    return LineChartData(
      gridData: FlGridData(
        show: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey[100]!, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:  AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 56,
          getTitlesWidget: (v, _) => Text(_short(v),
              style: TextStyle(color: Colors.grey[400], fontSize: 10)),
        )),
        bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true,
        color: const Color(0xFF4F7FFA), barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [const Color(0xFF4F7FFA).withOpacity(0.2),
                     const Color(0xFF4F7FFA).withOpacity(0)],
          )),
      )],
    );
  }

  String _short(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(0)}M';
    if (v >= 1000)    return '${(v/1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
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
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06), blurRadius: 10,
            offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Truy Cập Nhanh',
          style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 14, color: Color(0xFF1A1D2E))),
        const SizedBox(height: 16),
        _Btn(context, '📦', 'Thêm sản phẩm',  '/products'),
        _Btn(context, '🧾', 'Xem đơn hàng',   '/orders'),
        _Btn(context, '💰', 'Quản lý sổ nợ',  '/debts'),
        _Btn(context, '📈', 'Báo cáo doanh thu','/report'),
      ]),
    );
  }

  Widget _Btn(BuildContext ctx, String e, String label, String route) =>
      ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Text(e, style: const TextStyle(fontSize: 18)),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        onTap: () => ctx.go(route),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        hoverColor: const Color(0xFF4F7FFA).withOpacity(0.05),
      );
}