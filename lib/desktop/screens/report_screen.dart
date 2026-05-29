import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../shared/page_state.dart';
import '../../shared/widgets.dart';

enum _Period { day, week, month }

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  _Period _period = _Period.month;
  // FIX: Mặc định initial, KHÔNG load + KHÔNG mock data
  PageState<List<Map<String, dynamic>>> _state = const PageState.initial();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<Map<String, dynamic>> get _orders => _state.data ?? [];

  // FIX: Tất cả tổng mặc định = 0 khi chưa có data
  double get _totalRevenue => _orders.fold(0, (s, o) => s + _d(o['total_revenue']));
  double get _totalDebt    => _orders.fold(0, (s, o) => s + _d(o['debt']));
  double get _totalDiscount=> _orders.fold(0, (s, o) => s + _d(o['discount']));
  int    get _totalOrders  => _orders.length;

  Future<void> _load() async {
    setState(() => _state = const PageState.loading());
    try {
      final all = await apiService.getOrders()
          .timeout(const Duration(seconds: 8));
      final now   = DateTime.now();
      final start = _periodStart(now);
      final filtered = all.where((o) {
        final date = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime(2000);
        return date.isAfter(start);
      }).toList();
      if (mounted) setState(() => _state = PageState.success(filtered));
    } catch (_) {
      if (mounted) setState(() => _state = PageState.failure(
          'Không kết nối được server.\nKiểm tra backend tại localhost:3000'));
    }
  }

  DateTime _periodStart(DateTime now) {
    switch (_period) {
      case _Period.day:   return DateTime(now.year, now.month, now.day);
      case _Period.week:  return now.subtract(const Duration(days: 7));
      case _Period.month: return now.subtract(const Duration(days: 30));
    }
  }

  List<_ChartPt> get _chartData {
    final map = <String, double>{};
    for (final o in _orders) {
      final date = DateTime.tryParse(o['created_at'] ?? '') ?? DateTime.now();
      final key  = DateFormat('dd/MM').format(date);
      map[key]   = (map[key] ?? 0) + _d(o['total_revenue']);
    }
    return map.entries.map((e) => _ChartPt(e.key, e.value)).toList();
  }

  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                isDesktop ? 28 : 16, 28, isDesktop ? 28 : 16, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header + period + refresh
              isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Header(),
                        Row(children: [
                          _PeriodSel(current: _period,
                              onChange: (p) { setState(() => _period = p); _load(); }),
                          const SizedBox(width: 8),
                          Container(
                            height: 40, width: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F7FFA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              icon: const Text('🔄', style: TextStyle(fontSize: 16)),
                              onPressed: _load, tooltip: 'Tải dữ liệu',
                            ),
                          ),
                        ]),
                      ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _Header(),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _PeriodSel(current: _period,
                            onChange: (p) { setState(() => _period = p); _load(); })),
                        const SizedBox(width: 8),
                        ElevatedButton(onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F7FFA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: const Text('🔄 Tải dữ liệu')),
                      ]),
                    ]),
              const SizedBox(height: 20),
            ]),
          ),
        ),

        // Body
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 28 : 16),
          sliver: SliverToBoxAdapter(child: _buildBody(isDesktop)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ]),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_state.isInitial) {
      return EmptyInitialWidget(
        emoji: '📈',
        title: 'Chưa tải báo cáo',
        subtitle: 'Chọn kỳ và nhấn "Tải dữ liệu"\nđể xem báo cáo doanh thu',
        onRefresh: _load,
      );
    }
    if (_state.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4F7FFA)),
            SizedBox(height: 12),
            Text('Đang tải báo cáo...', style: TextStyle(color: Colors.grey)),
          ],
        )),
      );
    }
    if (_state.isFailure) {
      return SizedBox(height: 300,
        child: ErrorRetryWidget(message: _state.errorMessage!, onRetry: _load));
    }

    // Success
    return Column(children: [
      // Summary cards
      isDesktop
          ? Row(children: [
              _Card('💵', 'Doanh Thu', _fmt.format(_totalRevenue), const Color(0xFF4F7FFA)),
              const SizedBox(width: 12),
              _Card('🧾', 'Đơn Hàng', '$_totalOrders đơn', const Color(0xFF2DBD8F)),
              const SizedBox(width: 12),
              _Card('⚠️', 'Công Nợ', _fmt.format(_totalDebt), const Color(0xFFFF6B6B)),
              const SizedBox(width: 12),
              _Card('🎁', 'Giảm Giá', _fmt.format(_totalDiscount), const Color(0xFFFF9F43)),
            ])
          : GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12, crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                _Card('💵', 'Doanh Thu', _fmt.format(_totalRevenue), const Color(0xFF4F7FFA)),
                _Card('🧾', 'Đơn Hàng', '$_totalOrders đơn', const Color(0xFF2DBD8F)),
                _Card('⚠️', 'Công Nợ', _fmt.format(_totalDebt), const Color(0xFFFF6B6B)),
                _Card('🎁', 'Giảm Giá', _fmt.format(_totalDiscount), const Color(0xFFFF9F43)),
              ],
            ),

      const SizedBox(height: 20),

      // Chart
      _chartBox(isDesktop),
      const SizedBox(height: 20),

      // Tabs
      Container(
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 3))]),
        child: Column(children: [
          TabBar(controller: _tabCtrl,
            labelColor: const Color(0xFF4F7FFA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF4F7FFA),
            tabs: const [Tab(text: '📦  Theo sản phẩm'),
                         Tab(text: '🧾  Chi tiết đơn hàng')]),
          SizedBox(
            height: 360,
            child: _orders.isEmpty
                ? const Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('📭', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 12),
                      Text('Không có đơn hàng trong kỳ này',
                        style: TextStyle(color: Colors.grey)),
                    ]))
                : TabBarView(controller: _tabCtrl, children: [
                    _ProductTable(orders: _orders),
                    _OrderTable(orders: _orders, fmt: _fmt),
                  ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _chartBox(bool isDesktop) {
    final data = _chartData;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📈  Biểu Đồ Doanh Thu',
          style: TextStyle(fontWeight: FontWeight.bold,
              fontSize: 15, color: Color(0xFF1A1D2E))),
        const SizedBox(height: 20),
        SizedBox(
          height: isDesktop ? 220 : 180,
          child: data.isEmpty
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('📊', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text('Không có giao dịch trong kỳ này',
                    style: TextStyle(color: Colors.grey[400])),
                ])
              : BarChart(BarChartData(
                  maxY: data.map((e) => e.v).reduce((a,b) => a>b?a:b) * 1.2,
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey[100]!, strokeWidth: 1)),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 56,
                      getTitlesWidget: (v, _) => Text(_short(v),
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                    )),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 20,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i >= data.length) return const SizedBox.shrink();
                        return Text(data[i].label,
                          style: TextStyle(color: Colors.grey[400], fontSize: 9));
                      },
                    )),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(
                      toY: e.value.v, width: isDesktop ? 18 : 10,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)]),
                    )],
                  )).toList(),
                )),
        ),
      ]),
    );
  }

  Widget _Card(String e, String label, String val, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10)),
          child: Center(child: Text(e, style: const TextStyle(fontSize: 18)))),
        const SizedBox(height: 10),
        Text(val, style: TextStyle(fontSize: 18,
            fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
      ]),
    ),
  );

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0.0;
  String _short(double v) {
    if (v >= 1000000) return '${(v/1000000).toStringAsFixed(0)}M';
    if (v >= 1000)    return '${(v/1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _ChartPt { final String label; final double v; _ChartPt(this.label, this.v); }

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Báo Cáo Doanh Thu',
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
            color: Color(0xFF1A1D2E))),
      const SizedBox(height: 4),
      Text('Phân tích theo kỳ',
        style: TextStyle(color: Colors.grey[500], fontSize: 13)),
    ]);
}

