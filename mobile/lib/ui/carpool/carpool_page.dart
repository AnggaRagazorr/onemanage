import 'package:flutter/material.dart';
import '../shell/app_drawer.dart';
import 'carpool_history_store.dart';
import 'carpool_models.dart';
import 'carpool_history_page.dart';
import '../dashboard/dashboard_page.dart';
import '../admin/admin_carpool_store.dart';

class CarpoolPage extends StatefulWidget {
  const CarpoolPage({super.key});

  @override
  State<CarpoolPage> createState() => _CarpoolPageState();
}

class _CarpoolPageState extends State<CarpoolPage> {
  bool showForm = false;
  DateTime? selectedDate;
  AdminCar? selectedCar;
  AdminDriver? selectedDriver;
  TimeOfDay? selectedStartTime;
  final TextEditingController userCtrl = TextEditingController();
  final TextEditingController destinationCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    userCtrl.addListener(_handleFormChanged);
    destinationCtrl.addListener(_handleFormChanged);
    adminCarpoolStore.load();
    carpoolHistoryStore.load();
  }

  @override
  void dispose() {
    userCtrl.removeListener(_handleFormChanged);
    destinationCtrl.removeListener(_handleFormChanged);
    userCtrl.dispose();
    destinationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canCreateData = selectedCar != null && selectedDate != null;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AppDrawer(currentPage: AppPage.carpool),
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
                  "Carpool",
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
                Text(
                  showForm ? "Buat Data" : "Buat Data dan Cari History",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                if (!showForm) ...[
                  _selectionCard(
                    title: "Pilih Mobil",
                    value: selectedCar?.display ?? "Mobil",
                    icon: Icons.directions_car_rounded,
                    onTap: _pickCar,
                  ),
                  const SizedBox(height: 12),
                  _selectionCard(
                    title: "Pilih Tanggal",
                    value: _formatDate(selectedDate),
                    icon: Icons.calendar_month,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "History Hari ini",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<List<CarpoolHistoryItem>>(
                    valueListenable: carpoolHistoryStore.items,
                    builder: (context, items, _) {
                      final filtered = _filterHistoryItems(items);
                      return Column(
                        children: filtered.map(_historyCard).toList(),
                      );
                    },
                  ),
                ],
                if (showForm) ...[
                  _selectionCard(
                    title: "Pilih Driver",
                    value: selectedDriver?.display ?? "Driver",
                    icon: Icons.badge_outlined,
                    highlight: true,
                    onTap: _pickDriver,
                  ),
                  const SizedBox(height: 12),
                  _selectionCard(
                    title: "Pilih Jam Keluar",
                    value: _formatTime(selectedStartTime),
                    icon: Icons.calendar_month,
                    onTap: _pickStartTime,
                  ),
                  const SizedBox(height: 12),
                  _inputCard(
                    hint: "Masukkan User",
                    controller: userCtrl,
                    onChanged: (_) => _handleFormChanged(),
                  ),
                  const SizedBox(height: 12),
                  _inputCard(
                    hint: "Masukkan Tujuan",
                    controller: destinationCtrl,
                    onChanged: (_) => _handleFormChanged(),
                  ),
                  const SizedBox(height: 12),
                  _selectionCard(
                    title: "Pilih Jam Masuk",
                    value: "12:00",
                    icon: Icons.calendar_month,
                    enabled: false,
                  ),
                  const SizedBox(height: 12),
                  _inputCard(
                    hint: "Masukkan KM Terakhir Mobil",
                    enabled: false,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomActions(canCreateData: canCreateData),
    );
  }

  Widget _selectionCard({
    required String title,
    required String value,
    required IconData icon,
    bool highlight = false,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight && enabled ? const Color(0xFF0D5AA5) : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: enabled ? Colors.black.withOpacity(0.06) : Colors.transparent,
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
                  color: enabled ? const Color(0xFFE8F0FE) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: enabled ? const Color(0xFF0D5AA5) : const Color(0xFF9CA3AF),
                ),
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
              Icon(
                Icons.arrow_drop_down,
                color: enabled ? const Color(0xFF0D5AA5) : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputCard({
    required String hint,
    bool enabled = true,
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: enabled ? Colors.black.withOpacity(0.06) : Colors.transparent,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: enabled ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
            fontSize: 15,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _historyCard(CarpoolHistoryItem item) {
    final status = item.status;
    final statusStyle = _statusStyle(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleHistoryTap(item),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.site,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.vehicle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 6),
                      Text(
                        item.time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D5AA5),
                        ),
                      ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: Color(0xFF0D5AA5)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusStyle.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusStyle.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case "Done":
        return const _StatusStyle(
          background: Color(0xFFE8F0FE),
          foreground: Color(0xFF0D5AA5),
        );
      case "In Progress":
        return const _StatusStyle(
          background: Color(0xFFDCEBFF),
          foreground: Color(0xFF0B4A86),
        );
      default:
        return const _StatusStyle(
          background: Color(0xFFE8F0FE),
          foreground: Color(0xFF1E88E5),
        );
    }
  }

  Widget _bottomActions({required bool canCreateData}) {
    final canSubmit = showForm &&
        selectedDriver != null &&
        selectedStartTime != null &&
        userCtrl.text.trim().isNotEmpty &&
        destinationCtrl.text.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(
              label: showForm ? "Back" : "History",
              onPressed: showForm
                  ? () {
                      setState(() => showForm = false);
                    }
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CarpoolHistoryPage()),
                      );
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _actionButton(
              label: showForm ? "Submit" : "Buat Data",
              isLoading: showForm && _isSubmitting,
              onPressed: showForm
                  ? (canSubmit && !_isSubmitting ? () => _submitDummy() : null)
                  : (canCreateData
                      ? () {
                          setState(() => showForm = true);
                        }
                      : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback? onPressed, bool isLoading = false}) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D5AA5),
          disabledBackgroundColor: const Color(0xFF9DBCE6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  List<CarpoolHistoryItem> _filterHistoryItems(List<CarpoolHistoryItem> items) {
    final target = selectedDate ?? DateTime.now();
    return items.where((item) => _isSameDay(item.date, target)).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return "Pilih tanggal";
    }
    final day = date.day.toString().padLeft(2, '0');
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final month = months[date.month - 1];
    return "$day $month, ${date.year}";
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) {
      return "Pilih jam";
    }
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  Future<void> _pickCar() async {
    final cars = adminCarpoolStore.cars.value;
    final inProgressVehicles = carpoolHistoryStore.items.value
        .where((item) => item.status == "In Progress")
        .map((item) => item.vehicle)
        .toSet();
    final options = cars.map((car) => car.display).toList();
    final picked = await _showPicker(
      title: "Pilih Mobil",
      options: options,
      currentValue: selectedCar?.display,
      disabledOptions: inProgressVehicles,
    );
    if (picked != null) {
      final selected = cars.firstWhere((car) => car.display == picked);
      setState(() => selectedCar = selected);
    }
  }

  Future<void> _pickDriver() async {
    final drivers = adminCarpoolStore.drivers.value;
    final options = drivers.map((driver) => driver.display).toList();
    final picked = await _showPicker(
      title: "Pilih Driver",
      options: options,
      currentValue: selectedDriver?.display,
    );
    if (picked != null) {
      final selected = drivers.firstWhere((driver) => driver.display == picked);
      setState(() => selectedDriver = selected);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedStartTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => selectedStartTime = picked);
    }
  }

  Future<String?> _showPicker({
    required String title,
    required List<String> options,
    required String? currentValue,
    Set<String> disabledOptions = const {},
  }) {
    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...options.map((option) {
                final isDisabled = disabledOptions.contains(option);
                return ListTile(
                  title: Text(
                    option,
                    style: TextStyle(
                      color: isDisabled ? const Color(0xFF9CA3AF) : const Color(0xFF111827),
                    ),
                  ),
                  subtitle: isDisabled
                      ? const Text(
                          "In Progress",
                          style: TextStyle(color: Color(0xFF9CA3AF)),
                        )
                      : null,
                  trailing: currentValue == option
                      ? const Icon(Icons.check, color: Color(0xFF0D5AA5))
                      : null,
                  onTap: isDisabled ? null : () => Navigator.pop(context, option),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  bool _isSubmitting = false;

  Future<void> _submitDummy() async {
    setState(() => _isSubmitting = true);
    
    final newItem = CarpoolHistoryItem(
      vehicleId: selectedCar?.id ?? 0,
      driverId: selectedDriver?.id,
      site: destinationCtrl.text.trim().isEmpty ? "Tujuan belum diisi" : destinationCtrl.text.trim(),
      vehicle: selectedCar?.display ?? "-",
      time: _formatTime(selectedStartTime),
      status: "In Progress",
      driver: selectedDriver?.display ?? "-",
      user: userCtrl.text.trim().isEmpty ? "-" : userCtrl.text.trim(),
      destination: destinationCtrl.text.trim().isEmpty ? "-" : destinationCtrl.text.trim(),
      date: selectedDate ?? DateTime.now(),
    );

    try {
      await carpoolHistoryStore.addItem(newItem);
      if (!mounted) return;
      setState(() {
        showForm = false;
        selectedCar = null;
        selectedDriver = null;
        selectedStartTime = null;
        selectedDate = null;
        userCtrl.clear();
        destinationCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Data carpool masuk ke history (In Progress)."), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleFormChanged() {
    if (showForm) {
      setState(() {});
    }
  }

  void _handleHistoryTap(CarpoolHistoryItem item) {
    if (item.status == "Done") {
      _showDoneDetails(item);
      return;
    }
    if (item.status == "In Progress") {
      _showCompleteForm(item);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Data belum dimulai.")),
    );
  }

  void _showDoneDetails(CarpoolHistoryItem item) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Detail Carpool"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Site: ${item.site}"),
              Text("Mobil: ${item.vehicle}"),
              Text("Driver: ${item.driver}"),
              Text("User: ${item.user}"),
              Text("Tujuan: ${item.destination}"),
              Text("Jam Keluar: ${item.time}"),
              Text("Jam Masuk: ${item.endTime ?? "-"}"),
              Text("KM Terakhir: ${item.lastKm ?? "-"}"),
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

  Future<void> _showCompleteForm(CarpoolHistoryItem item) async {
    final endTimeCtrl = TextEditingController(text: item.endTime ?? "");
    final kmCtrl = TextEditingController(text: item.lastKm ?? "");
    final result = await showModalBottomSheet<CarpoolHistoryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Lengkapi Data",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text("Mobil: ${item.vehicle}"),
              const SizedBox(height: 12),
              TextField(
                controller: endTimeCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Jam Masuk",
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (picked != null) {
                    final hour = picked.hour.toString().padLeft(2, '0');
                    final minute = picked.minute.toString().padLeft(2, '0');
                    endTimeCtrl.text = "$hour:$minute";
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: kmCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "KM Terakhir Mobil",
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (endTimeCtrl.text.trim().isEmpty || kmCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Lengkapi jam masuk dan KM.")),
                      );
                      return;
                    }
                    Navigator.pop(
                      context,
                      item.copyWith(
                        status: "Done",
                        endTime: endTimeCtrl.text.trim(),
                        lastKm: kmCtrl.text.trim(),
                      ),
                    );
                  },
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await carpoolHistoryStore.updateItem(result);
    }
  }
}

class _StatusStyle {
  const _StatusStyle({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
