import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';
import '../../auth/profile_screen.dart';

// ── Mobile Shell ──────────────────────────────────────────
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
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              _BottomBtn('📊', 'Tổng quan', 0, selectedIndex, () => context.go('/')),
              _BottomBtn('📷', 'Quét QR',   1, selectedIndex, () => context.go('/scan')),
              _BottomBtn('🧾', 'Đơn hàng', 2, selectedIndex, () => context.go('/order-list')),
              _BottomBtn('💰', 'Sổ nợ',    3, selectedIndex, () => context.go('/debt-list')),
              _BottomBtn('📈', 'Báo cáo',  4, selectedIndex, () => context.go('/report')),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BottomBtn extends StatelessWidget {
  final String emoji, label;
  final int index, selected;
  final VoidCallback onTap;
  const _BottomBtn(this.emoji, this.label, this.index, this.selected, this.onTap);
  bool get isActive => index == selected;

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF4F7FFA).withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(emoji, style: TextStyle(fontSize: isActive ? 22 : 20)),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(
          fontSize: 10,
          color: isActive ? const Color(0xFF4F7FFA) : Colors.grey[500],
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
      ]),
    ),
  );
}

// ── FIX SLIDE 4: Mobile AppBar với icon profile góc phải ──
class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? extraActions;

  const MobileAppBar({super.key, required this.title, this.extraActions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Text(title,
        style: const TextStyle(
            color: Color(0xFF1A1D2E),
            fontWeight: FontWeight.bold, fontSize: 18)),
      actions: [
        ...?extraActions,

        // FIX SLIDE 4: Avatar icon góc phải → click hiện 2 options
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: const Color(0xFF4F7FFA).withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Center(
                child: Text(
                  (user?.fullName ?? user?.username ?? 'A')
                      .substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // FIX SLIDE 4: Bottom sheet có đúng 2 options: Xem hồ sơ + Đăng xuất
  void _showProfileSheet(BuildContext context) {
    final user = authService.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Avatar + tên
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                color: const Color(0xFF4F7FFA).withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(
              (user?.fullName ?? user?.username ?? 'A')
                  .substring(0, 1).toUpperCase(),
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 26))),
          ),
          const SizedBox(height: 12),
          Text(user?.fullName ?? user?.username ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                color: Color(0xFF1A1D2E))),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4F7FFA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user?.role == 'admin' ? '👑 Quản trị viên' : '👤 Nhân viên',
              style: const TextStyle(color: Color(0xFF4F7FFA),
                  fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 28),

          // Option 1: Xem hồ sơ
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              icon: const Text('👤', style: TextStyle(fontSize: 18)),
              label: const Text('Xem hồ sơ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F7FFA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Option 2: Đăng xuất
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmLogout(context);
              },
              icon: const Text('🚪', style: TextStyle(fontSize: 18)),
              label: const Text('Đăng xuất',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok == true) await authService.logout();
  }
}