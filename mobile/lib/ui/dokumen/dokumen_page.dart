import 'package:flutter/material.dart';
import '../shell/app_drawer.dart';
import '../dashboard/dashboard_page.dart';
import 'dokumen_store.dart';

class DokumenPage extends StatefulWidget {
  const DokumenPage({super.key});

  @override
  State<DokumenPage> createState() => _DokumenPageState();
}

class _DokumenPageState extends State<DokumenPage> {
  DateTime? selectedDate;
  final TextEditingController dayCtrl = TextEditingController();
  final TextEditingController timeCtrl = TextEditingController();
  final TextEditingController originCtrl = TextEditingController();
  final TextEditingController itemCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController ownerCtrl = TextEditingController();
  final TextEditingController receiverCtrl = TextEditingController();
  
  bool _isSubmitting = false;

  void _submit() async {
    setState(() => _isSubmitting = true);

    try {
      await dokumenStore.add(
        DokumenEntry(
          date: selectedDate!,
          day: dayCtrl.text.trim(),
          time: timeCtrl.text.trim(),
          origin: originCtrl.text.trim(),
          name: itemCtrl.text.trim(),
          qty: qtyCtrl.text.trim(),
          owner: ownerCtrl.text.trim(),
          receiver: receiverCtrl.text.trim(),
        ),
      );

      if (!mounted) return;

      setState(() {
        dayCtrl.clear();
        timeCtrl.clear();
        originCtrl.clear();
        itemCtrl.clear();
        qtyCtrl.clear();
        ownerCtrl.clear();
        receiverCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dokumen masuk tersimpan."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal menyimpan: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    dayCtrl.dispose();
    timeCtrl.dispose();
    originCtrl.dispose();
    itemCtrl.dispose();
    qtyCtrl.dispose();
    ownerCtrl.dispose();
    receiverCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    dokumenStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AppDrawer(currentPage: AppPage.dokumen),
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
                  "Dokumen Masuk",
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              children: [
                _formCard(),
                const SizedBox(height: 24),
                const Text(
                  "Data Dokumen Masuk",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                _dataTable(),
              ],
            ),
          ),
        ],
      ),
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
          _textRow(
            label: "Hari",
            controller: dayCtrl,
            hint: "Contoh: Senin",
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Jam",
            controller: timeCtrl,
            hint: "Contoh: 08:00",
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Asal Barang",
            controller: originCtrl,
            hint: "Contoh: Vendor A",
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Nama Barang",
            controller: itemCtrl,
            hint: "Contoh: Dokumen",
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Jumlah",
            controller: qtyCtrl,
            hint: "Contoh: 2",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Atas Nama",
            controller: ownerCtrl,
            hint: "Contoh: PT ABC",
          ),
          const SizedBox(height: 12),
          _textRow(
            label: "Penerima",
            controller: receiverCtrl,
            hint: "Contoh: Candra",
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting || !_canSubmit() ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5AA5),
                disabledBackgroundColor: const Color(0xFF9DBCE6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
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

  Widget _textRow({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            keyboardType: keyboardType,
            decoration: InputDecoration(hintText: hint),
          ),
        ),
      ],
    );
  }

  Widget _dataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder<List<DokumenEntry>>(
        valueListenable: dokumenStore.entries,
        builder: (context, items, _) {
          return DataTable(
            columnSpacing: 16,
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
            rows: items.isEmpty
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
                : items.asMap().entries.map((entry) {
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
        dayCtrl.text.trim().isNotEmpty &&
        timeCtrl.text.trim().isNotEmpty &&
        originCtrl.text.trim().isNotEmpty &&
        itemCtrl.text.trim().isNotEmpty &&
        qtyCtrl.text.trim().isNotEmpty &&
        ownerCtrl.text.trim().isNotEmpty &&
        receiverCtrl.text.trim().isNotEmpty;
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
}
