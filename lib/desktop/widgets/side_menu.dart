import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';
import '../../auth/profile_screen.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1117),
        border: Border(right: BorderSide(color: Color(0xFF1E2130), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF4F7FFA).withOpacity(0.4),
                    blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Center(child: Text('🛒', style: TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SHOP', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 15, letterSpacing: 1.5)),
                  Text('MANAGEMENT', style: TextStyle(
                    color: Color(0xFF4F7FFA), fontWeight: FontWeight.w600,
                    fontSize: 9, letterSpacing: 2)),
                ],
              ),
            ]),
          ),

          _SectionLabel('MENU CHÍNH'),
          _NavItem(emoji: '📊', label: 'Tổng quan',        route: '/',         location: location),
          _NavItem(emoji: '📦', label: 'Sản phẩm',         route: '/products', location: location),
          _NavItem(emoji: '🧾', label: 'Đơn hàng',         route: '/orders',   location: location),
          _NavItem(emoji: '💰', label: 'Sổ nợ',            route: '/debts',    location: location),
          const SizedBox(height: 8),
          _SectionLabel('PHÂN TÍCH'),
          _NavItem(emoji: '📈', label: 'Báo cáo doanh thu',route: '/report',   location: location),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // ── FIX SLIDE 3: User card click được → popup Profile/Logout ──
          _UserCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── User Card ở cuối SideMenu – click → popup 2 options ──
class _UserCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Material(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showProfileMenu(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              // Avatar
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F7FFA).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    (user?.fullName ?? user?.username ?? 'A')
                        .substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF4F7FFA),
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.fullName ?? user?.username ?? 'Admin',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                  Text(user?.role == 'admin' ? 'Quản trị viên' : 'Nhân viên',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                ]),
              ),
              // Indicator: 3 chấm dọc
              Icon(Icons.more_vert, color: Colors.grey[500], size: 16),
            ]),
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final offset = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size   = box?.size ?? Size.zero;

    showMenu<String>(
      context: context,
      color: const Color(0xFF1A1D2E),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2D3561))),
      position: RelativeRect.fromLTRB(
        offset.dx + 12,
        offset.dy - 110,
        offset.dx + size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'profile',
          child: Row(children: const [
            Text('👤', style: TextStyle(fontSize: 16)),
            SizedBox(width: 10),
            Text('Xem hồ sơ',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ]),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(children: const [
            Text('🚪', style: TextStyle(fontSize: 16)),
            SizedBox(width: 10),
            Text('Đăng xuất',
                style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ]),
        ),
      ],
    ).then((val) async {
      if (!context.mounted) return;
      if (val == 'profile') {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()));
      } else if (val == 'logout') {
        await _confirmLogout(context);
      }
    });
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

// ── Section label ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
    child: Text(text, style: TextStyle(
      color: Colors.grey[600], fontSize: 10,
      fontWeight: FontWeight.w600, letterSpacing: 1.5)),
  );
}

// ── Nav item ──────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final String emoji, label, route, location;
  const _NavItem({required this.emoji, required this.label,
                  required this.route, required this.location});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;
  bool get _isActive => widget.location == widget.route;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
    child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _isActive
                ? const Color(0xFF4F7FFA).withOpacity(0.15)
                : _hovered ? Colors.white.withOpacity(0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: _isActive
                ? Border.all(color: const Color(0xFF4F7FFA).withOpacity(0.3))
                : null,
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 3, height: 18,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _isActive ? const Color(0xFF4F7FFA) : Colors.transparent,
                borderRadius: BorderRadius.circular(2)),
            ),
            Text(widget.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.label, style: TextStyle(
              color: _isActive ? Colors.white
                  : _hovered ? Colors.grey[300] : Colors.grey[500],
              fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13))),
            if (_isActive)
              Container(width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F7FFA), shape: BoxShape.circle)),
          ]),
        ),
      ),
    ),
  );
}

// ── Desktop Shell ─────────────────────────────────────────
class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6FA),
    body: Row(children: [
      const SideMenu(),
      Expanded(child: child),
    ]),
  );
}