import 'package:flutter/material.dart';
import '../core/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  bool _obscure   = true;
  bool _loading   = false;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await authService.login(_userCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isDesktop ? _buildDesktop() : _buildMobile(),
      ),
    );
  }

  // ── Desktop: 2 cột ──────────────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        // Banner trái
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1D2E), Color(0xFF2D3561), Color(0xFF4F7FFA)],
              ),
            ),
            child: Stack(children: [
              Positioned(top: -60, left: -60,
                child: _circle(300, const Color(0xFF4F7FFA), 0.15)),
              Positioned(bottom: -80, right: -80,
                child: _circle(400, const Color(0xFF845EF7), 0.12)),
              Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: const Center(child: Text('🛒', style: TextStyle(fontSize: 32))),
                    ),
                    const SizedBox(height: 32),
                    const Text('SHOP\nMANAGEMENT',
                      style: TextStyle(color: Colors.white, fontSize: 40,
                          fontWeight: FontWeight.w900, height: 1.1, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    Text('Hệ thống quản lý đơn hàng\nthông minh & hiện đại',
                      style: TextStyle(color: Colors.white.withOpacity(0.7),
                          fontSize: 16, height: 1.6)),
                    const SizedBox(height: 48),
                    ...['📊 Dashboard tổng quan real-time',
                        '📦 Quản lý sản phẩm & mã QR',
                        '🧾 Tạo đơn hàng qua quét QR',
                        '📈 Báo cáo doanh thu chi tiết'].map((e) {
                      final parts = e.split(' ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(child: Text(parts[0],
                                style: const TextStyle(fontSize: 18))),
                          ),
                          const SizedBox(width: 12),
                          Text(parts.sublist(1).join(' '),
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85), fontSize: 14)),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
            ]),
          ),
        ),

        // Form phải
        Expanded(
          flex: 4,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chào mừng trở lại 👋',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D2E))),
                    const SizedBox(height: 8),
                    Text('Trang dành cho quản trị viên',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                    const SizedBox(height: 36),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Mobile: 1 cột cuộn ──────────────────────────────────
  Widget _buildMobile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 36),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFF1A1D2E), Color(0xFF4F7FFA)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(child: Text('🛒', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 20),
                const Text('SHOP MANAGEMENT',
                  style: TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('Đăng nhập để tiếp tục',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: _buildForm()),
        ],
      ),
    );
  }

  // ── Form dùng chung ─────────────────────────────────────
  Widget _buildForm() {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (authService.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('❌', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(authService.error!,
                    style: const TextStyle(color: Color(0xFFD63031), fontSize: 13))),
                ]),
              ),

            // Username
            const _FieldLabel('Tên đăng nhập'),
            const SizedBox(height: 8),
            // FIX 1: Dùng TextField thông thường với leading widget
            // thay vì prefixIcon để tránh lệch vị trí
            TextFormField(
              controller: _userCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Nhập tên đăng nhập',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                // FIX: dùng prefixIcon với SizedBox cố định thay vì Padding
                prefixIcon: SizedBox(
                  width: 48,
                  child: Center(
                    child: Text('👤',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _borderFocused(),
                errorBorder: _borderError(),
                focusedErrorBorder: _borderError(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
            ),
            const SizedBox(height: 20),

            // Password
            const _FieldLabel('Mật khẩu'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                hintText: 'Nhập mật khẩu',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                // FIX: prefixIcon cố định width
                prefixIcon: SizedBox(
                  width: 48,
                  child: Center(
                    child: Text('🔒',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                suffixIcon: IconButton(
                  icon: Text(_obscure ? '👁️' : '🙈',
                      style: const TextStyle(fontSize: 18)),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: _border(),
                enabledBorder: _border(),
                focusedBorder: _borderFocused(),
                errorBorder: _borderError(),
                focusedErrorBorder: _borderError(),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
            ),
            const SizedBox(height: 28),

            // Login button
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F7FFA),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF4F7FFA).withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Đăng Nhập',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),

            // Hint
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tài khoản mặc định (khi chưa có server):\nadmin / admin123',
                    style: TextStyle(color: Colors.blue[700], fontSize: 12),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE0E4F0)),
  );
  OutlineInputBorder _borderFocused() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF4F7FFA), width: 2),
  );
  OutlineInputBorder _borderError() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
  );

  Widget _circle(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
        color: color.withOpacity(opacity), shape: BoxShape.circle),
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
    style: const TextStyle(fontWeight: FontWeight.w600,
        fontSize: 13, color: Color(0xFF1A1D2E)));
}