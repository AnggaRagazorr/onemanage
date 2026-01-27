import 'package:flutter/material.dart';
import '../shell/app_drawer.dart';
import 'rekap_store.dart';
import '../../services/auth_service.dart';

class RekapPage extends StatefulWidget {
  const RekapPage({super.key});

  @override
  State<RekapPage> createState() => _RekapPageState();
}

class _RekapPageState extends State<RekapPage> {
  DateTime? selectedDate;
  final TextEditingController startTimeCtrl = TextEditingController();
  final TextEditingController endTimeCtrl = TextEditingController();
  final TextEditingController activityCtrl = TextEditingController();
  String selectedGuard = "";
  String selectedShift = "";

  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    activityCtrl.dispose();
    startTimeCtrl.dispose();
    endTimeCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Listen for errors
    rekapStore.errorMessage.addListener(() {
      final msg = rekapStore.errorMessage.value;
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    rekapStore.load();
    _loadUserGuard();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      rekapStore.loadMore();
    }
  }

  Future<void> _loadUserGuard() async {
    final name = await AuthService.instance.getName();
    if (!mounted) {
      return;
    }
    final trimmed = name?.trim() ?? "";
    if (trimmed.isEmpty) {
      return;
    }
    setState(() => selectedGuard = trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AppDrawer(currentPage: AppPage.rekap),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Rekap Harian",
                  style: TextStyle(
                    fontSize: 20,
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
          ),

          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                _guardPicker(),
                const SizedBox(height: 12),
                _formCard(),
                const SizedBox(height: 24),
                const Text(
                  "Data Rekap Harian",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                _guardSummary(),
                const SizedBox(height: 12),
                _dataTable(),
                ValueListenableBuilder<bool>(
                  valueListenable: rekapStore.isLoadingMore,
                  builder: (context, isLoading, _) {
                    if (!isLoading) return const SizedBox.shrink();
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardPicker() {
    const shiftOptions = ["Pagi", "Malam"];
    final shiftValue = shiftOptions.contains(selectedShift) ? selectedShift : null;
    final guardLabel = selectedGuard.isEmpty ? "Memuat..." : selectedGuard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Petugas Jaga :",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              guardLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D5AA5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              "Jaga :",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: shiftValue,
              hint: const Text("Pilih Shift"),
              items: shiftOptions
                  .map((shift) => DropdownMenuItem(value: shift, child: Text(shift)))
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => selectedShift = value);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _guardSummary() {
    return Row(
      children: [
        Text(
          "Petugas Jaga: $selectedGuard",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "Jaga: $selectedShift",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _formCard() {
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
        children: [
          _formRow(
            label: "Tanggal",
            value: _formatDate(selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _timeRow(
            label: "Jam Mulai",
            controller: startTimeCtrl,
          ),
          const SizedBox(height: 12),
          _timeRow(
            label: "Jam Selesai",
            controller: endTimeCtrl,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: activityCtrl,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: "Kejadian / Aktivitas",
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit() ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5AA5),
                disabledBackgroundColor: const Color(0xFF9DBCE6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Submit",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(value),
                  const Icon(Icons.calendar_month, size: 18, color: Color(0xFF0D5AA5)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timeRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              hintText: "Contoh 08:00",
              suffixText: "jj:mm",
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder<List<RekapEntry>>(
        valueListenable: rekapStore.entries,
        builder: (context, entries, _) {
          final sortedItems = List<RekapEntry>.from(entries)
            ..sort((a, b) {
              final dateCompare = a.date.compareTo(b.date);
              if (dateCompare != 0) {
                return dateCompare;
              }
              return _parseTime(a.startTime).compareTo(_parseTime(b.startTime));
            });
          return DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
            columns: const [
              DataColumn(label: Text("No")),
              DataColumn(label: Text("Tanggal")),
              DataColumn(label: Text("Jam Mulai")),
              DataColumn(label: Text("Jam Selesai")),
              DataColumn(label: Text("Uraian Kegiatan")),
            ],
            rows: sortedItems.isEmpty
                ? [
                    const DataRow(
                      cells: [
                        DataCell(Text("-")),
                        DataCell(Text("-")),
                        DataCell(Text("-")),
                        DataCell(Text("-")),
                        DataCell(Text("Belum ada data")),
                      ],
                    ),
                  ]
                : sortedItems.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text("$index")),
                        DataCell(Text(_formatDateShort(item.date))),
                        DataCell(Text(item.startTime)),
                        DataCell(Text(item.endTime)),
                        DataCell(SizedBox(width: 260, child: Text(item.activity))),
                      ],
                    );
                  }).toList(),
          );
        },
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  bool _canSubmit() {
    return selectedDate != null &&
        startTimeCtrl.text.trim().isNotEmpty &&
        endTimeCtrl.text.trim().isNotEmpty &&
        activityCtrl.text.trim().isNotEmpty;
  }

  void _submit() {
    rekapStore.add(
      RekapEntry(
        date: selectedDate!,
        startTime: startTimeCtrl.text.trim(),
        endTime: endTimeCtrl.text.trim(),
        activity: activityCtrl.text.trim(),
        guard: selectedGuard,
        shift: selectedShift,
      ),
    );
    setState(() {
      activityCtrl.clear();
      startTimeCtrl.clear();
      endTimeCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Rekap tersimpan.")),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "Pilih tanggal";
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$day-$month-${date.year}";
  }

  String _formatDateShort(DateTime date) {
    const months = [
      "JAN",
      "FEB",
      "MAR",
      "APR",
      "MEI",
      "JUN",
      "JUL",
      "AUG",
      "SEP",
      "OCT",
      "NOV",
      "DEC",
    ];
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year.toString().substring(2);
    return "$day-$month-$year";
  }

  int _parseTime(String value) {
    final parts = value.split(":");
    if (parts.length != 2) {
      return 0;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return (hour * 60) + minute;
  }
}
