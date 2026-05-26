import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Đổi khi deploy
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    contentType: 'application/json',
  ));

  // Biến lưu trữ Token trong bộ nhớ tạm (Runtime Session)
  String? _token;
  String? get token => _token;

  ApiService() {
    // Tự động đính kèm token vào Header của mọi request tiếp theo thông qua Interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ─── AUTHENTICATION (MỚI BỔ SUNG) ────────────────────────
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      if (res.data['success'] == true) {
        _token = res.data['token']; // Lưu token lại để dùng cho các request sau
      }
      return res.data;
    } on DioException catch (e) {
      // Trả về map lỗi nếu backend phản hồi mã 401 hoặc lỗi kết nối
      return e.response?.data ?? {'success': false, 'message': 'Không thể kết nối đến máy chủ'};
    }
  }

  void logout() {
    _token = null; // Xóa token khi đăng xuất hoặc khi hết thời gian tương tác
  }

  // ─── PRODUCTS ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getProducts() async {
    final res = await _dio.get('/products');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/products/$id', data: data);
    return res.data;
  }

  Future<String> getProductQR(String productId) async {
    final res = await _dio.get('/products/$productId/qr');
    return res.data['qr_url']; // URL ảnh QR
  }

  // ─── ORDERS ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await _dio.get('/orders');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final res = await _dio.post('/orders', data: data);
    return res.data;
  }

  // ─── DEBTS ──────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getDebts() async {
    final res = await _dio.get('/debts');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createDebt(Map<String, dynamic> data) async {
    final res = await _dio.post('/debts', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> updateDebt(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('/debts/$id', data: data);
    return res.data;
  }

  // ─── DASHBOARD ──────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard/stats');
    return res.data;
  }
}

final apiService = ApiService();