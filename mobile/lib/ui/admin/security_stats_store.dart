import 'package:flutter/foundation.dart';
import '../../services/security_stats_service.dart';

/// Summary statistics for a security personnel
class SecurityStats {
  SecurityStats({
    required this.id,
    required this.name,
    required this.username,
    required this.patrolCountToday,
    required this.patrolCountMonth,
    required this.isWorking,
    this.lastActivity,
    required this.score,
    required this.scorePercentage,
  });

  final int id;
  final String name;
  final String username;
  final int patrolCountToday;
  final int patrolCountMonth;
  final bool isWorking;
  final DateTime? lastActivity;
  final int score;
  final int scorePercentage;

  factory SecurityStats.fromJson(Map<String, dynamic> json) {
    return SecurityStats(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      patrolCountToday: json['patrol_count_today'] as int? ?? 0,
      patrolCountMonth: json['patrol_count_month'] as int? ?? 0,
      isWorking: json['is_working'] as bool? ?? false,
      lastActivity: json['last_activity'] != null 
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      score: json['score'] as int? ?? 0,
      scorePercentage: json['score_percentage'] as int? ?? 0,
    );
  }
}

/// Detailed statistics for a security personnel
class SecurityStatsDetail {
  SecurityStatsDetail({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.patrolCountToday,
    required this.patrolCountWeek,
    required this.patrolCountMonth,
    required this.patrolByAreaToday,
    required this.isWorking,
    this.lastActivity,
    required this.shiftsWorkedMonth,
    required this.score,
    required this.scorePercentage,
    required this.scoreBreakdown,
    required this.month,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final int patrolCountToday;
  final int patrolCountWeek;
  final int patrolCountMonth;
  final Map<String, int> patrolByAreaToday;
  final bool isWorking;
  final DateTime? lastActivity;
  final int shiftsWorkedMonth;
  final int score;
  final int scorePercentage;
  final ScoreBreakdown scoreBreakdown;
  final String month;

  factory SecurityStatsDetail.fromJson(Map<String, dynamic> json) {
    final areaMap = <String, int>{};
    // Handle both empty array [] and object {} from Laravel
    final rawAreaData = json['patrol_by_area_today'];
    if (rawAreaData is Map<String, dynamic>) {
      rawAreaData.forEach((key, value) {
        areaMap[key] = (value as num?)?.toInt() ?? 0;
      });
    }
    // If it's an empty array [], areaMap stays empty (which is correct)

    return SecurityStatsDetail(
      id: json['id'] as int,
      name: (json['name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      patrolCountToday: json['patrol_count_today'] as int? ?? 0,
      patrolCountWeek: json['patrol_count_week'] as int? ?? 0,
      patrolCountMonth: json['patrol_count_month'] as int? ?? 0,
      patrolByAreaToday: areaMap,
      isWorking: json['is_working'] as bool? ?? false,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      shiftsWorkedMonth: json['shifts_worked_month'] as int? ?? 0,
      score: json['score'] as int? ?? 0,
      scorePercentage: json['score_percentage'] as int? ?? 0,
      scoreBreakdown: ScoreBreakdown.fromJson(
          json['score_breakdown'] as Map<String, dynamic>? ?? {}),
      month: (json['month'] as String?) ?? '',
    );
  }
}

class ScoreBreakdown {
  ScoreBreakdown({
    required this.patrolPoints,
    required this.bonusPoints,
    required this.shiftsWithBonus,
    required this.daysWorked,
  });

  final int patrolPoints;
  final int bonusPoints;
  final int shiftsWithBonus;
  final int daysWorked;

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      patrolPoints: json['patrol_points'] as int? ?? 0,
      bonusPoints: json['bonus_points'] as int? ?? 0,
      shiftsWithBonus: json['shifts_with_bonus'] as int? ?? 0,
      daysWorked: json['days_worked'] as int? ?? 0,
    );
  }
}

/// Store for managing security statistics state
class SecurityStatsStore {
  SecurityStatsStore()
      : stats = ValueNotifier<List<SecurityStats>>([]),
        isLoading = ValueNotifier<bool>(false);

  final ValueNotifier<List<SecurityStats>> stats;
  final ValueNotifier<bool> isLoading;
  final SecurityStatsService _service = SecurityStatsService.instance;

  Future<void> load() async {
    isLoading.value = true;
    try {
      stats.value = await _service.fetchAll();
    } finally {
      isLoading.value = false;
    }
  }

  Future<SecurityStatsDetail> fetchDetail(int userId) async {
    return await _service.fetchDetail(userId);
  }
}

final securityStatsStore = SecurityStatsStore();
