import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: const {
              'Accept': 'application/json',
            },
          ),
        );

  static final ApiClient instance = ApiClient._internal();

  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  Future<String?> _getToken() async {
    return _storage.read(key: 'auth_token');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final token = await _getToken();
    return _dio.get(
      path,
      queryParameters: query,
      options: Options(headers: _authHeader(token)),
    );
  }

  Future<Response> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final token = await _getToken();
    return _dio.post(
      path,
      data: data,
      options: Options(headers: _authHeader(token)),
    );
  }

  Future<Response> delete(String path) async {
    final token = await _getToken();
    return _dio.delete(
      path,
      options: Options(headers: _authHeader(token)),
    );
  }

  Future<Response> postMultipart(
    String path, {
    required FormData data,
  }) async {
    final token = await _getToken();
    return _dio.post(
      path,
      data: data,
      options: Options(
        headers: _authHeader(token),
        contentType: 'multipart/form-data',
      ),
    );
  }

  Map<String, String> _authHeader(String? token) {
    if (token == null || token.isEmpty) {
      return {};
    }
    return {'Authorization': 'Bearer $token'};
  }
}
