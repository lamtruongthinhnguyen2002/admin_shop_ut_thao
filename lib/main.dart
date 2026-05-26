import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'desktop/screens/dashboard_screen.dart';
import 'desktop/screens/products_screen.dart';
import 'desktop/screens/orders_screen.dart';
import 'desktop/screens/debts_screen.dart';
import 'desktop/widgets/side_menu.dart'; // Đã thêm import SideMenu
import 'mobile/screens/qr_scan_screen.dart';
import 'mobile/screens/order_list_screen.dart';
import 'mobile/screens/debt_list_screen.dart';
import 'mobile/screens/mobile_home_screen.dart'; // Đã được sử dụng, không còn cảnh báo nữa
import 'mobile/widgets/mobile_bottom_nav.dart'; // Đã thêm import MobileBottomNav

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quản Lý Đơn Hàng',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// Phân biệt Desktop vs Mobile tự động
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // Nếu là mobile → hiện bottom nav
        // Nếu là desktop/web → hiện side menu
        final isDesktop = MediaQuery.of(context).size.width > 768;
        return isDesktop
            ? DesktopShell(child: child)
            : MobileShell(child: child);
      },
      routes: [
        // SỬA TẠI ĐÂY: Sử dụng MediaQuery để tự động trả về màn hình trang chủ phù hợp theo kích thước thiết bị
        GoRoute(
          path: '/',
          builder: (context, state) {
            final isDesktop = MediaQuery.of(context).size.width > 768;
            return isDesktop ? const DashboardScreen() : const MobileHomeScreen();
          },
        ),
        GoRoute(path: '/products', builder: (_, __) => const ProductsScreen()),
        GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/debts', builder: (_, __) => const DebtsScreen()),
        GoRoute(path: '/scan', builder: (_, __) => const QrScanScreen()),
        GoRoute(path: '/order-list', builder: (_, __) => const OrderListScreen()),
        GoRoute(path: '/debt-list', builder: (_, __) => const DebtListScreen()),
      ],
    ),
  ],
);

// --- BỔ SUNG ĐỊNH NGHĨA DESKTOP SHELL ---
class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/products') return 1;
    if (location == '/orders') return 2;
    if (location == '/debts') return 3;
    return 0; // Mặc định là Dashboard '/'
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/products'); break;
      case 2: context.go('/orders'); break;
      case 3: context.go('/debts'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            selectedIndex: _getSelectedIndex(context),
            onSelected: (index) => _onItemTapped(index, context),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// --- BỔ SUNG ĐỊNH NGHĨA MOBILE SHELL ---
class MobileShell extends StatelessWidget {
  final Widget child;
  const MobileShell({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/scan') return 1;
    if (location == '/order-list') return 2;
    if (location == '/debt-list') return 3;
    return 0; // Mặc định là Home '/'
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/scan'); break;
      case 2: context.go('/order-list'); break;
      case 3: context.go('/debt-list'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: MobileBottomNav(
        currentIndex: _getSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}