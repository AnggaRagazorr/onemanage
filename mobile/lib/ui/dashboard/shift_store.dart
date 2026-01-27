import 'package:flutter/foundation.dart';
import '../../services/api_client.dart';

class ShiftInfo {
  ShiftInfo({
    required this.id,
    required this.shiftType,
    required this.clockIn,
  });

  final int id;
  final String shiftType;
  final DateTime clockIn;

  factory ShiftInfo.fromJson(Map<String, dynamic> json) {
    return ShiftInfo(
      id: json['id'] as int,
      shiftType: (json['shift_type'] as String?) ?? '',
      clockIn: DateTime.parse(json['clock_in'] as String),
    );
  }
}

class ShiftStore {
  ShiftStore()
      : isActive = ValueNotifier<bool>(false),
        currentShift = ValueNotifier<ShiftInfo?>(null),
        isLoading = ValueNotifier<bool>(false);

  final ValueNotifier<bool> isActive;
  final ValueNotifier<ShiftInfo?> currentShift;
  final ValueNotifier<bool> isLoading;
  final ApiClient _client = ApiClient.instance;

  Future<void> loadCurrent() async {
    isLoading.value = true;
    try {
      final response = await _client.get('/shifts/current');
      final body = response.data as Map<String, dynamic>;
      isActive.value = body['is_active'] as bool? ?? false;
      if (body['shift'] != null) {
        currentShift.value = ShiftInfo.fromJson(body['shift'] as Map<String, dynamic>);
      } else {
        currentShift.value = null;
      }
    } catch (e) {
      print('Error loading shift: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> clockIn(String shiftType) async {
    isLoading.value = true;
    try {
      final response = await _client.post('/shifts/clock-in', data: {
        'shift_type': shiftType,
      });
      final body = response.data as Map<String, dynamic>;
      if (body['shift'] != null) {
        currentShift.value = ShiftInfo.fromJson(body['shift'] as Map<String, dynamic>);
        isActive.value = true;
      }
      return true;
    } catch (e) {
      print('Error clock in: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> clockOut() async {
    isLoading.value = true;
    try {
      await _client.post('/shifts/clock-out');
      currentShift.value = null;
      isActive.value = false;
      return true;
    } catch (e) {
      print('Error clock out: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

final shiftStore = ShiftStore();
