import '../ui/carpool/carpool_models.dart';
import '../ui/admin/admin_carpool_store.dart';
import 'api_client.dart';

class CarpoolService {
  CarpoolService._internal();

  static final CarpoolService instance = CarpoolService._internal();

  final ApiClient _client = ApiClient.instance;

  Future<List<AdminCar>> fetchVehicles() async {
    final response = await _client.get('/carpool/vehicles');
    final data = response.data as List<dynamic>;
    return data.map((item) => AdminCar.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<AdminDriver>> fetchDrivers() async {
    final response = await _client.get('/carpool/drivers');
    final data = response.data as List<dynamic>;
    return data.map((item) => AdminDriver.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<AdminCar> createVehicle(AdminCar car) async {
    final response = await _client.post('/carpool/vehicles', data: car.toJson());
    final body = response.data as Map<String, dynamic>;
    return AdminCar.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<AdminDriver> createDriver(AdminDriver driver) async {
    final response = await _client.post('/carpool/drivers', data: driver.toJson());
    final body = response.data as Map<String, dynamic>;
    return AdminDriver.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(int id) async {
    await _client.delete('/carpool/vehicles/$id');
  }

  Future<void> deleteDriver(int id) async {
    await _client.delete('/carpool/drivers/$id');
  }

  Future<List<CarpoolHistoryItem>> fetchLogs({String? date, String? status}) async {
    final response = await _client.get('/carpool/logs', query: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
    });
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data.map((item) => CarpoolHistoryItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<CarpoolHistoryItem> createLog(CarpoolHistoryItem item) async {
    final response = await _client.post('/carpool/logs', data: item.toJson());
    final body = response.data as Map<String, dynamic>;
    return CarpoolHistoryItem.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<CarpoolHistoryItem> updateLog(int id, Map<String, dynamic> payload) async {
    final response = await _client.post('/carpool/logs/$id', data: payload);
    final body = response.data as Map<String, dynamic>;
    return CarpoolHistoryItem.fromJson(body['data'] as Map<String, dynamic>);
  }
}
