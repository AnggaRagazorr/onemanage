import '../ui/dokumen/dokumen_store.dart';
import 'api_client.dart';

class DokumenService {
  DokumenService._internal();

  static final DokumenService instance = DokumenService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<DokumenEntry>> fetch({String? date}) async {
    final response = await _client.get(
      '/dokumen',
      query: date == null ? null : {'date': date},
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((item) => DokumenEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<DokumenEntry> create(DokumenEntry entry) async {
    final response = await _client.post('/dokumen', data: entry.toJson());
    final body = response.data as Map<String, dynamic>;
    return DokumenEntry.fromJson(body['data'] as Map<String, dynamic>);
  }
}
