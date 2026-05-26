import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/models/order.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final ApiService _apiService = ApiService();
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  // SỬA TẠI ĐÂY: Đổi từ 'niches' thành 'initState' để Flutter chạy đúng lifecycle
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      // 1. Lấy dữ liệu danh sách thô từ API
      final List<dynamic> rawData = await _apiService.getOrders();
      
      setState(() {
        // 2. Ép kiểu và chuyển đổi từng item sang đối tượng Order
        _orders = rawData.map((item) => Order.fromJson(item as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách đơn hàng')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                final order = _orders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.receipt)),
                    title: Text('Đơn hàng #${order.id}'),
                    // LƯU Ý: Nếu model Order của bạn đặt tên biến khác (ví dụ: tiếng Việt), 
                    // hãy chỉnh sửa các trường order.customerName, order.date, order.totalAmount dưới đây cho khớp.
                    subtitle: Text('Khách: ${order.customerName}\nNgày: ${order.date}'),
                    trailing: Text('${order.totalAmount} đ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}