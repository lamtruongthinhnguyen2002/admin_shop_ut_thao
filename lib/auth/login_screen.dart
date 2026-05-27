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
  bool  _obscure  = true;
  bool  _loading  = false;
  late  AnimationController _animCtrl;
  late  Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
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

    if (ok) {
      widget.onLoginSuccess();
    }
    // Lỗi đã được set trong authService.error → build() tự hiện
  }

  @override
  Widget build(BuildContext context) {
    final size     = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isDesktop
            ? _DesktopLayout(
                formKey:  _formKey,
                userCtrl: _userCtrl,
                passCtrl: _passCtrl,
                obscure:  _obscure,
                loading:  _loading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onLogin: _login,
              )
            : _MobileLayout(
                formKey:  _formKey,
                userCtrl: _userCtrl,
                passCtrl: _passCtrl,
                obscure:  _obscure,
                loading:  _loading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onLogin: _login,
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// DESKTOP LAYOUT – Chia 2 cột: Banner trái | Form phải
// ═══════════════════════════════════════════════════════════
class _DesktopLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onLogin;

  const _DesktopLayout({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.loading,
    required this.onToggleObscure, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Cột trái – Banner gradient ─────────────────────
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF1A1D2E), Color(0xFF2D3561), Color(0xFF4F7FFA)],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(top: -60, left: -60,
                  child: _GlowCircle(size: 300, color: const Color(0xFF4F7FFA).withOpacity(0.15))),
                Positioned(bottom: -80, right: -80,
                  child: _GlowCircle(size: 400, color: const Color(0xFF845EF7).withOpacity(0.12))),
                Positioned(top: 200, right: 40,
                  child: _GlowCircle(size: 120, color: Colors.white.withOpacity(0.05))),

                // Content
                Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Center(
                          child: Text('🛒', style: TextStyle(fontSize: 32)),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('SHOP\nMANAGEMENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 2,
                        )),
                      const SizedBox(height: 16),
                      Text(
                        'Hệ thống quản lý đơn hàng\nthông minh & hiện đại',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16, height: 1.6),
                      ),
                      const SizedBox(height: 48),
                      // Feature list
                      ...[
                        ('📊', 'Dashboard tổng quan real-time'),
                        ('📦', 'Quản lý sản phẩm & mã QR'),
                        ('🧾', 'Tạo đơn hàng qua quét QR'),
                        ('📈', 'Báo cáo doanh thu chi tiết'),
                      ].map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(child: Text(e.$1,
                                style: const TextStyle(fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Text(e.$2,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14)),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Cột phải – Form đăng nhập ──────────────────────
        Expanded(
          flex: 4,
          child: Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(48),
              child: _LoginForm(
                formKey:         formKey,
                userCtrl:        userCtrl,
                passCtrl:        passCtrl,
                obscure:         obscure,
                loading:         loading,
                onToggleObscure: onToggleObscure,
                onLogin:         onLogin,
                isDesktop:       true,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MOBILE LAYOUT – Full screen cuộn được
// ═══════════════════════════════════════════════════════════
class _MobileLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onLogin;

  const _MobileLayout({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.loading,
    required this.onToggleObscure, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Header gradient ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [Color(0xFF1A1D2E), Color(0xFF4F7FFA)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(32),
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
                  child: const Center(child: Text('🛒',
                      style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(height: 20),
                const Text('SHOP ÚT THẢO',
                  style: TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('Đăng nhập để tiếp tục',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),

          // ── Form ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: _LoginForm(
              formKey:         formKey,
              userCtrl:        userCtrl,
              passCtrl:        passCtrl,
              obscure:         obscure,
              loading:         loading,
              onToggleObscure: onToggleObscure,
              onLogin:         onLogin,
              isDesktop:       false,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// FORM ĐĂNG NHẬP – dùng chung cho cả Desktop và Mobile
// ═══════════════════════════════════════════════════════════
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController userCtrl, passCtrl;
  final bool obscure, loading, isDesktop;
  final VoidCallback onToggleObscure, onLogin;

  const _LoginForm({
    required this.formKey, required this.userCtrl, required this.passCtrl,
    required this.obscure, required this.loading,   required this.isDesktop,
    required this.onToggleObscure, required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        return Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isDesktop) ...[
                const Text('Trang dành cho quản trị viên',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
                const SizedBox(height: 8),
                Text('Vui lòng đăng nhập để tiếp tục',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 40),
              ] else ...[
                const Text('Đăng Nhập',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D2E))),
                const SizedBox(height: 24),
              ],

              // ── Error banner ──────────────────────────────
              if (authService.error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❌', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(authService.error!,
                          style: const TextStyle(
                              color: Color(0xFFD63031), fontSize: 13)),
                      ),
                    ],
                  ),
                ),

              // ── Username ──────────────────────────────────
              _Label('Tên đăng nhập'),
              const SizedBox(height: 8),
              TextFormField(
                controller: userCtrl,
                textInputAction: TextInputAction.next,
                decoration: _inputDeco(
                  hint: 'Nhập tên đăng nhập',
                  prefix: const Text('👤', style: TextStyle(fontSize: 18)),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              const SizedBox(height: 20),

              // ── Password ──────────────────────────────────
              _Label('Mật khẩu'),
              const SizedBox(height: 8),
              TextFormField(
                controller: passCtrl,
                obscureText: obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onLogin(),
                decoration: _inputDeco(
                  hint: 'Nhập mật khẩu',
                  prefix: const Text('🔒', style: TextStyle(fontSize: 18)),
                  suffix: IconButton(
                    icon: Text(obscure ? '👁️' : '🙈',
                        style: const TextStyle(fontSize: 18)),
                    onPressed: onToggleObscure,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu' : null,
              ),
              const SizedBox(height: 32),

              // ── Login Button ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F7FFA),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF4F7FFA).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Đăng Nhập',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // ── Hint offline ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tài khoản mặc định (khi chưa có server):\nadmin / admin123',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: prefix != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: prefix)
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E4F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F7FFA), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
      );
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF1A1D2E)),
      );
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}