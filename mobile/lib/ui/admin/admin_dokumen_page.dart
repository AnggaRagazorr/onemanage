import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../dokumen/dokumen_store.dart';
import 'admin_drawer.dart';

class AdminDokumenPage extends StatefulWidget {
  const AdminDokumenPage({super.key});

  @override
  State<AdminDokumenPage> createState() => _AdminDokumenPageState();
}

class _AdminDokumenPageState extends State<AdminDokumenPage> {
  @override
  void initState() {
    super.initState();
    // Load with existing filter if any
    final date = dokumenStore.filterDate.value;
    if (date != null) {
      dokumenStore.setFilter(date);
    } else {
      dokumenStore.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AdminDrawer(currentPage: AdminPage.dokumen),
      backgroundColor: const Color(0xFFF7F9FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ValueListenableBuilder<DateTime?>(
              valueListenable: dokumenStore.filterDate,
              builder: (context, selectedDate, _) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Data Dokumen Masuk",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _printDokumen(context);
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
    return ValueListenableBuilder<List<DokumenEntry>>(
      valueListenable: dokumenStore.entries,
      builder: (context, items, _) {
        final filtered = _filterEntries(items, selectedDate);
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
                    "Tabel Dokumen",
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
                      "${filtered.length} data",
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
                  constraints: const BoxConstraints(minWidth: 900),
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF3F4F6)),
                    columns: const [
                      DataColumn(label: Text("No")),
                      DataColumn(label: Text("Tgl")),
                      DataColumn(label: Text("Hari")),
                      DataColumn(label: Text("Jam")),
                      DataColumn(label: Text("Asal Barang")),
                      DataColumn(label: Text("Nama Barang")),
                      DataColumn(label: Text("Jumlah")),
                      DataColumn(label: Text("Atas Nama")),
                      DataColumn(label: Text("Penerima")),
                    ],
                    rows: filtered.isEmpty
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
                                DataCell(Text("-")),
                                DataCell(Text("-")),
                              ],
                            ),
                          ]
                        : filtered.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            final item = entry.value;
                            return DataRow(
                              cells: [
                                DataCell(Text("$index")),
                                DataCell(Text(_formatDateShort(item.date))),
                                DataCell(Text(item.day)),
                                DataCell(Text(item.time)),
                                DataCell(Text(item.origin)),
                                DataCell(Text(item.name)),
                                DataCell(Text(item.qty)),
                                DataCell(Text(item.owner)),
                                DataCell(Text(item.receiver)),
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

  Future<void> _printDokumen(BuildContext context) async {
    // Current filter is in store
    final selectedDate = dokumenStore.filterDate.value;
    final entries = _filterEntries(dokumenStore.entries.value, selectedDate);
    final doc = await _buildDokumenPdf(entries);
    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: 'dokumen-masuk.pdf',
    );
  }

  Future<pw.Document> _buildDokumenPdf(List<DokumenEntry> entries) async {
    final doc = pw.Document();
    final logoData = await rootBundle.load('assets/image/logo_pgncom.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final now = DateTime.now();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          _pdfHeader(
            logo: logo,
            title: "Dokumen Masuk",
            printDate: _formatPrintDate(now),
            officer: "Admin",
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE5E7EB)),
            headers: const [
              "No",
              "Tgl",
              "Hari",
              "Jam",
              "Asal Barang",
              "Nama Barang",
              "Jumlah",
              "Atas Nama",
              "Penerima",
            ],
            data: entries.isEmpty
                ? [
                    ["-", "-", "-", "-", "Belum ada data", "-", "-", "-", "-"],
                  ]
                : entries.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return [
                      "$index",
                      _formatDateShort(item.date),
                      item.day,
                      item.time,
                      item.origin,
                      item.name,
                      item.qty,
                      item.owner,
                      item.receiver,
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
            "Dokumen Masuk",
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
    final current = dokumenStore.filterDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null) {
      dokumenStore.setFilter(picked);
    }
  }

  Future<void> _resetFilter() async {
    dokumenStore.setFilter(null);
  }

  List<DokumenEntry> _filterEntries(List<DokumenEntry> entries, DateTime? date) {
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
}
