import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'models/user.dart';

class AuthService extends ChangeNotifier {
  static const _userKey        = 'auth_user';
  static const _lastActiveKey  = 'last_active_ms';
  static const _sessionTimeout = Duration(hours: 8); // Slide 5: auto logout 8h
  static const String baseUrl  = 'http://localhost:3000/api';

  User?   _currentUser;
  bool    _loading = true;
  String? _error;

  // ── Inactivity timer ──────────────────────────────────
  Timer? _inactivityTimer;

  User?   get currentUser => _currentUser;
  bool    get isLoggedIn  => _currentUser != null;
  bool    get loading     => _loading;
  String? get error       => _error;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    contentType: 'application/json',
  ));

  // ─── Khởi tạo: đọc session đã lưu ───────────────────
  Future<void> init() async {
    try {
      final prefs   = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_userKey);
      if (userStr != null) {
        final json = jsonDecode(userStr) as Map<String, dynamic>;
        // Slide 5: Kiểm tra thời gian inactivity
        final lastActiveMs = prefs.getInt(_lastActiveKey) ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastActiveMs;
        if (elapsed > _sessionTimeout.inMilliseconds) {
          // Quá 8 giờ → xoá session
          await _clearSession(prefs);
        } else {
          _currentUser = User.fromJson(json, json['token'] ?? '');
          _startInactivityTimer();
        }
      }
    } catch (_) {
      _currentUser = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ─── Đăng nhập ───────────────────────────────────────
  Future<bool> login(String username, String password) async {
    _error = null;
    notifyListeners();
    try {
      final res = await _dio.post('/auth/login',
          data: {'username': username.trim(), 'password': password});
      if (res.statusCode == 200) {
        final token    = res.data['token'] as String;
        final userData = res.data['user'] as Map<String, dynamic>;
        _currentUser   = User.fromJson(userData, token);
        await _saveSession();
        _startInactivityTimer();
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
        // Offline: tài khoản mặc định để test
        if (username == 'admin' && password == 'admin123') {
          _currentUser = const User(
            id: 'offline', username: 'admin', role: 'admin',
            fullName: 'Quản Trị Viên', token: 'offline_token');
          await _saveSession();
          _startInactivityTimer();
          notifyListeners();
          return true;
        }
        _error = 'Không kết nối được server.\nThử: admin / admin123';
      } else if (e.response?.statusCode == 401) {
        _error = 'Sai tên đăng nhập hoặc mật khẩu';
      } else {
        _error = 'Đăng nhập thất bại. Vui lòng thử lại.';
      }
      notifyListeners();
      return false;
    }
  }

  // ─── Đổi thông tin profile ────────────────────────────
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? newUsername,
    String? currentPassword,
    String? newPassword,
  }) async {
    try {
      final res = await _dio.put(
        '/auth/profile',
        data: {
          if (fullName     != null) 'full_name':       fullName,
          if (newUsername  != null) 'new_username':    newUsername,
          if (currentPassword != null) 'current_password': currentPassword,
          if (newPassword  != null) 'new_password':    newPassword,
        },
        options: Options(headers: {'Authorization': authHeader}),
      );
      if (res.statusCode == 200) {
        // Cập nhật local user
        final updated = res.data['user'] as Map<String, dynamic>;
        _currentUser  = User.fromJson(updated, _currentUser!.token);
        await _saveSession();
        notifyListeners();
        return {'success': true, 'message': 'Cập nhật thành công'};
      }
      return {'success': false, 'message': res.data['message'] ?? 'Lỗi'};
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Dữ liệu không hợp lệ'};
      }
      return {'success': false, 'message': 'Không kết nối được server'};
    }
  }

  // ─── Đăng xuất ───────────────────────────────────────
  Future<void> logout() async {
    _inactivityTimer?.cancel();
    _currentUser = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await _clearSession(prefs);
    notifyListeners();
  }

  // ─── Cập nhật last active (gọi khi user tương tác) ───
  Future<void> refreshActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _lastActiveKey, DateTime.now().millisecondsSinceEpoch);
    // Reset timer
    _startInactivityTimer();
  }

  // ─── Timer tự động logout sau 8h không hoạt động ─────
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_sessionTimeout, () async {
      if (_currentUser != null) {
        await logout();
      }
    });
  }

  // ─── Helpers ─────────────────────────────────────────
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    await prefs.setInt(
        _lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_userKey);
    await prefs.remove(_lastActiveKey);
    _currentUser = null;
  }

  String get authHeader => 'Bearer ${_currentUser?.token ?? ""}';
}

final authService = AuthService();