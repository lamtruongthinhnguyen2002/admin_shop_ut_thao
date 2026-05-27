// ignore_for_file: unused_element_parameter, unused_import

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../mobile/widgets/mobile_bottom_nav.dart';

enum _Period { day, week, month }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  _Period  _period  = _Period.month;
  bool     _loading = true;
  String?  _error;
  late TabController _tabCtrl;

  // Dữ liệu
  List<Map<String, dynamic>> _orders    = [];
  List<_ChartPoint>          _chartData = [];

  // Tổng hợp
  double get _totalRevenue => _orders.fold(0, (s, o) => s + _d(o['total_revenue']));
  double get _totalDebt    => _orders.fold(0, (s, o) => s + _d(o['debt']));
  double get _totalDiscount=> _orders.fold(0, (s, o) => s + _d(o['discount']));
  int    get _totalOrders  => _orders.length;

  // Theo sản phẩm
  Map<String, _ProductStat> get _byProduct {
    final map = <String, _ProductStat>{};
    for (final o in _orders) {
      final name = o['product_name'] as String;
      map[name] = (map[name] ?? _ProductStat(name: name)).add(
        qty:     (o['quantity'] as num).toInt(),
        revenue: _d(o['total_revenue']),
        debt:    _d(o['debt']),
      );
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.value.revenue.compareTo(a.value.revenue)));
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await apiService.getOrders()
          .timeout(const Duration(seconds: 6));
      final now   = DateTime.now();
      final start = _periodStart(now);

      _orders = orders.where((o) {
        final date = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime(2000);
        return date.isAfter(start);
      }).toList();

      _buildChart();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      // Dữ liệu demo khi chưa có backend
      _orders    = _demoOrders();
      _buildChart();
      if (mounted) setState(() { _loading = false; _error = 'Demo data – Chưa kết nối server'; });
    }
  }

  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case _Period.day:   return DateTime(now.year, now.month, now.day);
      case _Period.week:  return now.subtract(const Duration(days: 7));
      case _Period.month: return now.subtract(const Duration(days: 30));
    }
  }

  void _buildChart() {
    final Map<String, double> grouped = {};
    for (final o in _orders) {
      final date = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now();
      final key  = _chartKey(date);
      grouped[key] = (grouped[key] ?? 0) + _d(o['total_revenue']);
    }
    final sorted = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    _chartData = sorted.map((e) => _ChartPoint(e.key, e.value)).toList();
  }

  String _chartKey(DateTime d) {
    switch (_period) {
      case _Period.day:   return '${d.hour}h';
      case _Period.week:  return DateFormat('dd/MM').format(d);
      case _Period.month: return DateFormat('dd/MM').format(d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4F7FFA)))
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  // ── AppBar ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          isDesktop ? 28 : 16, 28, isDesktop ? 28 : 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Error banner
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(children: [
                                const Text('⚠️'),
                                const SizedBox(width: 8),
                                Text(_error!, style: const TextStyle(fontSize: 12)),
                              ]),
                            ),

                          // Header + period selector
                          isDesktop
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _PageHeader(),
                                    _PeriodSelector(
                                      current: _period,
                                      onChange: (p) {
                                        setState(() => _period = p);
                                        _load();
                                      },
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _PageHeader(),
                                    const SizedBox(height: 12),
                                    _PeriodSelector(
                                      current: _period,
                                      onChange: (p) {
                                        setState(() => _period = p);
                                        _load();
                                      },
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // ── Summary cards ────────────────────────────
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 28 : 16),
                    sliver: SliverToBoxAdapter(
                      child: isDesktop
                          ? Row(
                              children: [
                                _buildCard('💵', 'Doanh Thu', _vnd(_totalRevenue), const Color(0xFF4F7FFA)),
                                const SizedBox(width: 12),
                                _buildCard('🧾', 'Đơn Hàng', '$_totalOrders đơn', const Color(0xFF2DBD8F)),
                                const SizedBox(width: 12),
                                _buildCard('⚠️', 'Công Nợ', _vnd(_totalDebt), const Color(0xFFFF6B6B)),
                                const SizedBox(width: 12),
                                _buildCard('🎁', 'Giảm Giá', _vnd(_totalDiscount), const Color(0xFFFF9F43)),
                              ],
                            )
                          : GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.6,
                              children: [
                                _buildCard('💵', 'Doanh Thu', _vnd(_totalRevenue), const Color(0xFF4F7FFA)),
                                _buildCard('🧾', 'Đơn Hàng', '$_totalOrders đơn', const Color(0xFF2DBD8F)),
                                _buildCard('⚠️', 'Công Nợ', _vnd(_totalDebt), const Color(0xFFFF6B6B)),
                                _buildCard('🎁', 'Giảm Giá', _vnd(_totalDiscount), const Color(0xFFFF9F43)),
                              ],
                            ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Chart ─────────────────────────────────────
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 28 : 16),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: _cardDeco(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('📈  Biểu Đồ Doanh Thu',
                                  style: TextStyle(fontWeight: FontWeight.bold,
                                      fontSize: 15, color: Color(0xFF1A1D2E))),
                                Text('${_chartData.length} điểm dữ liệu',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: isDesktop ? 240 : 200,
                              child: _chartData.isEmpty
                                  ? _EmptyChart()
                                  : _buildBarChart(isDesktop),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                  // ── Tabs: Chi tiết ────────────────────────────
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 28 : 16),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: _cardDeco(),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabCtrl,
                              labelColor: const Color(0xFF4F7FFA),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: const Color(0xFF4F7FFA),
                              tabs: const [
                                Tab(text: '📦  Theo Sản Phẩm'),
                                Tab(text: '🧾  Chi Tiết Đơn Hàng'),
                              ],
                            ),
                            SizedBox(
                              height: 400,
                              child: TabBarView(
                                controller: _tabCtrl,
                                children: [
                                  _ProductTable(stats: _byProduct),
                                  _OrderTable(orders: _orders),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(String emoji, String label, String value, Color color) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
        ],
      ),
    );
    return isDesktop ? Expanded(child: card) : card;
  }

  Widget _buildBarChart(bool isDesktop) {
    if (_chartData.isEmpty) return _EmptyChart();
    final maxY = _chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: Colors.grey[100]!, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              getTitlesWidget: (v, _) => Text(
                _short(v), style: TextStyle(color: Colors.grey[400], fontSize: 10)),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i >= _chartData.length) return const SizedBox.shrink();
                if (isDesktop || i % 3 == 0) {
                  return Text(_chartData[i].label,
                    style: TextStyle(color: Colors.grey[400], fontSize: 9));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _chartData.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.value,
                width: isDesktop ? 18 : 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)],
                ),
              ),
            ],
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, _, rod, __) => BarTooltipItem(
              '${_chartData[group.x].label}\n${_vnd(rod.toY)}',
              const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 10, offset: const Offset(0, 3)),
    ],
  );

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;

  String _vnd(double v) => NumberFormat.currency(
      locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(v);

  String _short(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M';
    if (v >= 1000)    return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  // Dữ liệu demo
  List<Map<String, dynamic>> _demoOrders() {
    final now = DateTime.now();
    return List.generate(12, (i) => {
      'id':           'demo-$i',
      'product_name': ['Cà phê', 'Trà sữa', 'Bánh mì', 'Nước ép'][i % 4],
      'quantity':     (i % 3) + 1,
      'amount_due':   ((i + 1) * 25000).toDouble(),
      'discount':     (i % 4 == 0 ? 5000 : 0).toDouble(),
      'amount_paid':  ((i + 1) * 25000).toDouble(),
      'debt':         (i % 5 == 0 ? 15000 : 0).toDouble(),
      'total_revenue':((i + 1) * 25000 - (i % 4 == 0 ? 5000 : 0)).toDouble(),
      'created_at':   now.subtract(Duration(days: i * 2)).toIso8601String(),
    });
  }
}

// ─────────────────────────────────────────────────────────
// Sub widgets
// ─────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Báo Cáo Doanh Thu',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D2E))),
          const SizedBox(height: 4),
          Text('Phân tích chi tiết theo kỳ',
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      );
}

