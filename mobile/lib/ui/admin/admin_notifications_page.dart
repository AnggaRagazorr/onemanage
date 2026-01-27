import 'package:flutter/material.dart';
import '../rekap/rekap_store.dart';
import 'admin_drawer.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  @override
  void initState() {
    super.initState();
    rekapStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi Rekap"),
        backgroundColor: const Color(0xFF0D5AA5),
      ),
      endDrawer: const AdminDrawer(currentPage: AdminPage.notif),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ValueListenableBuilder<List<RekapEntry>>(
        valueListenable: rekapStore.entries,
        builder: (context, entries, _) {
          if (entries.isEmpty) {
            return const Center(child: Text("Belum ada notifikasi."));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Uraian: ${entry.activity}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Petugas: ${entry.guard} | Jaga: ${entry.shift}",
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tanggal: ${_formatDate(entry.date)}",
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return "$day-$month-$year";
  }
}
