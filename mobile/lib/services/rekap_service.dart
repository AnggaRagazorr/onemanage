import '../ui/rekap/rekap_store.dart';
import 'api_client.dart';

class RekapService {
  RekapService._internal();

  static final RekapService instance = RekapService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> fetch({String? date, int page = 1}) async {
    final response = await _client.get(
      '/rekaps',
      query: {
        if (date != null) 'date': date,
        'page': page,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = (body['data'] as List<dynamic>)
        .map((item) => RekapEntry.fromJson(item as Map<String, dynamic>))
        .toList();
    
    return {
      'data': data,
      'last_page': body['last_page'] ?? 1,
      'current_page': body['current_page'] ?? 1,
    };
  }

  Future<RekapEntry> create(RekapEntry entry) async {
    final response = await _client.post('/rekaps', data: entry.toJson());
    final body = response.data as Map<String, dynamic>;
    return RekapEntry.fromJson(body['data'] as Map<String, dynamic>);
  }
}
