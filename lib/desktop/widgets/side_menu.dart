import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_service.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final user     = authService.currentUser;

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
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF4F7FFA).withOpacity(0.4),
                        blurRadius: 8, offset: const Offset(0, 3)),
                  ],
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

          // ── Section: Menu chính ───────────────────────────
          _SectionLabel('MENU CHÍNH'),

          _NavItem(emoji: '📊', label: 'Tổng quan',        route: '/',         location: location),
          _NavItem(emoji: '📦', label: 'Sản phẩm',         route: '/products', location: location),
          _NavItem(emoji: '🧾', label: 'Đơn hàng',         route: '/orders',   location: location),
          _NavItem(emoji: '💰', label: 'Sổ nợ',            route: '/debts',    location: location),

          const SizedBox(height: 8),

          // ── Section: Phân tích ────────────────────────────
          _SectionLabel('PHÂN TÍCH'),

          _NavItem(emoji: '📈', label: 'Báo cáo doanh thu',route: '/report',   location: location),

          const Spacer(),
          const Divider(color: Colors.white12, height: 1),

          // ── User info + Logout ────────────────────────────
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F7FFA).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(child: Text('👤', style: TextStyle(fontSize: 14))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.fullName ?? user?.username ?? 'Admin',
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                    Text(user?.role == 'admin' ? 'Quản trị viên' : 'Nhân viên',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ],
                ),
              ),
              // Logout icon
              GestureDetector(
                onTap: () => _confirmLogout(context),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Center(
                    child: Text('🚪', style: TextStyle(fontSize: 14))),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authService.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đăng xuất')),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
    child: Text(text,
      style: TextStyle(
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
  Widget build(BuildContext context) {
    return Padding(
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
              Expanded(
                child: Text(widget.label,
                  style: TextStyle(
                    color: _isActive ? Colors.white
                        : _hovered ? Colors.grey[300] : Colors.grey[500],
                    fontWeight: _isActive ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13)),
              ),
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
}

// ── Desktop Shell ─────────────────────────────────────────
class DesktopShell extends StatelessWidget {
  final Widget child;
  const DesktopShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Row(children: [
        const SideMenu(),
        Expanded(child: child),
      ]),
    );
  }
}