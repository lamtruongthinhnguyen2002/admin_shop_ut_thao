// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/auth_service.dart';
import 'auth/login_screen.dart';
import 'auth/profile_screen.dart';
import 'desktop/screens/dashboard_screen.dart';
import 'desktop/screens/products_screen.dart';
import 'desktop/screens/product_form_screen.dart';
import 'desktop/screens/orders_screen.dart';
import 'desktop/screens/debts_screen.dart';
import 'desktop/screens/report_screen.dart';
import 'desktop/widgets/side_menu.dart';
import 'mobile/screens/qr_scan_screen.dart';
import 'mobile/screens/order_list_screen.dart';
import 'mobile/screens/debt_list_screen.dart';
import 'mobile/widgets/mobile_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await authService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) => MaterialApp.router(
        title: 'Quản Lý Đơn Hàng',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F7FFA)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF4F6FA),
        ),
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    if (authService.loading) return null;
    final loggedIn   = authService.isLoggedIn;
    final isLogin    = state.uri.path == '/login';
    if (!loggedIn && !isLogin) return '/login';
    if ( loggedIn &&  isLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/login',
      builder: (_, __) => LoginScreen(onLoginSuccess: () {})),

    // Slide 5: Wrap toàn bộ app với InactivityDetector
    ShellRoute(
      builder: (context, state, child) {
        if (authService.loading) return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
        return InactivityDetector(
          child: MediaQuery.of(context).size.width >= 768
              ? DesktopShell(child: child)
              : MobileShell(child: child),
        );
      },
      routes: [
        GoRoute(path: '/',           builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/products',   builder: (_, __) => const ProductsScreen()),
        GoRoute(path: '/orders',     builder: (_, __) => const OrdersScreen()),
        GoRoute(path: '/debts',      builder: (_, __) => const DebtsScreen()),
        GoRoute(path: '/report',     builder: (_, __) => const ReportScreen()),
        GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/scan',       builder: (_, __) => const QrScanScreen()),
        GoRoute(path: '/order-list', builder: (_, __) => const OrderListScreen()),
        GoRoute(path: '/debt-list',  builder: (_, __) => const DebtListScreen()),
      ],
    ),
  ],
);

/// Slide 5: Wrapper phát hiện user tương tác → reset inactivity timer
/// Khi không tương tác > 8h → AuthService tự logout
class InactivityDetector extends StatelessWidget {
  final Widget child;
  const InactivityDetector({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Mọi gesture đều refresh last-active timestamp
    return Listener(
      onPointerDown: (_) => authService.refreshActivity(),
      onPointerMove: (_) => authService.refreshActivity(),
      child: child,
    );
  }
}