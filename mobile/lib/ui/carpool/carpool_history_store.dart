import 'package:flutter/material.dart';
import 'carpool_models.dart';
import '../../services/carpool_service.dart';

class CarpoolHistoryStore {
  final ValueNotifier<List<CarpoolHistoryItem>> items;
  final ValueNotifier<DateTime?> filterDate = ValueNotifier<DateTime?>(null);

  CarpoolHistoryStore(List<CarpoolHistoryItem> initialItems)
      : items = ValueNotifier<List<CarpoolHistoryItem>>(List<CarpoolHistoryItem>.from(initialItems));

  final CarpoolService _service = CarpoolService.instance;

  Future<void> load({String? date, String? status}) async {
    items.value = await _service.fetchLogs(date: date, status: status);
  }

  void setFilter(DateTime? date) {
    filterDate.value = date;
    String? dateStr;
    if (date != null) {
       final day = date.day.toString().padLeft(2, '0');
       final month = date.month.toString().padLeft(2, '0');
       dateStr = "${date.year}-$month-$day";
    }
    load(date: dateStr);
  }

  Future<void> addItem(CarpoolHistoryItem item) async {
    final saved = await _service.createLog(item);
    items.value = [saved, ...items.value];
  }

  Future<void> updateItem(CarpoolHistoryItem updated) async {
    if (updated.id == null) {
      return;
    }
    final saved = await _service.updateLog(updated.id!, {
      'end_time': updated.endTime,
      'last_km': updated.lastKm,
      'status': updated.status,
    });
    items.value = items.value
        .map((item) => item.id == saved.id ? saved : item)
        .toList(growable: false);
  }
}

final carpoolHistoryStore = CarpoolHistoryStore(
  [],
);
