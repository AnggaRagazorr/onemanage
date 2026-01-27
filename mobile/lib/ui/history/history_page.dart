import 'package:flutter/material.dart';
import '../../mock/mock_data.dart';
import '../../widgets/section_title.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = MockData.history();

    return Scaffold(
      appBar: AppBar(title: const Text("Riwayat Patroli")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle("Riwayat"),
          if (items.isEmpty)
            const Card(
              child: ListTile(
                title: Text("Belum ada data."),
                subtitle: Text("Data akan muncul setelah security melakukan patroli."),
              ),
            ),
          ...items.map((p) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text(p.areaCode, style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text("${p.status} • ${p.time}"),
                ),
              )),
        ],
      ),
    );
  }
}
