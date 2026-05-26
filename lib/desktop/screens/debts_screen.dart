import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/models/debt.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final ApiService _apiService = ApiService();
  List<Debt> _debts = [];
  bool _isLoading = true;

  @override
  // Đã sửa từ 'niches' thành 'initState' để Flutter nhận diện đúng lifecycle
  void initState() {
    super.initState();
    _fetchDebts();
  }

  Future<void> _fetchDebts() async {
    try {
      // 1. Lấy dữ liệu dạng List thô từ API dịch vụ
      final List<dynamic> rawData = await _apiService.getDebts();
      
      setState(() {
        // 2. Ép kiểu và map từng item từ Map<String, dynamic> sang đối tượng Debt thông qua factory .fromJson
        _debts = rawData.map((item) => Debt.fromJson(item as Map<String, dynamic>)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu công nợ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Công Nợ')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Khách hàng')),
                      DataColumn(label: Text('Số tiền nợ')),
                      DataColumn(label: Text('Ngày hẹn trả')),
                      DataColumn(label: Text('Trạng thái')),
                    ],
                    rows: _debts.map((debt) {
                      // LƯU Ý: Nếu các thuộc tính trong file 'core/models/debt.dart' của bạn 
                      // được đặt tên khác (ví dụ tiếng Việt), hãy thay đổi các biến dưới đây 
                      // cho khớp với model của bạn (ví dụ: debt.khachHang, debt.soTien...)
                      return DataRow(cells: [
                        DataCell(Text(debt.customerName)),
                        DataCell(Text('${debt.amount} đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                        DataCell(Text(debt.dueDate)),
                        DataCell(
                          Chip(
                            label: Text(debt.status),
                            backgroundColor: debt.status == 'Quá hạn' ? Colors.red.shade100 : Colors.orange.shade100,
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}