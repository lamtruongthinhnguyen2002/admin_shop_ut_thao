import 'package:flutter/material.dart';

class MobileBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const MobileBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Quét mã'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Đơn hàng'),
        BottomNavigationBarItem(icon: Icon(Icons.monetization_on), label: 'Công nợ'),
      ],
    );
  }
}