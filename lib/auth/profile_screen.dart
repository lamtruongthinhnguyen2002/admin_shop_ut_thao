import 'package:flutter/material.dart';
import '../core/auth_service.dart';

/// Page Profile – dùng chung Desktop & Mobile
/// Cho phép đổi: username, tên hiển thị, mật khẩu
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _curPassCtrl  = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _conPassCtrl  = TextEditingController();

  bool _obscureCur  = true;
  bool _obscureNew  = true;
  bool _obscureCon  = true;
  bool _saving      = false;
  bool _changePass  = false; // toggle đổi mật khẩu

  @override
  void initState() {
    super.initState();
    final u = authService.currentUser;
    _fullNameCtrl.text = u?.fullName ?? '';
    _usernameCtrl.text = u?.username ?? '';
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _usernameCtrl.dispose();
    _curPassCtrl.dispose();
    _newPassCtrl.dispose();
    _conPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_changePass && _newPassCtrl.text != _conPassCtrl.text) {
      _showSnack('Mật khẩu xác nhận không khớp', isError: true);
      return;
    }

    setState(() => _saving = true);

    final result = await authService.updateProfile(
      fullName:        _fullNameCtrl.text.trim(),
      newUsername:     _usernameCtrl.text.trim(),
      currentPassword: _changePass ? _curPassCtrl.text : null,
      newPassword:     _changePass ? _newPassCtrl.text : null,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      _showSnack('✅ ${result['message']}');
      if (_changePass) {
        // Xoá fields mật khẩu sau khi đổi thành công
        _curPassCtrl.clear();
        _newPassCtrl.clear();
        _conPassCtrl.clear();
        setState(() => _changePass = false);
      }
    } else {
      _showSnack(result['message'] ?? 'Lỗi', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final user      = authService.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Hồ Sơ Cá Nhân',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E))),
        leading: BackButton(color: const Color(0xFF1A1D2E)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 640 : double.infinity),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Avatar + tên ──────────────────────────
                  Center(
                    child: Column(children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F7FFA), Color(0xFF845EF7)]),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF4F7FFA).withOpacity(0.3),
                            blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: Center(
                          child: Text(
                            (user?.fullName ?? user?.username ?? 'A')
                                .substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white,
                                fontSize: 36, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(user?.fullName ?? user?.username ?? '',
                        style: const TextStyle(fontSize: 20,
                            fontWeight: FontWeight.bold, color: Color(0xFF1A1D2E))),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F7FFA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.role == 'admin' ? '👑 Quản trị viên' : '👤 Nhân viên',
                          style: const TextStyle(color: Color(0xFF4F7FFA),
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 32),

                  // ── Thông tin cá nhân ─────────────────────
                  _sectionCard(title: '👤 Thông Tin Cá Nhân', children: [
                    _label('Tên hiển thị'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _fullNameCtrl,
                      decoration: _deco(hint: 'Nhập tên hiển thị'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 16),
                    _label('Tên đăng nhập (username)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: _deco(hint: 'Nhập username mới'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vui lòng nhập username';
                        }
                        if (v.trim().length < 3) {
                          return 'Username tối thiểu 3 ký tự';
                        }
                        if (v.contains(' ')) {
                          return 'Username không được có khoảng trắng';
                        }
                        return null;
                      },
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Đổi mật khẩu (toggle) ─────────────────
                  _sectionCard(
                    title: '🔒 Đổi Mật Khẩu',
                    trailing: Switch(
                      value: _changePass,
                      onChanged: (v) => setState(() {
                        _changePass = v;
                        if (!v) {
                          _curPassCtrl.clear();
                          _newPassCtrl.clear();
                          _conPassCtrl.clear();
                        }
                      }),
                      activeColor: const Color(0xFF4F7FFA),
                    ),
                    children: [
                      if (!_changePass)
                        Text('Bật toggle để thay đổi mật khẩu',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13))
                      else ...[
                        _label('Mật khẩu hiện tại'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _curPassCtrl,
                          obscureText: _obscureCur,
                          decoration: _decoPass(
                            hint: 'Nhập mật khẩu hiện tại',
                            obscure: _obscureCur,
                            toggle: () => setState(() => _obscureCur = !_obscureCur),
                          ),
                          validator: _changePass
                              ? (v) => (v == null || v.isEmpty)
                                  ? 'Nhập mật khẩu hiện tại' : null
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _label('Mật khẩu mới'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _newPassCtrl,
                          obscureText: _obscureNew,
                          decoration: _decoPass(
                            hint: 'Tối thiểu 6 ký tự',
                            obscure: _obscureNew,
                            toggle: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          validator: _changePass
                              ? (v) {
                                  if (v == null || v.isEmpty) return 'Nhập mật khẩu mới';
                                  if (v.length < 6) return 'Tối thiểu 6 ký tự';
                                  return null;
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        _label('Xác nhận mật khẩu mới'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _conPassCtrl,
                          obscureText: _obscureCon,
                          decoration: _decoPass(
                            hint: 'Nhập lại mật khẩu mới',
                            obscure: _obscureCon,
                            toggle: () => setState(() => _obscureCon = !_obscureCon),
                          ),
                          validator: _changePass
                              ? (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Xác nhận mật khẩu';
                                  }
                                  if (v != _newPassCtrl.text) {
                                    return 'Mật khẩu không khớp';
                                  }
                                  return null;
                                }
                              : null,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Nút Lưu ─────────────────────────────
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F7FFA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('Lưu thay đổi',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nút đăng xuất
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () async {
                        final confirm = await _confirmDialog(
                          context, 'Đăng xuất',
                          'Bạn có chắc muốn đăng xuất không?');
                        if (confirm == true) await authService.logout();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('🚪  Đăng xuất',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper widgets ──────────────────────────────────────
  Widget _sectionCard({
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15,
                color: Color(0xFF1A1D2E))),
            if (trailing != null) trailing,
          ]),
          const SizedBox(height: 16),
          ...children,
        ]),
      );

  Widget _label(String text) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.w600,
        fontSize: 13, color: Color(0xFF1A1D2E)));

  InputDecoration _deco({required String hint}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF8F9FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E4F0))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF4F7FFA), width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );

  InputDecoration _decoPass({
    required String hint, required bool obscure, required VoidCallback toggle}) =>
      _deco(hint: hint).copyWith(
        suffixIcon: IconButton(
          icon: Text(obscure ? '👁️' : '🙈',
              style: const TextStyle(fontSize: 18)),
          onPressed: toggle,
        ),
      );

  Future<bool?> _confirmDialog(
      BuildContext ctx, String title, String content) =>
      showDialog<bool>(
        context: ctx,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Đồng ý')),
          ],
        ),
      );
}