import 'package:flutter/material.dart';

import '../../services/rekap_service.dart';

class RekapEntry {
  RekapEntry({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.guard,
    required this.shift,
  });

  final int? id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String activity;
  final String guard;
  final String shift;

  factory RekapEntry.fromJson(Map<String, dynamic> json) {
    return RekapEntry(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      activity: json['activity'] as String,
      guard: json['guard'] as String,
      shift: json['shift'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'activity': activity,
      'guard': guard,
      'shift': shift,
    };
  }
}

class RekapStore {
  RekapStore(List<RekapEntry> initial)
      : entries = ValueNotifier<List<RekapEntry>>(List<RekapEntry>.from(initial));

  final ValueNotifier<List<RekapEntry>> entries;
  final ValueNotifier<DateTime?> filterDate = ValueNotifier<DateTime?>(null);
  
  // Pagination State
  final ValueNotifier<bool> isLoadingMore = ValueNotifier<bool>(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier<String?>(null);
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isFetching = false;

  final RekapService _service = RekapService.instance;

  Future<void> load({String? date}) async {
    if (_isFetching) return;
    _isFetching = true;
    errorMessage.value = null; // Clear previous error
    
    try {
      _currentPage = 1;
      final result = await _service.fetch(date: date, page: 1);
      entries.value = result['data'] as List<RekapEntry>;
      _lastPage = result['last_page'] as int;
      _currentPage = result['current_page'] as int;
    } catch (e) {
      errorMessage.value = "Gagal memuat data. Periksa koneksi internet.";
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || _currentPage >= _lastPage) return;
    
    _isFetching = true;
    isLoadingMore.value = true;
    errorMessage.value = null;
    
    try {
      final date = filterDate.value;
      String? dateStr;
      if (date != null) {
         final day = date.day.toString().padLeft(2, '0');
         final month = date.month.toString().padLeft(2, '0');
         dateStr = "${date.year}-$month-$day";
      }

      final next = _currentPage + 1;
      final result = await _service.fetch(date: dateStr, page: next);
      
      final newEntries = result['data'] as List<RekapEntry>;
      entries.value = [...entries.value, ...newEntries];
      
      _lastPage = result['last_page'] as int;
      _currentPage = result['current_page'] as int;
    } catch (e) {
      errorMessage.value = "Gagal memuat halaman berikutnya.";
    } finally {
      isLoadingMore.value = false;
      _isFetching = false;
    }
  }

  void setFilter(DateTime? date) {
    if (_isFetching) return; 
    filterDate.value = date;
    String? dateStr;
    if (date != null) {
       final day = date.day.toString().padLeft(2, '0');
       final month = date.month.toString().padLeft(2, '0');
       dateStr = "${date.year}-$month-$day";
    }
    load(date: dateStr);
  }

  Future<void> add(RekapEntry entry) async {
    final saved = await _service.create(entry);
    entries.value = [saved, ...entries.value];
  }
}

final rekapStore = RekapStore([]);