class _PeriodSel extends StatelessWidget {
  final _Period current;
  final ValueChanged<_Period> onChange;
  const _PeriodSel({required this.current, required this.onChange});

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFE0E4F0))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      _Btn('Hôm nay', _Period.day,   current, onChange),
      _Btn('7 ngày',  _Period.week,  current, onChange),
      _Btn('30 ngày', _Period.month, current, onChange),
    ]),
  );
}

class _Btn extends StatelessWidget {
  final String label; final _Period val, cur; final ValueChanged<_Period> cb;
  const _Btn(this.label, this.val, this.cur, this.cb);

  @override
  Widget build(BuildContext context) {
    final active = val == cur;
    return GestureDetector(
      onTap: () => cb(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4F7FFA) : Colors.transparent,
          borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(label, style: TextStyle(
          color: active ? Colors.white : Colors.grey[600],
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.normal))),
      ),
    );
  }
}

class _ProductTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  const _ProductTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    final map = <String, Map<String, dynamic>>{};
    for (final o in orders) {
      final name = o['product_name'] as String? ?? '';
      if (!map.containsKey(name)) map[name] = {'qty': 0, 'revenue': 0.0};
      map[name]!['qty'] = (map[name]!['qty'] as int) + ((o['quantity'] as num?)?.toInt() ?? 0);
      map[name]!['revenue'] = (map[name]!['revenue'] as double) + ((o['total_revenue'] as num?)?.toDouble() ?? 0);
    }
    final total = map.values.fold(0.0, (s, v) => s + (v['revenue'] as double));
    final entries = map.entries.toList()
      ..sort((a,b) => (b.value['revenue'] as double).compareTo(a.value['revenue'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3), 1: FlexColumnWidth(1),
          2: FlexColumnWidth(2), 3: FlexColumnWidth(1),
        },
        children: [
          _tRow(['Sản phẩm', 'SL', 'Doanh thu', '%'], isHeader: true),
          ...entries.map((e) {
            final pct = total > 0 ? e.value['revenue'] / total * 100 : 0.0;
            return _tRow([e.key, '${e.value['qty']}',
              fmt.format(e.value['revenue']), '${pct.toStringAsFixed(0)}%']);
          }),
        ],
      ),
    );
  }

  TableRow _tRow(List<String> cells, {bool isHeader = false}) => TableRow(
    decoration: isHeader ? BoxDecoration(color: Colors.grey[50]) : null,
    children: cells.map((c) => TableCell(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(c, style: TextStyle(
          fontWeight: isHeader ? FontWeight.w700 : FontWeight.normal,
          fontSize: isHeader ? 12 : 13)),
      ))).toList(),
  );
}

