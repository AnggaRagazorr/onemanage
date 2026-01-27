import 'package:flutter/material.dart';
import '../shell/app_drawer.dart';
import 'carpool_history_store.dart';
import 'carpool_models.dart';

class CarpoolHistoryPage extends StatefulWidget {
  const CarpoolHistoryPage({super.key});

  @override
  State<CarpoolHistoryPage> createState() => _CarpoolHistoryPageState();
}

class _CarpoolHistoryPageState extends State<CarpoolHistoryPage> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          // Gradient Header with Back Button
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
                  "History Pemakaian",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                                "Belum ada history.",
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: items.map(_historyCard).toList(),
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

  Widget _historyCard(CarpoolHistoryItem item) {
    final statusStyle = _statusStyle(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleHistoryTap(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
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
                      Text(
                        item.site,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.vehicle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 6),
                          Text(
                            item.time,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D5AA5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: Color(0xFF0D5AA5)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusStyle.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusStyle.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case "Done":
        return const _StatusStyle(
          background: Color(0xFFE8F0FE),
          foreground: Color(0xFF0D5AA5),
        );
      case "In Progress":
        return const _StatusStyle(
          background: Color(0xFFDCEBFF),
          foreground: Color(0xFF0B4A86),
        );
      default:
        return const _StatusStyle(
          background: Color(0xFFE8F0FE),
          foreground: Color(0xFF1E88E5),
        );
    }
  }

  Widget _bottomBack(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D5AA5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            "Back",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
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
      firstDate: DateTime(now.year - 5),
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
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final month = months[date.month - 1];
    return "$day $month, ${date.year}";
  }



  void _handleHistoryTap(CarpoolHistoryItem item) {
    if (item.status == "Done") {
      _showDoneDetails(item);
      return;
    }
    if (item.status == "In Progress") {
      _showCompleteForm(item);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data belum dimulai.")),
    );
  }

  void _showDoneDetails(CarpoolHistoryItem item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Detail Carpool"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Site: ${item.site}"),
              Text("Mobil: ${item.vehicle}"),
              Text("Driver: ${item.driver}"),
              Text("User: ${item.user}"),
              Text("Tujuan: ${item.destination}"),
              Text("Jam Keluar: ${item.time}"),
              Text("Jam Masuk: ${item.endTime ?? "-"}"),
              Text("KM Terakhir: ${item.lastKm ?? "-"}"),
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

  Future<void> _showCompleteForm(CarpoolHistoryItem item) async {
    final endTimeCtrl = TextEditingController(text: item.endTime ?? "");
    final kmCtrl = TextEditingController(text: item.lastKm ?? "");
    final result = await showModalBottomSheet<CarpoolHistoryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lengkapi Data",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text("Mobil: ${item.vehicle}"),
              const SizedBox(height: 12),
              TextField(
                controller: endTimeCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Jam Masuk",
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (picked != null) {
                    final hour = picked.hour.toString().padLeft(2, '0');
                    final minute = picked.minute.toString().padLeft(2, '0');
                    endTimeCtrl.text = "$hour:$minute";
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "KM Terakhir Mobil",
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (endTimeCtrl.text.trim().isEmpty || kmCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lengkapi jam masuk dan KM.")),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      item.copyWith(
                        status: "Done",
                        endTime: endTimeCtrl.text.trim(),
                        lastKm: kmCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      carpoolHistoryStore.updateItem(result);
    }
  }
}

class _StatusStyle {
  const _StatusStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
