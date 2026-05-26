import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/models/debt.dart';

class DebtListScreen extends StatelessWidget {
  const DebtListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sổ Nợ Di Động')),
      body: FutureBuilder<List<Debt>>(
        // SỬA TẠI ĐÂY: Dùng .then() để map List<dynamic> thành List<Debt> trước khi truyền vào FutureBuilder
        future: ApiService().getDebts().then((rawData) {
          return (rawData as List)
              .map((item) => Debt.fromJson(item as Map<String, dynamic>))
              .toList();
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu công nợ.'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final debt = snapshot.data![index];
              return ListTile(
                title: Text(debt.customerName),
                subtitle: Text('Hạn trả: ${debt.dueDate}'),
                trailing: Text('${debt.amount} đ', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}