import 'package:flutter/material.dart';
import 'admin_carpool_store.dart';

class AdminCarpoolVehicleFormPage extends StatefulWidget {
  const AdminCarpoolVehicleFormPage({super.key});

  @override
  State<AdminCarpoolVehicleFormPage> createState() => _AdminCarpoolVehicleFormPageState();
}

class _AdminCarpoolVehicleFormPageState extends State<AdminCarpoolVehicleFormPage> {
  final TextEditingController brandCtrl = TextEditingController();
  final TextEditingController plateCtrl = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    brandCtrl.dispose();
    plateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Mobil"),
        backgroundColor: const Color(0xFF0D5AA5),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          _inputField(label: "Merk Mobil", controller: brandCtrl),
          const SizedBox(height: 12),
          _inputField(label: "Nomor Polisi", controller: plateCtrl),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _canSubmit() && !isSaving ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5AA5),
                disabledBackgroundColor: const Color(0xFF9DBCE6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Simpan",
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

  Widget _inputField({required String label, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(labelText: label),
    );
  }

  bool _canSubmit() {
    return brandCtrl.text.trim().isNotEmpty && plateCtrl.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    setState(() => isSaving = true);
    await adminCarpoolStore.addCar(
      AdminCar(
        brand: brandCtrl.text.trim(),
        plate: plateCtrl.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
