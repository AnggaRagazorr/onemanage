import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../patrol/patrol_store.dart';
import '../rekap/rekap_store.dart';
import '../dokumen/dokumen_store.dart';
import 'admin_drawer.dart';
import 'admin_users_store.dart';
import 'admin_carpool_store.dart';
import '../carpool/carpool_history_store.dart';
import '../carpool/carpool_models.dart';
import 'security_stats_store.dart';
import 'security_detail_page.dart';

import '../../services/notification_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _name = 'Loading...';

  @override
  void initState() {
    super.initState();
    NotificationService().subscribeToTopic('admin_rekap_updates'); // Subscribe to admin notifications
    patrolStore.load();
    rekapStore.load();
    dokumenStore.load();
    adminUsersStore.load();
    adminCarpoolStore.load();
    carpoolHistoryStore.load(status: "In Progress");
    securityStatsStore.load();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.instance.getName();
    if (mounted) {
      setState(() {
        _name = name ?? 'Admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D5AA5), Color(0xFF003377)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                        const Text(
                          'ADMIN PORTAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        // Placeholder for symmetry
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.admin_panel_settings, size: 32, color: Color(0xFF0D5AA5)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Administrator',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ringkasan Sistem",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Grid Layout for Stats
                  ValueListenableBuilder<List<PatrolEntry>>(
                    valueListenable: patrolStore.entries,
                    builder: (context, entries, _) {
                      return _statCard("Hasil Patroli", "${entries.length}", Icons.shield, const Color(0xFF0D5AA5));
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ValueListenableBuilder<List<RekapEntry>>(
                          valueListenable: rekapStore.entries,
                          builder: (context, entries, _) {
                            return _statCard("Rekap", "${entries.length}", Icons.event_note, const Color(0xFFD32F2F), compact: true);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ValueListenableBuilder<List<DokumenEntry>>(
                          valueListenable: dokumenStore.entries,
                          builder: (context, entries, _) {
                            return _statCard("Dokumen", "${entries.length}", Icons.folder, const Color(0xFFFB8C00), compact: true);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  ValueListenableBuilder<List<CarpoolHistoryItem>>(
                    valueListenable: carpoolHistoryStore.items,
                    builder: (context, logs, _) {
                      final activeVehicleIds = <int>{};
                      final activeDriverIds = <int>{};
                      final activeVehicleDetails = <String>[];
                      final activeDriverDetails = <String>[];
                      final seenVehicleIds = <int>{};
                      final seenDriverIds = <int>{};
                      for (final item in logs) {
                        if (item.status != "In Progress") {
                          continue;
                        }
                        activeVehicleIds.add(item.vehicleId);
                        if (item.driverId != null) {
                          activeDriverIds.add(item.driverId!);
                        }
                        if (!seenVehicleIds.contains(item.vehicleId)) {
                          activeVehicleDetails.add(_formatAssignment(
                            driver: item.driver,
                            vehicle: item.vehicle,
                            driverFirst: false,
                          ));
                          seenVehicleIds.add(item.vehicleId);
                        }
                        if (item.driverId != null && !seenDriverIds.contains(item.driverId)) {
                          activeDriverDetails.add(_formatAssignment(
                            driver: item.driver,
                            vehicle: item.vehicle,
                            driverFirst: true,
                          ));
                          seenDriverIds.add(item.driverId!);
                        }
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 380;

                          Widget buildCarsCard() {
                            return ValueListenableBuilder<List<AdminCar>>(
                              valueListenable: adminCarpoolStore.cars,
                              builder: (context, cars, _) {
                                final totalCars = cars.length;
                                final busyCars = activeVehicleIds.length > totalCars
                                    ? totalCars
                                    : activeVehicleIds.length;
                                final availableCars = totalCars - busyCars;
                                return _carpoolDetailCard(
                                  title: "Mobil Carpool",
                                  total: totalCars,
                                  availableLabel: "Tersedia",
                                  available: availableCars,
                                  busyLabel: "Tidak tersedia",
                                  busy: busyCars,
                                  unitLabel: "unit",
                                  icon: Icons.directions_car,
                                  color: const Color(0xFF1E88E5),
                                  compact: isNarrow,
                                  activeDetails: activeVehicleDetails,
                                  activeTitle: "Sedang digunakan",
                                );
                              },
                            );
                          }

                          Widget buildDriversCard() {
                            return ValueListenableBuilder<List<AdminDriver>>(
                              valueListenable: adminCarpoolStore.drivers,
                              builder: (context, drivers, _) {
                                final totalDrivers = drivers.length;
                                final busyDrivers = activeDriverIds.length > totalDrivers
                                    ? totalDrivers
                                    : activeDriverIds.length;
                                final availableDrivers = totalDrivers - busyDrivers;
                                return _carpoolDetailCard(
                                  title: "Driver Carpool",
                                  total: totalDrivers,
                                  availableLabel: "Tersedia",
                                  available: availableDrivers,
                                  busyLabel: "Sedang bertugas",
                                  busy: busyDrivers,
                                  unitLabel: "orang",
                                  icon: Icons.badge_outlined,
                                  color: const Color(0xFF00897B),
                                  compact: isNarrow,
                                  activeDetails: activeDriverDetails,
                                  activeTitle: "Sedang bertugas",
                                );
                              },
                            );
                          }

                          if (isNarrow) {
                            return Column(
                              children: [
                                buildCarsCard(),
                                const SizedBox(height: 16),
                                buildDriversCard(),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: buildCarsCard()),
                              const SizedBox(width: 16),
                              Expanded(child: buildDriversCard()),
                            ],
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  
                  ValueListenableBuilder<List<AdminUser>>(
                    valueListenable: adminUsersStore.users,
                    builder: (context, users, _) {
                      return _statCard("Total User", "${users.length}", Icons.people_alt, const Color(0xFF2E7D32));
                    },
                  ),

                  const SizedBox(height: 24),
                  
                  // Security Statistics Section
                  const Text(
                    "Statistik Security",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ValueListenableBuilder<bool>(
                    valueListenable: securityStatsStore.isLoading,
                    builder: (context, isLoading, _) {
                      if (isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      return ValueListenableBuilder<List<SecurityStats>>(
                        valueListenable: securityStatsStore.stats,
                        builder: (context, stats, _) {
                          if (stats.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  "Belum ada data security",
                                  style: TextStyle(color: Color(0xFF6B7280)),
                                ),
                              ),
                            );
                          }
                          return _buildSecurityStatsList(stats);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: const AdminDrawer(currentPage: AdminPage.dashboard),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {bool compact = false}) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: compact ? 20 : 24),
          ),
          SizedBox(width: compact ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carpoolDetailCard({
    required String title,
    required int total,
    required String availableLabel,
    required int available,
    required String busyLabel,
    required int busy,
    required String unitLabel,
    required IconData icon,
    required Color color,
    bool compact = false,
    List<String> activeDetails = const [],
    String? activeTitle,
  }) {
    final availabilityRate = total == 0 ? 0.0 : available / total;
    final availabilityPercent = (availabilityRate * 100).round();
    const availableColor = Color(0xFF16A34A);
    const busyColor = Color(0xFFDC2626);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 320;
        final pillBelow = compact || isTight;
        final stackStats = constraints.maxWidth < 260;
        final padding = compact ? 14.0 : 16.0;
        final headerGap = compact ? 10.0 : 12.0;
        final sectionGap = compact ? 10.0 : 12.0;
        final progressHeight = compact ? 7.0 : 8.0;

        final titleStyle = TextStyle(
          fontSize: compact ? 13 : 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        );
        final totalStyle = TextStyle(
          fontSize: compact ? 20 : 22,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1F2937),
        );
        final pill = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            "Ketersediaan $availabilityPercent%",
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 10 : 12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: compact ? 18 : 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: titleStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "$total",
                          style: totalStyle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!pillBelow) pill,
                ],
              ),
              if (pillBelow) ...[
                SizedBox(height: compact ? 8 : 10),
                Align(alignment: Alignment.centerLeft, child: pill),
              ],
              SizedBox(height: headerGap),
              if (stackStats) ...[
                _carpoolStatPill(
                  label: availableLabel,
                  value: available,
                  color: availableColor,
                ),
                const SizedBox(height: 8),
                _carpoolStatPill(
                  label: busyLabel,
                  value: busy,
                  color: busyColor,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _carpoolStatPill(
                        label: availableLabel,
                        value: available,
                        color: availableColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _carpoolStatPill(
                        label: busyLabel,
                        value: busy,
                        color: busyColor,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: sectionGap),
              const Text(
                "Ketersediaan",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: availabilityRate,
                  minHeight: progressHeight,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Tersedia $available dari $total $unitLabel",
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (activeDetails.isNotEmpty) ...[
                SizedBox(height: compact ? 10 : 12),
                Text(
                  activeTitle ?? "Sedang bertugas",
                  style: TextStyle(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                ..._buildDetailLines(activeDetails, compact: compact),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _carpoolStatPill({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAssignment({
    required String driver,
    required String vehicle,
    required bool driverFirst,
  }) {
    final driverLabel = driver.trim().isEmpty || driver.trim() == "-" ? "Driver belum ditentukan" : driver.trim();
    final vehicleLabel = vehicle.trim().isEmpty || vehicle.trim() == "-" ? "Mobil belum ditentukan" : vehicle.trim();
    if (driverFirst) {
      return "Driver: $driverLabel | Mobil: $vehicleLabel";
    }
    return "Mobil: $vehicleLabel | Driver: $driverLabel";
  }

  List<Widget> _buildDetailLines(List<String> details, {required bool compact}) {
    const maxItems = 3;
    final visible = details.take(maxItems).toList();
    final extra = details.length - visible.length;
    final textStyle = TextStyle(
      fontSize: compact ? 11 : 12,
      color: const Color(0xFF4B5563),
      height: 1.3,
    );
    final widgets = <Widget>[];
    for (final item in visible) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item, style: textStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
      );
    }
    if (extra > 0) {
      widgets.add(
        Text(
          "+$extra lainnya",
          style: textStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }
    return widgets;
  }

  Widget _buildSecurityStatsList(List<SecurityStats> stats) {
    return Column(
      children: stats.map((stat) => _buildSecurityCard(stat)).toList(),
    );
  }

  Widget _buildSecurityCard(SecurityStats stat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SecurityDetailPage(
              userId: stat.id,
              userName: stat.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stat.isWorking ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            // Avatar with score
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _getScoreColor(stat.scorePercentage).withOpacity(0.1),
                  child: Text(
                    stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(stat.scorePercentage),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name and stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hari ini: ${stat.patrolCountToday}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bulan: ${stat.patrolCountMonth}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getScoreColor(stat.scorePercentage).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${stat.scorePercentage}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getScoreColor(stat.scorePercentage),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int percentage) {
    if (percentage >= 80) return const Color(0xFF10B981);
    if (percentage >= 60) return const Color(0xFF0D5AA5);
    if (percentage >= 40) return const Color(0xFFFB8C00);
    return const Color(0xFFEF4444);
  }
}