class _OrderTable extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final NumberFormat fmt;
  const _OrderTable({required this.orders, required this.fmt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 20,
          columns: const [
            DataColumn(label: Text('Mã',        style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Sản phẩm',  style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('SL',        style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Phải thu',  style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Đã trả',    style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Nợ',        style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Doanh thu', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: orders.map((o) {
            final debt = (o['debt'] as num?)?.toDouble() ?? 0.0;
            return DataRow(cells: [
              DataCell(Text('#${(o['id'] as String? ?? '').substring(0, 6).toUpperCase()}',
                style: TextStyle(fontFamily: 'monospace',
                    fontSize: 11, color: Colors.grey[500]))),
              DataCell(Text(o['product_name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text('${o['quantity']}')),
              DataCell(Text(fmt.format((o['amount_due'] as num?)?.toDouble() ?? 0))),
              DataCell(Text(fmt.format((o['amount_paid'] as num?)?.toDouble() ?? 0))),
              DataCell(Text(fmt.format(debt),
                style: TextStyle(
                  color: debt > 0 ? Colors.red[600] : Colors.green[600],
                  fontWeight: FontWeight.w600))),
              DataCell(Text(fmt.format((o['total_revenue'] as num?)?.toDouble() ?? 0),
                style: const TextStyle(
                  color: Color(0xFF4F7FFA), fontWeight: FontWeight.w700))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}