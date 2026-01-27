import '../ui/admin/admin_users_store.dart';
import 'api_client.dart';

class AdminUserService {
  AdminUserService._internal();

  static final AdminUserService instance = AdminUserService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<AdminUser>> fetchUsers() async {
    final response = await _client.get('/admin/users');
    final data = response.data as List<dynamic>;
    return data.map((item) => AdminUser.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AdminUser> createUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.post(
      '/admin/users',
      data: {
        'name': name,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return AdminUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AdminUser> updateUser({
    required int id,
    required String name,
    required String username,
    required String email,
    String? password,
    required String role,
  }) async {
    final data = {
      'name': name,
      'username': username,
      'email': email,
      'role': role,
    };
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    final response = await _client.post('/admin/users/$id', data: data);
    final body = response.data as Map<String, dynamic>;
    return AdminUser.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(int id) async {
    await _client.post('/admin/users/$id/delete');
  }
}
