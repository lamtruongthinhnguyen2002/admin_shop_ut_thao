import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../desktop/widgets/stat_card.dart'; // Tái sử dụng StatCard đã sửa lỗi ở bước trước

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng Quan Cửa Hàng', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners Chào mừng & Lối tắt nhanh
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xin chào ngày mới!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hôm nay bạn muốn làm gì?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Quét Mã Đơn Hàng / QR'),
                    onPressed: () => context.go('/scan'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Chỉ số báo cáo nhanh (Grid 2 cột phù hợp màn hình Mobile)
            const Text(
              'Báo cáo hôm nay',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: const [
                StatCard(
                  title: 'Doanh thu',
                  value: '1.250k',
                  icon: Icons.monetization_on,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Đơn mới',
                  value: '12 đh',
                  icon: Icons.shopping_bag,
                  color: Colors.orange,
                ),
                StatCard(
                  title: 'Tổng công nợ',
                  value: '4.800k',
                  icon: Icons.assignment_late,
                  color: Colors.red,
                ),
                StatCard(
                  title: 'Sản phẩm',
                  value: '150',
                  icon: Icons.inventory,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Truy cập nhanh danh mục dữ liệu chính
            const Text(
              'Quản lý nhanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.blue),
                    title: const Text('Xem danh sách đơn hàng'),
                    trailing: const Icon(Icons.chevron_right),
                    // SỬA TẠI ĐÂY: Đổi từ 'onPressed' thành 'onTap'
                    onTap: () => context.go('/order-list'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.monetization_on_outlined, color: Colors.red),
                    title: const Text('Xem sổ nợ khách hàng'),
                    trailing: const Icon(Icons.chevron_right),
                    // SỬA TẠI ĐÂY: Đổi từ 'onPressed' thành 'onTap'
                    onTap: () => context.go('/debt-list'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}