class _PeriodSelector extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChange;

  const _PeriodSelector({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E4F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PeriodBtn('Hôm nay',  _Period.day,   current, onChange),
          _PeriodBtn('7 ngày',   _Period.week,  current, onChange),
          _PeriodBtn('30 ngày',  _Period.month, current, onChange),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final _Period value, current;
  final ValueChanged<_Period> onChange;

  const _PeriodBtn(this.label, this.value, this.current, this.onChange);

  @override
  Widget build(BuildContext context) {
    final active = value == current;
    return GestureDetector(
      onTap: () => onChange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4F7FFA) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : Colors.grey[600],
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            )),
        ),
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final Map<String, _ProductStat> stats;
  const _ProductTable({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu'));
    }

    final total = stats.values.fold(0.0, (s, v) => s + v.revenue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(2),
          3: FlexColumnWidth(1),
        },
        children: [
          // Header
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[50]),
            children: ['Sản phẩm', 'SL', 'Doanh thu', '%']
                .map((h) => TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(h,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12)),
                    )))
                .toList(),
          ),
          // Rows
          ...stats.values.map((s) {
            final pct = total > 0 ? s.revenue / total * 100 : 0.0;
            return TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 4,
                            backgroundColor: Colors.grey[100],
                            color: const Color(0xFF4F7FFA),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _cell('${s.qty}'),
                _cell(_vnd(s.revenue),
                    color: const Color(0xFF2DBD8F), bold: true),
                _cell('${pct.toStringAsFixed(0)}%',
                    color: Colors.grey[600]),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _cell(String text, {Color? color, bool bold = false}) => TableCell(
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Text(text,
        style: TextStyle(
          color: color, fontSize: 13,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
    ),
  );

  String _vnd(double v) => NumberFormat.currency(
      locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(v);
}

class _OrderTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const _OrderTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Mã', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Sản phẩm', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('SL',       style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Phải thu', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Đã trả',   style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Nợ',       style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Doanh thu',style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: orders.map((o) {
            final debt = _d(o['debt']);
            return DataRow(cells: [
              DataCell(Text(
                '#${(o['id'] as String).substring(0, 6).toUpperCase()}',
                style: TextStyle(color: Colors.grey[500], fontSize: 11,
                    fontFamily: 'monospace'))),
              DataCell(Text(o['product_name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text('${o['quantity']}')),
              DataCell(Text(_vnd(_d(o['amount_due'])))),
              DataCell(Text(_vnd(_d(o['amount_paid'])))),
              DataCell(Text(_vnd(debt),
                style: TextStyle(
                  color: debt > 0 ? Colors.red[600] : Colors.green[600],
                  fontWeight: FontWeight.w600))),
              DataCell(Text(_vnd(_d(o['total_revenue'])),
                style: const TextStyle(
                  color: Color(0xFF4F7FFA), fontWeight: FontWeight.w700))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _vnd(double v) => NumberFormat.currency(
      locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(v);
}

class _EmptyChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Text('📊', style: TextStyle(fontSize: 40)),
      const SizedBox(height: 12),
      Text('Chưa có dữ liệu trong kỳ này',
          style: TextStyle(color: Colors.grey[400])),
    ],
  );
}

// ─── Data classes ─────────────────────────────────────────

class _ChartPoint {
  final String label;
  final double value;
  _ChartPoint(this.label, this.value);
}

class _ProductStat {
  final String name;
  int    qty;
  double revenue;
  double debt;

  _ProductStat({required this.name, this.qty = 0, this.revenue = 0, this.debt = 0});

  _ProductStat add({required int qty, required double revenue, required double debt}) {
    this.qty     += qty;
    this.revenue += revenue;
    this.debt    += debt;
    return this;
  }
}