import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';

class MobileShell extends StatelessWidget {
  final Widget child;
  const MobileShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    if (location == '/scan')        selectedIndex = 1;
    if (location == '/order-list')  selectedIndex = 2;
    if (location == '/debt-list')   selectedIndex = 3;
    if (location == '/report')      selectedIndex = 4;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 16, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _BottomNavBtn(emoji: '📊', label: 'Tổng quan',  index: 0, selected: selectedIndex, onTap: () => context.go('/')),
                _BottomNavBtn(emoji: '📷', label: 'Quét QR',    index: 1, selected: selectedIndex, onTap: () => context.go('/scan')),
                _BottomNavBtn(emoji: '🧾', label: 'Đơn hàng',  index: 2, selected: selectedIndex, onTap: () => context.go('/order-list')),
                _BottomNavBtn(emoji: '💰', label: 'Sổ nợ',     index: 3, selected: selectedIndex, onTap: () => context.go('/debt-list')),
                _BottomNavBtn(emoji: '📈', label: 'Báo cáo',   index: 4, selected: selectedIndex, onTap: () => context.go('/report')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNavBtn extends StatelessWidget {
  final String emoji, label;
  final int index, selected;
  final VoidCallback onTap;

  const _BottomNavBtn({
    required this.emoji, required this.label,
    required this.index, required this.selected, required this.onTap,
  });

  bool get isActive => index == selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF4F7FFA).withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(emoji,
                    style: TextStyle(fontSize: isActive ? 22 : 20)),
              ),
              const SizedBox(height: 2),
              Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? const Color(0xFF4F7FFA) : Colors.grey[500],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mobile Header AppBar với thông tin user ───────────────
class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const MobileAppBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(title,
        style: const TextStyle(
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        ...?actions,
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showLogoutSheet(context),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF4F7FFA).withOpacity(0.15),
              child: Text(
                (user?.fullName ?? user?.username ?? 'A')
                    .substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF4F7FFA), fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  void _showLogoutSheet(BuildContext context) {
    final user = authService.currentUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('👤', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(user?.fullName ?? user?.username ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(user?.role == 'admin' ? 'Quản trị viên' : 'Nhân viên',
              style: TextStyle(color: Colors.grey[500])),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await authService.logout();
                },
                icon: const Text('🚪'),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}