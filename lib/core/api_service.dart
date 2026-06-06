import 'package:dio/dio.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 6),
    receiveTimeout: const Duration(seconds: 6),
    contentType: 'application/json',
    validateStatus: (status) => status != null && status < 500,
  ));

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

  Future<Map<String, dynamic>> getProductById(String id) async {
    final res = await _dio.get('/products/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> getProductQR(String productId) async {
    final res = await _dio.get('/products/$productId/qr');
    return res.data;
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    final res = await _dio.get('/orders');
    return List<Map<String, dynamic>>.from(res.data);
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async {
    final res = await _dio.post('/orders', data: data);
    return res.data;
  }

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

  Future<Map<String, dynamic>> getDashboardStats() async {
    final res = await _dio.get('/dashboard/stats');
    return res.data;
  }
}

final apiService = ApiService();