import 'package:flutter/material.dart';
import 'admin_carpool_store.dart';

class AdminCarpoolDriverFormPage extends StatefulWidget {
  const AdminCarpoolDriverFormPage({super.key});

  @override
  State<AdminCarpoolDriverFormPage> createState() => _AdminCarpoolDriverFormPageState();
}

class _AdminCarpoolDriverFormPageState extends State<AdminCarpoolDriverFormPage> {
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController nipCtrl = TextEditingController();
  bool isSaving = false;

  @override
  void dispose() {
    nameCtrl.dispose();
    nipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Driver"),
        backgroundColor: const Color(0xFF0D5AA5),
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          _inputField(label: "Nama Driver", controller: nameCtrl),
          const SizedBox(height: 12),
          _inputField(label: "NIP Driver", controller: nipCtrl),
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
    return nameCtrl.text.trim().isNotEmpty && nipCtrl.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    setState(() => isSaving = true);
    await adminCarpoolStore.addDriver(
      AdminDriver(
        name: nameCtrl.text.trim(),
        nip: nipCtrl.text.trim(),
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
