import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../rekap/rekap_store.dart';
import 'admin_drawer.dart';

class AdminRekapPage extends StatefulWidget {
  const AdminRekapPage({super.key});

  @override
  State<AdminRekapPage> createState() => _AdminRekapPageState();
}

class _AdminRekapPageState extends State<AdminRekapPage> {
  final ScrollController _scrollController = ScrollController();
  
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

    final date = rekapStore.filterDate.value;
    if (date != null) {
      rekapStore.setFilter(date);
    } else {
      rekapStore.load();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      rekapStore.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AdminDrawer(currentPage: AdminPage.rekap),
      body: Column(
        children: [
          _buildHeader(),

          Expanded(
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: rekapStore.filterDate,
              builder: (context, selectedDate, _) {
                return ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Data Rekap Harian",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _printRekap(context);
                          },
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text("Cetak"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D5AA5),
                            side: BorderSide(color: const Color(0xFF0D5AA5).withOpacity(0.4)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _selectionCard(
                      title: "Filter Tanggal",
                      value: _formatFilterDate(selectedDate),
                      icon: Icons.calendar_month,
                      onTap: _pickDate,
                    ),
                    if (selectedDate != null) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _resetFilter,
                          child: const Text("Reset filter"),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _dataTable(selectedDate),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataTable(DateTime? selectedDate) {
    return ValueListenableBuilder<List<RekapEntry>>(
      valueListenable: rekapStore.entries,
      builder: (context, entries, _) {
        final filtered = _filterEntries(entries, selectedDate);
        final sortedItems = List<RekapEntry>.from(filtered)
          ..sort((a, b) {
            final dateCompare = a.date.compareTo(b.date);
            if (dateCompare != 0) {
              return dateCompare;
            }
            return _parseTime(a.startTime).compareTo(_parseTime(b.startTime));
          });
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tabel Rekap",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "${sortedItems.length} data",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 880),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                    columns: const [
                      DataColumn(label: Text("No")),
                      DataColumn(label: Text("Tanggal")),
                      DataColumn(label: Text("Jam Mulai")),
                      DataColumn(label: Text("Jam Selesai")),
                      DataColumn(label: Text("Uraian Kegiatan")),
                      DataColumn(label: Text("Petugas")),
                      DataColumn(label: Text("Jaga")),
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
                                DataCell(Text("-")),
                                DataCell(Text("-")),
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
                                DataCell(Text(item.guard)),
                                DataCell(Text(item.shift)),
                              ],
                            );
                          }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printRekap(BuildContext context) async {
    final selectedDate = rekapStore.filterDate.value;
    final entries = _filterEntries(rekapStore.entries.value, selectedDate);
    final doc = await _buildRekapPdf(entries);
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'rekap-harian.pdf',
    );
  }

  Future<pw.Document> _buildRekapPdf(List<RekapEntry> entries) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/image/logo_pgncom.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final now = DateTime.now();
    final guards = entries.map((e) => e.guard).toSet().where((e) => e.trim().isNotEmpty).toList();
    final guardLabel = guards.isEmpty ? "-" : guards.join(", ");

    final sortedItems = List<RekapEntry>.from(entries)
      ..sort((a, b) {
        final dateCompare = a.date.compareTo(b.date);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return _parseTime(a.startTime).compareTo(_parseTime(b.startTime));
      });

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _pdfHeader(
            logo: logo,
            title: "Rekap Harian",
            printDate: _formatPrintDate(now),
            officer: guardLabel,
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE5E7EB)),
            headers: const [
              "No",
              "Tanggal",
              "Jam Mulai",
              "Jam Selesai",
              "Uraian Kegiatan",
              "Petugas",
              "Jaga",
            ],
            data: sortedItems.isEmpty
                ? [
                    ["-", "-", "-", "-", "Belum ada data", "-", "-"],
                  ]
                : sortedItems.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return [
                      "$index",
                      _formatDateShort(item.date),
                      item.startTime,
                      item.endTime,
                      item.activity,
                      item.guard,
                      item.shift,
                    ];
                  }).toList(),
          ),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _pdfHeader({
    required pw.ImageProvider logo,
    required String title,
    required String printDate,
    required String officer,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Image(logo, width: 90),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text("Tanggal Cetak: $printDate", style: const pw.TextStyle(fontSize: 10)),
              pw.Text("Petugas: $officer", style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  String _formatPrintDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return "$day-$month-$year";
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 24, left: 24, right: 24),
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
            "Rekap Harian",
            style: TextStyle(
              fontSize: 22,
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final current = rekapStore.filterDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      rekapStore.setFilter(picked);
    }
  }

  Future<void> _resetFilter() async {
    rekapStore.setFilter(null);
  }

  List<RekapEntry> _filterEntries(List<RekapEntry> entries, DateTime? date) {
    if (date == null) {
      return entries;
    }
    return entries.where((entry) => _isSameDay(entry.date, date)).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatFilterDate(DateTime? date) {
    if (date == null) {
      return "Semua tanggal";
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "${date.year}-$month-$day";
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
