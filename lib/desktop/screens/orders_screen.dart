import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/models/order.dart';
import '../../shared/page_state.dart';
import '../../shared/widgets.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  PageState<List<Order>> _state = const PageState.initial();
  final _searchCtrl = TextEditingController();
  String _filter = 'Tất cả';
  static const _filters = ['Tất cả', 'Có nợ', 'Không nợ'];

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
      final data = await apiService.getOrders().timeout(const Duration(seconds: 8));
      final orders = data.map((e) => Order.fromJson(e)).toList();
      if (mounted) setState(() => _state = PageState.success(orders));
    } catch (_) {
      if (mounted) setState(() => _state = PageState.failure(
          'Không kết nối được server.\nKiểm tra backend tại localhost:3000'));
    }
  }

  List<Order> get _filtered {
    var list = _state.data ?? [];
    if (_filter == 'Có nợ')   list = list.where((o) => o.debt > 0).toList();
    if (_filter == 'Không nợ') list = list.where((o) => o.debt <= 0).toList();
    final q = _searchCtrl.text.toLowerCase().trim();
    if (q.isNotEmpty) {
      list = list.where((o) =>
          o.productName.toLowerCase().contains(q) ||
          o.id.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  final _fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Quản Lý Đơn Hàng',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D2E))),
            const SizedBox(height: 4),
            Text(_state.isSuccess
                ? 'Tổng cộng: ${_state.data!.length} đơn hàng'
                : 'Nhấn "Tải dữ liệu" để bắt đầu',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 16),

        if (_state.isSuccess) ...[
          SearchFilterBar(
            controller: _searchCtrl, hint: 'Tìm mã đơn hoặc tên sản phẩm...',
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
      emoji: '🧾', title: 'Chưa tải dữ liệu đơn hàng',
      subtitle: 'Đơn hàng được đồng bộ từ Mobile\nNhấn "Tải dữ liệu" để hiển thị',
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
          DataColumn2(label: Text('Mã đơn'),    size: ColumnSize.S),
          DataColumn2(label: Text('Sản phẩm'),  size: ColumnSize.L),
          DataColumn2(label: Text('SL'),        size: ColumnSize.S),
          DataColumn2(label: Text('Phải trả'),  numeric: true),
          DataColumn2(label: Text('Giảm giá'),  numeric: true),
          DataColumn2(label: Text('Đã trả'),    numeric: true),
          DataColumn2(label: Text('Công nợ'),   numeric: true),
          DataColumn2(label: Text('Doanh thu'), numeric: true),
        ],
        rows: list.map((o) => DataRow(cells: [
          DataCell(Text('#${o.id.substring(0,6).toUpperCase()}',
            style: TextStyle(fontFamily: 'monospace',
                fontSize: 11, color: Colors.grey[600]))),
          DataCell(Text(o.productName,
            style: const TextStyle(fontWeight: FontWeight.w500))),
          DataCell(Text('${o.quantity}')),
          DataCell(Text(_fmt.format(o.amountDue))),
          DataCell(Text(_fmt.format(o.discount))),
          DataCell(Text(_fmt.format(o.amountPaid))),
          DataCell(Text(_fmt.format(o.debt),
            style: TextStyle(
              color: o.debt > 0 ? Colors.red[600] : Colors.green[600],
              fontWeight: FontWeight.w600))),
          DataCell(Text(_fmt.format(o.totalRevenue),
            style: const TextStyle(
              color: Color(0xFF4F7FFA), fontWeight: FontWeight.bold))),
        ])).toList(),
      ),
    );
  }
}