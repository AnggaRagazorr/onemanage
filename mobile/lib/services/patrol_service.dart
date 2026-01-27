import 'package:dio/dio.dart';
import '../ui/patrol/patrol_store.dart';
import 'api_client.dart';

class PatrolService {
  PatrolService._internal();

  static final PatrolService instance = PatrolService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<PatrolEntry>> fetch({String? date, int? userId}) async {
    final query = <String, dynamic>{};
    if (date != null) {
      query['date'] = date;
    }
    if (userId != null) {
      query['user_id'] = userId;
    }
    final response = await _client.get(
      '/patrols',
      query: query.isEmpty ? null : query,
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((item) => PatrolEntry.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<PatrolConditionReport>> fetchReports({String? date, int? userId}) async {
    final query = <String, dynamic>{};
    if (date != null) {
      query['date'] = date;
    }
    if (userId != null) {
      query['user_id'] = userId;
    }
    final response = await _client.get(
      '/patrol-conditions',
      query: query.isEmpty ? null : query,
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((item) => PatrolConditionReport.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<PatrolConditionReport> createReport(PatrolConditionReport report) async {
    final response = await _client.post('/patrol-conditions', data: report.toJson());
    final body = response.data as Map<String, dynamic>;
    return PatrolConditionReport.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<PatrolEntry> upload({
    required String area,
    required String barcode,
    required List<MultipartFile> photos,
  }) async {
    final form = FormData.fromMap({
      'area': area,
      'barcode': barcode,
      'photos': photos,
    });
    final response = await _client.postMultipart('/patrols', data: form);
    final body = response.data as Map<String, dynamic>;
    return PatrolEntry.fromJson(body['data'] as Map<String, dynamic>);
  }
}
