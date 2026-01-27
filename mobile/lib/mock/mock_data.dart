import '../models/activity.dart';
import '../models/patrol_record.dart';

class MockData {
  static Map<String, dynamic> dashboard() => {
        "patrolTarget": 3,
        "patrolDone": 0,
        "rekapToday": 0,
        "mobilTersedia": 0,
        "dokumenToday": 0,
      };

  static List<Activity> activities() => [
        Activity(title: "Belum ada aktivitas.", subtitle: "Mulai patroli untuk mencatat log."),
      ];

  static List<PatrolRecord> history() => [
        // dummy kosong dulu, nanti kamu bisa isi
      ];
}
