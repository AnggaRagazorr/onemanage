import 'package:flutter/material.dart';

import '../../services/dokumen_service.dart';

class DokumenEntry {
  DokumenEntry({
    this.id,
    required this.date,
    required this.day,
    required this.time,
    required this.origin,
    required this.name,
    required this.qty,
    required this.owner,
    required this.receiver,
  });

  final int? id;
  final DateTime date;
  final String day;
  final String time;
  final String origin;
  final String name;
  final String qty;
  final String owner;
  final String receiver;

  factory DokumenEntry.fromJson(Map<String, dynamic> json) {
    return DokumenEntry(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      day: json['day'] as String,
      time: json['time'] as String,
      origin: json['origin'] as String,
      name: json['item_name'] as String,
      qty: json['qty'] as String,
      owner: json['owner'] as String,
      receiver: json['receiver'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T').first,
      'day': day,
      'time': time,
      'origin': origin,
      'item_name': name,
      'qty': qty,
      'owner': owner,
      'receiver': receiver,
    };
  }
}

class DokumenStore {
  DokumenStore(List<DokumenEntry> initial)
      : entries = ValueNotifier<List<DokumenEntry>>(List<DokumenEntry>.from(initial));

  final ValueNotifier<List<DokumenEntry>> entries;
  final ValueNotifier<DateTime?> filterDate = ValueNotifier<DateTime?>(null);
  final DokumenService _service = DokumenService.instance;

  Future<void> load({String? date}) async {
    if (date != null) {
      // If date string is provided (from filter), parse and set filterDate
      // Or if the logic is reversed: load() is called WITH a formatted string.
      // Let's store the DateTime if possible.
      // But wait, the existing load() took a String? date.
      // The UI converts DateTime to String before calling load.
      // We should probably allow setting the filterDate separately or handle it here.
    }
    // Actually, to keep it simple and consistent:
    // The UI should set store.filterDate.value, then call store.load().
    // OR store.load() takes the date and sets it.
    
    // Let's make load() use the stored date if no argument is passed, 
    // BUT update the stored date if an argument IS passed.
    
    // However, the argument is String? date. 
    // I will change the logic:
    // If date is passed, we assume it's the filter.
    // But the current UI calls load(date: _formatDate(selectedDate)).
    
    // Better approach:
    // Update the UI to pass the DateTime to a new method setFilter or just manage it here.
    // Let's just add the ValueNotifier for now and let the UI drive it, 
    // ensuring we don't regress.
    
    final data = await _service.fetch(date: date);
    entries.value = data;
  }

  void setFilter(DateTime? date) {
    filterDate.value = date;
    // We also need to format it to string for the service
    // But the service takes a string.
    // Let's helper method in UI handle string formatting or do it here.
    // Ideally the store shouldn't worry about UI string formatting, but it needs to call the service.
    // The service expects YYYY-MM-DD.
    
    String? dateStr;
    if (date != null) {
       final day = date.day.toString().padLeft(2, '0');
       final month = date.month.toString().padLeft(2, '0');
       dateStr = "${date.year}-$month-$day";
    }
    load(date: dateStr);
  }

  Future<void> add(DokumenEntry entry) async {
    final saved = await _service.create(entry);
    entries.value = [saved, ...entries.value];
  }
}

final dokumenStore = DokumenStore([]);
