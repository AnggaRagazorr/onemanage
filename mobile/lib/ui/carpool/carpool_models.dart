class CarpoolHistoryItem {
  const CarpoolHistoryItem({
    this.id,
    required this.vehicleId,
    this.driverId,
    required this.site,
    required this.vehicle,
    required this.time,
    required this.status,
    required this.driver,
    required this.user,
    required this.destination,
    required this.date,
    this.endTime,
    this.lastKm,
  });

  final int? id;
  final int vehicleId;
  final int? driverId;
  final String site;
  final String vehicle;
  final String time;
  final String status;
  final String driver;
  final String user;
  final String destination;
  final DateTime date;
  final String? endTime;
  final String? lastKm;

  factory CarpoolHistoryItem.fromJson(Map<String, dynamic> json) {
    return CarpoolHistoryItem(
      id: json['id'] as int?,
      vehicleId: json['vehicle_id'] as int,
      driverId: json['driver_id'] as int?,
      site: json['destination'] as String? ?? "-",
      vehicle: json['vehicle_display'] as String? ?? "-",
      time: json['start_time'] as String? ?? "-",
      status: json['status'] as String? ?? "-",
      driver: json['driver_display'] as String? ?? "-",
      user: json['user_name'] as String? ?? "-",
      destination: json['destination'] as String? ?? "-",
      date: DateTime.parse(json['date'] as String),
      endTime: json['end_time'] as String?,
      lastKm: json['last_km'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicle_id': vehicleId,
      'driver_id': driverId,
      'date': date.toIso8601String().split('T').first,
      'destination': destination,
      'start_time': time,
      'end_time': endTime,
      'last_km': lastKm,
      'status': status,
      'user_name': user,
    };
  }

  CarpoolHistoryItem copyWith({
    String? status,
    String? endTime,
    String? lastKm,
    DateTime? date,
  }) {
    return CarpoolHistoryItem(
      id: id,
      vehicleId: vehicleId,
      driverId: driverId,
      site: site,
      vehicle: vehicle,
      time: time,
      status: status ?? this.status,
      driver: driver,
      user: user,
      destination: destination,
      date: date ?? this.date,
      endTime: endTime ?? this.endTime,
      lastKm: lastKm ?? this.lastKm,
    );
  }
}
