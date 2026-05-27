import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'models/user.dart';

class AuthService extends ChangeNotifier {
  static const _tokenKey = 'auth_token';
  static const _userKey  = 'auth_user';
  static const String baseUrl = 'http://localhost:3000/api';

  User?  _currentUser;
  bool   _loading = true;     // đang kiểm tra token lưu sẵn
  String? _error;

  User?  get currentUser => _currentUser;
  bool   get isLoggedIn  => _currentUser != null;
  bool   get loading     => _loading;
  String? get error      => _error;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    contentType: 'application/json',
  ));

  // ─── Khởi tạo: đọc token đã lưu ──────────────────────
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        final json = jsonDecode(userStr) as Map<String, dynamic>;
        _currentUser = User.fromJson(json, json['token']);
        // Verify token còn hợp lệ
        await _verifyToken(_currentUser!.token);
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _verifyToken(String token) async {
    try {
      final res = await _dio.get('/auth/me',
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      if (res.statusCode != 200) _currentUser = null;
    } catch (_) {
      // Token hết hạn hoặc server chưa chạy → vẫn cho dùng offline
    }
  }

  // ─── Đăng nhập ────────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _error = null;
    notifyListeners();

    try {
      final res = await _dio.post('/auth/login', data: {
        'username': username.trim(),
        'password': password,
      });

      if (res.statusCode == 200) {
        final token = res.data['token'] as String;
        final userData = res.data['user'] as Map<String, dynamic>;
        _currentUser = User.fromJson(userData, token);
        await _saveToPrefs(_currentUser!);
        notifyListeners();
        return true;
      } else {
        _error = res.data['message'] ?? 'Đăng nhập thất bại';
        notifyListeners();
        return false;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        // Offline mode: dùng tài khoản mặc định để dev/test
        if (username == 'admin' && password == 'admin123') {
          _currentUser = const User(
            id: 'offline',
            username: 'admin',
            role: 'admin',
            fullName: 'Quản Trị Viên',
            token: 'offline_token',
          );
          notifyListeners();
          return true;
        }
        _error = 'Không kết nối được server.\nThử: admin / admin123';
      } else if (e.response?.statusCode == 401) {
        _error = 'Sai tên đăng nhập hoặc mật khẩu';
      } else {
        _error = 'Lỗi: ${e.message}';
      }
      notifyListeners();
      return false;
    }
  }

  // ─── Đăng xuất ────────────────────────────────────────
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    notifyListeners();
  }

  // ─── Lưu vào SharedPreferences ────────────────────────
  Future<void> _saveToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  // ─── Lấy Authorization header ─────────────────────────
  String get authHeader => 'Bearer ${_currentUser?.token ?? ""}';
}

// Singleton
final authService = AuthService();