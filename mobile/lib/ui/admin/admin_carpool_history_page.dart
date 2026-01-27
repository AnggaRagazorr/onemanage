import 'package:flutter/material.dart';
import '../carpool/carpool_history_store.dart';
import '../carpool/carpool_models.dart';
import 'admin_drawer.dart';

class AdminCarpoolHistoryPage extends StatefulWidget {
  const AdminCarpoolHistoryPage({super.key});

  @override
  State<AdminCarpoolHistoryPage> createState() => _AdminCarpoolHistoryPageState();
}

class _AdminCarpoolHistoryPageState extends State<AdminCarpoolHistoryPage> {
  @override
  void initState() {
    super.initState();
    final date = carpoolHistoryStore.filterDate.value;
    if (date != null) {
      carpoolHistoryStore.setFilter(date);
    } else {
      carpoolHistoryStore.load();
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AdminDrawer(currentPage: AdminPage.carpool),
      body: Column(
        children: [
          // Gradient Header
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 20),
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
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  "History Carpool",
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
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: carpoolHistoryStore.filterDate,
              builder: (context, selectedDate, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  children: [
                    _selectionCard(
                      title: "Filter Tanggal",
                      value: _formatDate(selectedDate),
                      icon: Icons.calendar_month,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<List<CarpoolHistoryItem>>(
                      valueListenable: carpoolHistoryStore.items,
                      builder: (context, items, _) {
                        if (items.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 24),
                            child: Center(
                              child: Text(
                                "Belum ada history carpool.",
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: items.map((item) => _historyCard(context, item)).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0D5AA5)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Color(0xFF0D5AA5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyCard(BuildContext context, CarpoolHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showHistoryDetail(context, item),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.vehicle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.destination} • ${item.time}",
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D5AA5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = carpoolHistoryStore.filterDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      carpoolHistoryStore.setFilter(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "Semua tanggal";
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }



  void _showHistoryDetail(BuildContext context, CarpoolHistoryItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Detail Carpool"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mobil: ${item.vehicle}"),
              Text("Driver: ${item.driver}"),
              Text("User: ${item.user}"),
              Text("Tujuan: ${item.destination}"),
              Text("Jam Keluar: ${item.time}"),
              Text("Jam Masuk: ${item.endTime ?? "-"}"),
              Text("KM Terakhir: ${item.lastKm ?? "-"}"),
              Text("Status: ${item.status}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}
