import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      extended: true,
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Text(
          'SHOP MANAGEMENT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Tổng quan'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.shopping_bag),
          label: Text('Sản phẩm'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.list_alt),
          label: Text('Đơn hàng'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.monetization_on),
          label: Text('Sổ nợ'),
        ),
      ],
    );
  }
}