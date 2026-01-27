import 'package:flutter/material.dart';
import 'admin_drawer.dart';
import 'admin_carpool_store.dart';
import '../carpool/carpool_history_store.dart';
import '../carpool/carpool_models.dart';
import 'admin_carpool_vehicle_form.dart';
import 'admin_carpool_driver_form.dart';
import 'admin_carpool_history_page.dart';

class AdminCarpoolPage extends StatefulWidget {
  const AdminCarpoolPage({super.key});

  @override
  State<AdminCarpoolPage> createState() => _AdminCarpoolPageState();
}

class _AdminCarpoolPageState extends State<AdminCarpoolPage> {
  @override
  void initState() {
    super.initState();
    adminCarpoolStore.load();
    carpoolHistoryStore.load();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AdminDrawer(currentPage: AdminPage.carpool),
      body: Column(
        children: [
          // Gradient Header
          Container(
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
                  "Kelola Carpool",
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
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              children: [
                _sectionHeader(
                  title: "Daftar Mobil",
                  onAdd: () => _showAddDialog(context, isCar: true),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<AdminCar>>(
                  valueListenable: adminCarpoolStore.cars,
                  builder: (context, cars, _) {
                    if (cars.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("Belum ada mobil.", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: cars.map(_carCard).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                _sectionHeader(
                  title: "Daftar Driver",
                  onAdd: () => _showAddDialog(context, isCar: false),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<AdminDriver>>(
                  valueListenable: adminCarpoolStore.drivers,
                  builder: (context, drivers, _) {
                    if (drivers.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text("Belum ada driver.", style: TextStyle(color: Colors.grey)),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: drivers.map(_driverCard).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                // History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "History Penggunaan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AdminCarpoolHistoryPage()),
                        );
                      },
                      child: const Text("Lihat Semua", style: TextStyle(color: Color(0xFF0D5AA5))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<List<CarpoolHistoryItem>>(
                  valueListenable: carpoolHistoryStore.items,
                  builder: (context, items, _) {
                    if (items.isEmpty) {
                      return const Text("Belum ada history carpool.", style: TextStyle(color: Colors.grey));
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: items.take(5).map((item) => _historyCard(context, item)).toList(),
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

  Widget _sectionHeader({required String title, required VoidCallback onAdd}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, color: Color(0xFF0D5AA5)),
          label: const Text(
            "Tambah",
            style: TextStyle(color: Color(0xFF0D5AA5)),
          ),
        ),
      ],
    );
  }

  Widget _carCard(AdminCar car) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.brand,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  car.plate,
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteCar(car),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            tooltip: "Hapus",
          ),
        ],
      ),
    );
  }

  Widget _driverCard(AdminDriver driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "NIP: ${driver.nip}",
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDeleteDriver(driver),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            tooltip: "Hapus",
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCar(AdminCar car) async {
    if (car.id == null) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Mobil?"),
          content: Text("Mobil ${car.brand} (${car.plate}) akan dihapus."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus", style: TextStyle(color: Color(0xFFDC2626))),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }
    await adminCarpoolStore.deleteCar(car);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Mobil berhasil dihapus.")),
    );
  }

  Future<void> _confirmDeleteDriver(AdminDriver driver) async {
    if (driver.id == null) {
      return;
    }
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus Driver?"),
          content: Text("Driver ${driver.name} (${driver.nip}) akan dihapus."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Hapus", style: TextStyle(color: Color(0xFFDC2626))),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }
    await adminCarpoolStore.deleteDriver(driver);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Driver berhasil dihapus.")),
    );
  }

  Widget _historyCard(BuildContext context, CarpoolHistoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showHistoryDetail(context, item),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.vehicle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${item.destination} • ${item.time}",
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D5AA5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, {required bool isCar}) {
    if (isCar) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCarpoolVehicleFormPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminCarpoolDriverFormPage()),
      );
    }
  }

  void _showHistoryDetail(BuildContext context, CarpoolHistoryItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Detail Carpool"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mobil: ${item.vehicle}"),
              Text("Driver: ${item.driver}"),
              Text("User: ${item.user}"),
              Text("Tujuan: ${item.destination}"),
              Text("Jam Keluar: ${item.time}"),
              Text("Jam Masuk: ${item.endTime ?? "-"}"),
              Text("KM Terakhir: ${item.lastKm ?? "-"}"),
              Text("Status: ${item.status}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}
