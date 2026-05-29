import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/models/debt.dart';
import '../../shared/page_state.dart';
import '../../shared/widgets.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});
  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  PageState<List<Debt>> _state = const PageState.initial();
  final _searchCtrl = TextEditingController();
  String _filter = 'Tất cả';
  static const _filters = ['Tất cả', 'Còn nợ', 'Đã thanh toán'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }
  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _state = const PageState.loading());
    try {
      final data = await apiService.getDebts().timeout(const Duration(seconds: 8));
      final debts = data.map((e) => Debt.fromJson(e)).toList();
      if (mounted) setState(() => _state = PageState.success(debts));
    } catch (_) {
      if (mounted) setState(() => _state = PageState.failure(
          'Không kết nối được server.\nKiểm tra backend tại localhost:3000'));
    }
  }

  List<Debt> get _filtered {
    var list = _state.data ?? [];
    if (_filter == 'Còn nợ')       list = list.where((d) => d.totalRevenue > 0).toList();
    if (_filter == 'Đã thanh toán') list = list.where((d) => d.totalRevenue <= 0).toList();
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((d) => d.name.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  double get _totalDebt    => (_state.data ?? []).fold(0, (s, d) => s + d.debtAmount);
  double get _totalPaid    => (_state.data ?? []).fold(0, (s, d) => s + d.amountPaid);
  double get _totalRevenue => (_state.data ?? []).fold(0, (s, d) => s + d.totalRevenue);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Quản Lý Công Nợ',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D2E))),
        ]),
        const SizedBox(height: 16),

        // Summary cards (chỉ khi có data)
        if (_state.isSuccess) ...[
          Row(children: [
            _SumCard('💸', 'Tổng Tiền Nợ', _fmt.format(_totalDebt), Colors.red[700]!),
            const SizedBox(width: 12),
            _SumCard('✅', 'Đã Thu', _fmt.format(_totalPaid), Colors.green[700]!),
            const SizedBox(width: 12),
            _SumCard('📊', 'Còn Lại', _fmt.format(_totalRevenue), Colors.blue[700]!),
          ]),
          const SizedBox(height: 16),
          SearchFilterBar(
            controller: _searchCtrl, hint: 'Tìm tên công nợ...',
            filterOptions: _filters, selectedFilter: _filter,
            onFilterChanged: (v) => setState(() => _filter = v),
            onRefresh: _load,
          ),
          const SizedBox(height: 16),
        ],

        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    if (_state.isInitial) return EmptyInitialWidget(
      emoji: '💰', title: 'Chưa tải dữ liệu công nợ',
      subtitle: 'Công nợ được đồng bộ từ đơn hàng Mobile\nNhấn "Tải dữ liệu" để hiển thị',
      onRefresh: _load,
    );
    if (_state.isLoading) return const Center(
      child: CircularProgressIndicator(color: Color(0xFF4F7FFA)));
    if (_state.isFailure) return ErrorRetryWidget(
        message: _state.errorMessage!, onRetry: _load);

    final list = _filtered;
    if (list.isEmpty) return const EmptySearchWidget();

    return Card(
      elevation: 1, clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DataTable2(
        columnSpacing: 12, horizontalMargin: 16,
        headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
        headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        columns: const [
          DataColumn2(label: Text('Mã'), size: ColumnSize.S),
          DataColumn2(label: Text('Tên công nợ'), size: ColumnSize.L),
          DataColumn2(label: Text('Số tiền nợ'), numeric: true),
          DataColumn2(label: Text('Đã trả'), numeric: true),
          DataColumn2(label: Text('Giảm giá'), numeric: true),
          DataColumn2(label: Text('Còn lại'), numeric: true),
        ],
        rows: list.map((d) {
          final cleared = d.totalRevenue <= 0;
          return DataRow(
            color: WidgetStateProperty.all(cleared ? Colors.green[50] : null),
            cells: [
              DataCell(Text('#${d.id.substring(0,6).toUpperCase()}',
                style: TextStyle(fontFamily: 'monospace',
                    fontSize: 11, color: Colors.grey[500]))),
              DataCell(Row(children: [
                if (cleared)
                  const Padding(padding: EdgeInsets.only(right: 6),
                    child: Text('✅', style: TextStyle(fontSize: 14))),
                Flexible(child: Text(d.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
              ])),
              DataCell(Text(_fmt.format(d.debtAmount),
                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w600))),
              DataCell(Text(_fmt.format(d.amountPaid))),
              DataCell(Text(_fmt.format(d.discount))),
              DataCell(Text(_fmt.format(d.totalRevenue),
                style: TextStyle(
                  color: cleared ? Colors.green[700] : Colors.blue[700],
                  fontWeight: FontWeight.bold))),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SumCard extends StatelessWidget {
  final String emoji, label, value;
  final Color color;
  const _SumCard(this.emoji, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: color),
            overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );
}