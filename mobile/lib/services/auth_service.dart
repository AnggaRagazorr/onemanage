import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  AuthService._internal();

  static final AuthService instance = AuthService._internal();

  final ApiClient _client = ApiClient.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await _client.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
        'device_name': 'mobile',
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    await _client.setToken(token);
    
    final user = data['user'] as Map<String, dynamic>? ?? {};
    await _storage.write(key: 'user_role', value: (user['role'] ?? '') as String);
    await _storage.write(key: 'user_name', value: (user['name'] ?? 'User') as String);
    await _storage.write(key: 'user_email', value: (user['email'] ?? '') as String);
    
    return data;
  }

  Future<String?> getRole() => _storage.read(key: 'user_role');
  Future<String?> getName() => _storage.read(key: 'user_name');
  Future<String?> getEmail() => _storage.read(key: 'user_email');

  Future<void> logout() async {
    await _client.post('/auth/logout');
    await _client.clearToken();
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
  }
}
