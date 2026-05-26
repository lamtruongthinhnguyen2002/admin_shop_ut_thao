import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/api_service.dart';
import '../../core/models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> orders = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final data = await apiService.getOrders();
    setState(() {
      orders = data.map((e) => Order.fromJson(e)).toList();
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản Lý Đơn Hàng',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Dữ liệu được cập nhật từ giao diện Mobile',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 16),

          Expanded(
            child: loading
              ? const Center(child: CircularProgressIndicator())
              : DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn2(label: Text('Mã đơn hàng'), size: ColumnSize.S),
                    DataColumn2(label: Text('Tên đơn hàng'), size: ColumnSize.L),
                    DataColumn2(label: Text('Số lượng'), size: ColumnSize.S),
                    DataColumn2(label: Text('Phải trả'), numeric: true),
                    DataColumn2(label: Text('Giảm giá'), numeric: true),
                    DataColumn2(label: Text('Khách trả'), numeric: true),
                    DataColumn2(label: Text('Công nợ'), numeric: true),
                    DataColumn2(label: Text('Doanh thu'), numeric: true),
                  ],
                  rows: orders.map((o) => DataRow(cells: [
                    DataCell(Text(o.id.substring(0, 8))),
                    DataCell(Text(o.productName)),
                    DataCell(Text('${o.quantity}')),
                    DataCell(Text(_vnd(o.amountDue))),
                    DataCell(Text(_vnd(o.discount))),
                    DataCell(Text(_vnd(o.amountPaid))),
                    DataCell(Text(_vnd(o.debt),
                      style: TextStyle(color: o.debt > 0 ? Colors.red : Colors.green))),
                    DataCell(Text(_vnd(o.totalRevenue),
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  ])).toList(),
                ),
          ),
        ],
      ),
    );
  }

  String _vnd(double v) =>
    '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}đ';
}