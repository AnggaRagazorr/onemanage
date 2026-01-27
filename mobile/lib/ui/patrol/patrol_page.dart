import 'package:flutter/material.dart';
import '../shell/app_drawer.dart';
import '../dashboard/dashboard_page.dart';
import 'patrol_area_page.dart';
import 'patrol_condition_form_page.dart';
import 'patrol_store.dart';

class PatrolPage extends StatefulWidget {
  const PatrolPage({super.key});

  @override
  State<PatrolPage> createState() => _PatrolPageState();
}

class _PatrolPageState extends State<PatrolPage> {
  @override
  void initState() {
    super.initState();
    // Load today's data to calculate progress
    patrolStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AppDrawer(currentPage: AppPage.patrol),
      body: Column(
        children: [
          // Premium Gradient Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D5AA5), Color(0xFF003377)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardPage()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  "Patroli",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Scaffold.of(context).openEndDrawer(),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ValueListenableBuilder<List<PatrolEntry>>(
              valueListenable: patrolStore.entries,
              builder: (context, entries, _) {
                // Logic: 4 patrols per area per day = 100%
                final now = DateTime.now();
                final todayEntries = entries.where((e) => 
                  e.timestamp.year == now.year && 
                  e.timestamp.month == now.month && 
                  e.timestamp.day == now.day
                ).toList();

                // Calculate count per area
                int countLuar = todayEntries.where((e) => e.area == "Area Luar").length;
                int countSmoking = todayEntries.where((e) => e.area == "Area Smooking").length;
                int countBalkon = todayEntries.where((e) => e.area == "Area Balkon").length;

                // Calculate Percentages (Max 4)
                double percentLuar = (countLuar / 4).clamp(0.0, 1.0);
                double percentSmoking = (countSmoking / 4).clamp(0.0, 1.0);
                double percentBalkon = (countBalkon / 4).clamp(0.0, 1.0);

                // Total Progress (Average of all areas)
                double totalProgress = (percentLuar + percentSmoking + percentBalkon) / 3;

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _progressCard(totalProgress),
                    const SizedBox(height: 24),
                    const Text(
                      "Pilih Area Patroli",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _areaCard(
                      title: "Area Luar",
                      subtitle: countLuar >= 4 ? "Patroli selesai" : "Tersisa ${4 - countLuar} patroli hari ini",
                      percent: "${(percentLuar * 100).toInt()}%",
                      badgeColor: const Color(0xFFFFE4EC),
                      iconColor: const Color(0xFFD6336C),
                      onTap: () => _openArea(
                        title: "Area Luar",
                        subtitle: "Silahkan scan barcode terlebih dahulu",
                        color: const Color(0xFFFFF1E8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _areaCard(
                      title: "Area Smooking",
                      subtitle: countSmoking >= 4 ? "Patroli selesai" : "Tersisa ${4 - countSmoking} patroli hari ini",
                      percent: "${(percentSmoking * 100).toInt()}%",
                      badgeColor: const Color(0xFFEDE9FE),
                      iconColor: const Color(0xFF7C3AED),
                      onTap: () => _openArea(
                        title: "Area Smooking",
                        subtitle: "Silahkan scan barcode terlebih dahulu",
                        color: const Color(0xFFF0F7FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _areaCard(
                      title: "Area Balkon",
                      subtitle: countBalkon >= 4 ? "Patroli selesai" : "Tersisa ${4 - countBalkon} patroli hari ini",
                      percent: "${(percentBalkon * 100).toInt()}%",
                      badgeColor: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      onTap: () => _openArea(
                        title: "Area Balkon",
                        subtitle: "Silahkan scan barcode terlebih dahulu",
                        color: const Color(0xFFFFE1C9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PatrolConditionFormPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D5AA5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF0D5AA5).withOpacity(0.4),
                        ),
                        child: const Text(
                          "Hasil Kondisi Patroli",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressCard(double progress) {
    // Format percentage to integer
    final int percentInt = (progress * 100).toInt();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D5AA5), Color(0xFF0284C7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D5AA5).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Progress patroli\nanda hari ini!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text(
                    "Lihat Detail",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                "$percentInt%",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _areaCard({
    required String title,
    required String subtitle,
    required String percent,
    required Color badgeColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) { // Parse percent string to double for progress bar
    double progressValue = double.tryParse(percent.replaceAll('%', '')) ?? 0.0;
    progressValue /= 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.shield_rounded, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            percent,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressValue,
                          backgroundColor: const Color(0xFFF3F4F6),
                          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openArea({
    required String title,
    required String subtitle,
    required Color color,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatrolAreaPage(
          title: title,
          subtitle: subtitle,
          bannerColor: color,
        ),
      ),
    );
  }
}
