import 'package:flutter/material.dart';
import '../patrol/patrol_store.dart';
import 'admin_drawer.dart';
import 'admin_users_store.dart';

class AdminPatrolPage extends StatefulWidget {
  const AdminPatrolPage({super.key});

  @override
  State<AdminPatrolPage> createState() => _AdminPatrolPageState();
}

class _AdminPatrolPageState extends State<AdminPatrolPage> {
  DateTime? _selectedDate;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    adminUsersStore.load();
    _loadData();
  }

  void _loadData() {
    final date = _selectedDate == null ? null : _formatDateKey(_selectedDate!);
    patrolStore.load(date: date, userId: _selectedUserId);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedUserId = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AdminDrawer(currentPage: AdminPage.patrol),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder<List<PatrolEntry>>(
              valueListenable: patrolStore.entries,
              builder: (context, entries, _) {
                return ValueListenableBuilder<List<PatrolConditionReport>>(
                  valueListenable: patrolStore.conditionReports,
                  builder: (context, reports, _) {
                    final summaries = _buildSummaries(entries, reports);
                    return _buildSummaryList(summaries);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 24, right: 24),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Hasil Patroli",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryList(List<_PatrolSummary> summaries) {
    if (summaries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        children: [
          _buildFilters(),
          const SizedBox(height: 24),
          const Center(child: Text("Belum ada data patroli.")),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: summaries.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildFilters();
        }
        final summary = summaries[index - 1];
        return _buildSummaryCard(summary);
      },
    );
  }

  Widget _buildFilters() {
    final hasFilter = _selectedDate != null || _selectedUserId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Filter",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 220, child: _buildUserFilter()),
              SizedBox(width: 200, child: _buildDateFilter()),
            ],
          ),
          if (hasFilter) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _clearFilters,
                child: const Text("Reset filter"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserFilter() {
    return ValueListenableBuilder<List<AdminUser>>(
      valueListenable: adminUsersStore.users,
      builder: (context, users, _) {
        final items = <DropdownMenuItem<int?>>[
          const DropdownMenuItem(
            value: null,
            child: Text("Semua User"),
          ),
          ...users
              .where((user) => user.id != null)
              .map(
                (user) => DropdownMenuItem(
                  value: user.id,
                  child: Text(user.name),
                ),
              ),
        ];

        return DropdownButtonFormField<int?>(
          value: _selectedUserId,
          items: items,
          onChanged: (value) {
            setState(() {
              _selectedUserId = value;
            });
            _loadData();
          },
          decoration: InputDecoration(
            labelText: "User",
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateFilter() {
    final label = _selectedDate == null ? "Semua tanggal" : _formatDate(_selectedDate!);

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Tanggal",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          suffixIcon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFF6B7280)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(_PatrolSummary summary) {
    final areas = summary.areas;
    final report = summary.report;
    final totalScans = summary.entries.length;
    final totalPhotos = summary.totalPhotos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.officer,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(summary.date),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "$totalScans Scan",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (areas.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas.map(_areaChip).toList(),
            )
          else
            const Text(
              "Tidak ada area patroli.",
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statPill("Foto", "$totalPhotos"),
              const SizedBox(width: 8),
              _statPill("Area", "${areas.length}"),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Laporan Kondisi",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (report != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Pukul ${report.time}",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (report == null)
            const Text(
              "Belum ada laporan kondisi.",
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            )
          else ...[
            _infoRow(Icons.visibility, "Situasi", report.situasi),
            const SizedBox(height: 6),
            _infoRow(Icons.warning_amber_rounded, "AGHT", report.aght),
            const SizedBox(height: 6),
            _infoRow(Icons.cloud, "Cuaca", report.cuaca),
            const SizedBox(height: 6),
            _infoRow(Icons.water_drop, "PDAM", report.pdam),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _miniInfo("WFO", "${report.wfo} Orang")),
                const SizedBox(width: 8),
                Expanded(child: _miniInfo("Tambahan", "${report.tambahan} Orang")),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _areaChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4338CA),
        ),
      ),
    );
  }

  Widget _buildScanList() {
    return ValueListenableBuilder<List<PatrolEntry>>(
      valueListenable: patrolStore.entries,
      builder: (context, entries, _) {
        if (entries.isEmpty) {
          return const Center(child: Text("Belum ada hasil scan."));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.area,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Lengkap",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow(Icons.qr_code, "Barcode", entry.barcode),
                  const SizedBox(height: 8),
                  _infoRow(Icons.photo_camera, "Foto", "${entry.photoCount} Foto"),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatTimestamp(entry.timestamp),
                      style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildConditionList() {
    return ValueListenableBuilder<List<PatrolConditionReport>>(
      valueListenable: patrolStore.conditionReports,
      builder: (context, reports, _) {
        if (reports.isEmpty) {
          return const Center(child: Text("Belum ada laporan kondisi."));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(report.date),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D5AA5)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Pukul ${report.time}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _infoRow(Icons.visibility, "Situasi", report.situasi),
                  const SizedBox(height: 8),
                  _infoRow(Icons.warning_amber_rounded, "AGHT", report.aght),
                  const SizedBox(height: 8),
                  _infoRow(Icons.cloud, "Cuaca", report.cuaca),
                  const SizedBox(height: 8),
                  _infoRow(Icons.water_drop, "PDAM", "${report.pdam} "),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _miniInfo("WFO", "${report.wfo} Orang")),
                      const SizedBox(width: 8),
                      Expanded(child: _miniInfo("Tambahan", "${report.tambahan} Orang")),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Oleh: ${report.officer}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        SizedBox(
          width: 70, 
          child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ),
        const Text(": ", style: TextStyle(color: Color(0xFF6B7280))),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        ),
      ],
    );
  }

  Widget _miniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  List<_PatrolSummary> _buildSummaries(
    List<PatrolEntry> entries,
    List<PatrolConditionReport> reports,
  ) {
    final grouped = <String, _PatrolSummary>{};

    for (final entry in entries) {
      final dateOnly = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);
      final officer = (entry.officer ?? '').trim().isEmpty ? 'Tidak diketahui' : entry.officer!.trim();
      final userKey = entry.userId?.toString() ?? officer.toLowerCase();
      final key = "${_formatDateKey(dateOnly)}|$userKey";
      final summary = grouped.putIfAbsent(
        key,
        () => _PatrolSummary(date: dateOnly, userKey: userKey, userId: entry.userId, officer: officer),
      );
      summary.entries.add(entry);
      if (summary.officer.isEmpty || summary.officer == 'Tidak diketahui') {
        summary.officer = officer;
      }
    }

    for (final report in reports) {
      final dateOnly = DateTime(report.date.year, report.date.month, report.date.day);
      final officer = report.officer.trim().isEmpty ? 'Tidak diketahui' : report.officer.trim();
      final userKey = report.userId?.toString() ?? officer.toLowerCase();
      final key = "${_formatDateKey(dateOnly)}|$userKey";
      final summary = grouped.putIfAbsent(
        key,
        () => _PatrolSummary(date: dateOnly, userKey: userKey, userId: report.userId, officer: officer),
      );
      if (summary.report == null || _isReportNewer(report, summary.report!)) {
        summary.report = report;
      }
      if (summary.officer.isEmpty || summary.officer == 'Tidak diketahui') {
        summary.officer = officer;
      }
    }

    final summaries = grouped.values.toList();
    summaries.sort((a, b) {
      final dateCompare = b.date.compareTo(a.date);
      if (dateCompare != 0) {
        return dateCompare;
      }
      return a.officer.compareTo(b.officer);
    });
    return summaries;
  }

  bool _isReportNewer(PatrolConditionReport candidate, PatrolConditionReport current) {
    final candidateTime = _buildReportDateTime(candidate);
    final currentTime = _buildReportDateTime(current);
    return candidateTime.isAfter(currentTime);
  }

  DateTime _buildReportDateTime(PatrolConditionReport report) {
    final parts = report.time.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(report.date.year, report.date.month, report.date.day, hour, minute);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$day/$month/${date.year}";
  }

  String _formatDateKey(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
  }

  String _formatTimestamp(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day-$month-$year $hour:$minute";
  }
}

class _PatrolSummary {
  _PatrolSummary({
    required this.date,
    required this.userKey,
    required this.userId,
    required this.officer,
  });

  final DateTime date;
  final String userKey;
  final int? userId;
  String officer;
  final List<PatrolEntry> entries = [];
  PatrolConditionReport? report;

  int get totalPhotos {
    var total = 0;
    for (final entry in entries) {
      total += entry.photoCount;
    }
    return total;
  }

  List<String> get areas {
    final areaSet = <String>{};
    for (final entry in entries) {
      areaSet.add(entry.area);
    }
    final areaList = areaSet.toList();
    areaList.sort();
    return areaList;
  }
}
