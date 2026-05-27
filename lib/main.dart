import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/auth_service.dart';
import 'auth/login_screen.dart';
import 'desktop/screens/dashboard_screen.dart';
import 'desktop/screens/products_screen.dart';
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
  await authService.init(); // Khôi phục session đã lưu
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        return MaterialApp.router(
          title: 'Quản Lý Đơn Hàng',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4F7FFA)),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          ),
          routerConfig: _buildRouter(),
        );
      },
    );
  }

  GoRouter _buildRouter() => GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // ── Auth guard: chưa đăng nhập → login ──────────────
      if (authService.loading) return null; // đang init
      final isLoggedIn  = authService.isLoggedIn;
      final isLoginPage = state.uri.path == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn  &&  isLoginPage) return '/';
      return null;
    },
    routes: [
      // ── Login (không có Shell) ─────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, __) => LoginScreen(
          onLoginSuccess: () {},  // router redirect xử lý
        ),
      ),

      // ── App shell (có menu) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          if (authService.loading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final isDesktop = MediaQuery.of(context).size.width >= 768;
          return isDesktop
              ? DesktopShell(child: child)
              : MobileShell(child: child);
        },
        routes: [
          GoRoute(path: '/',            builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/products',    builder: (_, __) => const ProductsScreen()),
          GoRoute(path: '/orders',      builder: (_, __) => const OrdersScreen()),
          GoRoute(path: '/debts',       builder: (_, __) => const DebtsScreen()),
          GoRoute(path: '/report',      builder: (_, __) => const ReportScreen()),
          GoRoute(path: '/scan',        builder: (_, __) => const QrScanScreen()),
          GoRoute(path: '/order-list',  builder: (_, __) => const OrderListScreen()),
          GoRoute(path: '/debt-list',   builder: (_, __) => const DebtListScreen()),
        ],
      ),
    ],
  );
}