import '../ui/admin/security_stats_store.dart';
import 'api_client.dart';

class SecurityStatsService {
  SecurityStatsService._internal();

  static final SecurityStatsService instance = SecurityStatsService._internal();

  final ApiClient _client = ApiClient.instance;

  /// Fetch all security personnel with their statistics
  Future<List<SecurityStats>> fetchAll() async {
    final response = await _client.get('/admin/security-stats');
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((item) => SecurityStats.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Fetch detailed statistics for a specific security
  Future<SecurityStatsDetail> fetchDetail(int userId) async {
    try {
      final response = await _client.get('/admin/security-stats/$userId');
      final body = response.data as Map<String, dynamic>;
      return SecurityStatsDetail.fromJson(body);
    } catch (e) {
      print('Error fetching security stats detail: $e');
      rethrow;
    }
  }
}
