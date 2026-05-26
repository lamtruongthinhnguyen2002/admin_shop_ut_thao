import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final res = await apiService.login(_usernameController.text, _passwordController.text);
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        if (mounted) context.go('/'); // Đăng nhập thành công, chuyển vào trang chủ
      } else {
        _showError(res['message'] ?? 'Đăng nhập thất bại');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Không thể kết nối tới máy chủ');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          // SỬA TẠI ĐÂY: Dùng BoxConstraints để giới hạn chiều rộng tối đa cho Container thay vì gọi trực tiếp
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('ĐĂNG NHẬP HỆ THỐNG', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 24),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Tài khoản', border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu', border: OutlineInputBorder())),
                  const SizedBox(height: 24),
                  _isLoading 
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          onPressed: _handleLogin,
                          child: const Text('Đăng nhập'),
                        ),
                      )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}