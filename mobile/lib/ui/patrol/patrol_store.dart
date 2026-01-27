import 'package:flutter/material.dart';
import '../../services/patrol_service.dart';

class PatrolEntry {
  PatrolEntry({
    this.id,
    required this.area,
    required this.barcode,
    required this.photoCount,
    required this.timestamp,
    this.userId,
    this.officer,
  });

  final int? id;
  final String area;
  final String barcode;
  final int photoCount;
  final DateTime timestamp;
  final int? userId;
  final String? officer;

  factory PatrolEntry.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return PatrolEntry(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      area: json['area'] as String,
      barcode: json['barcode'] as String,
      photoCount: json['photo_count'] as int? ?? 0,
      timestamp: DateTime.parse(json['captured_at'] as String),
      officer: (user?['name'] as String?) ?? json['officer'] as String?,
    );
  }
}

class PatrolConditionReport {
  PatrolConditionReport({
    this.id,
    this.userId,
    required this.date,
    required this.time,
    required this.situasi,
    required this.aght,
    required this.cuaca,
    required this.pdam,
    required this.wfo,
    required this.tambahan,
    required this.officer,
  });

  final int? id;
  final int? userId;
  final DateTime date;
  final String time;
  final String situasi;
  final String aght;
  final String cuaca;
  final String pdam;
  final int wfo;
  final int tambahan;
  final String officer;

  factory PatrolConditionReport.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final dateValue = json['date'] as String? ?? json['created_at'] as String? ?? '';
    return PatrolConditionReport(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      date: DateTime.parse(dateValue),
      time: (json['time'] as String?) ?? '-',
      situasi: (json['situasi'] as String?) ?? '-',
      aght: (json['aght'] as String?) ?? '-',
      cuaca: (json['cuaca'] as String?) ?? '-',
      pdam: (json['pdam'] as String?) ?? '-',
      wfo: json['wfo'] as int? ?? 0,
      tambahan: json['tambahan'] as int? ?? 0,
      officer: (user?['name'] as String?) ?? json['officer'] as String? ?? '-',
    );
  }

  Map<String, dynamic> toJson() {
    final dateValue = DateTime(date.year, date.month, date.day).toIso8601String().split('T').first;
    return {
      'date': dateValue,
      'time': time,
      'situasi': situasi,
      'aght': aght,
      'cuaca': cuaca,
      'pdam': pdam,
      'wfo': wfo,
      'tambahan': tambahan,
    };
  }
}

class PatrolStore {
  PatrolStore(List<PatrolEntry> initial)
      : entries = ValueNotifier<List<PatrolEntry>>(List<PatrolEntry>.from(initial)),
        conditionReports = ValueNotifier<List<PatrolConditionReport>>([]);

  final ValueNotifier<List<PatrolEntry>> entries;
  final ValueNotifier<List<PatrolConditionReport>> conditionReports;
  final PatrolService _service = PatrolService.instance;

  Future<void> load({String? date, int? userId}) async {
    final results = await Future.wait([
      _service.fetch(date: date, userId: userId),
      _service.fetchReports(date: date, userId: userId),
    ]);
    entries.value = results[0] as List<PatrolEntry>;
    conditionReports.value = results[1] as List<PatrolConditionReport>;
  }

  void add(PatrolEntry entry) {
    entries.value = [entry, ...entries.value];
  }

  void addConditionReport(PatrolConditionReport report) {
    conditionReports.value = [report, ...conditionReports.value];
  }

  Future<PatrolConditionReport> createConditionReport(PatrolConditionReport report) async {
    final saved = await _service.createReport(report);
    conditionReports.value = [saved, ...conditionReports.value];
    return saved;
  }
}

final patrolStore = PatrolStore([]);
