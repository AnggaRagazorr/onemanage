import 'package:flutter/material.dart';
import '../../services/auth_service.dart'; // To get current user
import 'patrol_store.dart';

class PatrolConditionFormPage extends StatefulWidget {
  const PatrolConditionFormPage({super.key});

  @override
  State<PatrolConditionFormPage> createState() => _PatrolConditionFormPageState();
}

class _PatrolConditionFormPageState extends State<PatrolConditionFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _timeController = TextEditingController();
  final _situasiController = TextEditingController();
  final _aghtController = TextEditingController(); // Ancaman, Gangguan, Hambatan, Tantangan
  final _cuacaController = TextEditingController();
  final _pdamController = TextEditingController();
  final _wfoController = TextEditingController();
  final _tambahanController = TextEditingController();

  // State
  late DateTime _currentDate;
  String _currentUser = "Loading...";
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now();
    _loadUser();
    
    // Set default time to current time
    final hour = _currentDate.hour.toString().padLeft(2, '0');
    final minute = _currentDate.minute.toString().padLeft(2, '0');
    _timeController.text = "$hour:$minute";
  }

  Future<void> _loadUser() async {
    final name = await AuthService.instance.getName();
    if (name != null) {
      setState(() {
        _currentUser = name;
      });
    } else {
      setState(() {
        _currentUser = "User (Unknown)";
      });
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _situasiController.dispose();
    _aghtController.dispose();
    _cuacaController.dispose();
    _pdamController.dispose();
    _wfoController.dispose();
    _tambahanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Isi Kondisi Patroli"),
        backgroundColor: const Color(0xFF0D5AA5),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadOnlyField("Hari dan Tanggal", _formatDate(_currentDate)),
              const SizedBox(height: 16),
              _buildTimeField(),
              const SizedBox(height: 16),
              _buildTextField("Situasi", _situasiController, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField("AGHT", _aghtController, maxLines: 2, hint: "Ancaman, Gangguan, Hambatan, Tantangan"),
              const SizedBox(height: 16),
              _buildTextField("Cuaca", _cuacaController, hint: "Cerah / Hujan / Mendung"),
              const SizedBox(height: 16),
              _buildTextField("PDAM (Meteran)", _pdamController, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField("Personel WFO", _wfoController, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField("Personel Tambahan", _tambahanController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 24),
              // Petugas On Duty Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(Icons.security, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Petugas On Duty", style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                        Text(_currentUser, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0C4A6E))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5AA5),
                    disabledBackgroundColor: const Color(0xFF9DBCE6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      : const Text("Kirim Laporan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, color: Color(0xFF1F2937))),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (val) => val == null || val.isEmpty ? "Wajib diisi" : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D5AA5), width: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Pukul", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 8),
        TextFormField(
          controller: _timeController,
          readOnly: true, // Prevent manual typing to enforce picker usage or format
          onTap: () async {
            final now = TimeOfDay.now();
            final picked = await showTimePicker(context: context, initialTime: now);
            if (picked != null) {
              final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
              _timeController.text = formatted;
            }
          },
          decoration: InputDecoration(
            suffixIcon: const Icon(Icons.access_time, color: Color(0xFF6B7280)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const days = ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"];
    const months = ["Januari", "Februari", "Maret", "April", "Mei", "Juni", "Juli", "Agustus", "September", "oktober", "November", "Desember"];
    final dayName = days[date.weekday - 1];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    return "$dayName, $day $month $year";
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      
      // Create Report Object
      final report = PatrolConditionReport(
        date: DateTime.now(),
        time: _timeController.text,
        situasi: _situasiController.text,
        aght: _aghtController.text,
        cuaca: _cuacaController.text,
        pdam: _pdamController.text,
        wfo: int.tryParse(_wfoController.text) ?? 0,
        tambahan: int.tryParse(_tambahanController.text) ?? 0,
        officer: _currentUser,
      );

      try {
        await patrolStore.createConditionReport(report);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan kondisi berhasil dikirim!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengirim laporan kondisi."), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}
