import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../shell/app_drawer.dart';
import '../carpool/carpool_history_page.dart';
import 'shift_store.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _name = 'Loading...';
  String _role = '';
  
  // Stats
  int _patrolToday = 0;
  int _patrolTarget = 3;
  int _rekapCount = 0;
  int _carpoolAvailable = 0;
  int _carpoolTotal = 0;
  int _dokumenCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserData(),
      _loadDashboardStats(),
      shiftStore.loadCurrent(),
    ]);
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.instance.getName();
    final role = await AuthService.instance.getRole();
    if (mounted) {
      setState(() {
        _name = name ?? 'User';
        _role = role ?? '';
      });
    }
  }

  Future<void> _loadDashboardStats() async {
    try {
      final response = await ApiClient.instance.get('/dashboard');
      final data = response.data;
      if (mounted) {
        setState(() {
          _patrolToday = data['patrol_today'] ?? 0;
          _patrolTarget = data['patrol_target'] ?? 3;
          _rekapCount = data['rekap_today'] ?? 0;
          _carpoolAvailable = data['carpool_available'] ?? 0;
          _carpoolTotal = data['carpool_total'] ?? 0;
          _dokumenCount = data['dokumen_today'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openEndDrawer(),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.security, color: Colors.white, size: 24),
                            SizedBox(width: 8),
                            Text(
                              "SEKURITI",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        // Placeholder for symmetry
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 32, color: Color(0xFF0D5AA5)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat Datang,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                _role,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Shift Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildShiftCard(),
              ),

              const SizedBox(height: 24),

              // Cards Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                       'Highlight Hari Ini',
                       style: TextStyle(
                         fontSize: 18,
                         fontWeight: FontWeight.bold,
                         color: Color(0xFF1F2937),
                       ),
                    ),
                    const SizedBox(height: 16),
                    // Patroli Hari Ini Card
                    _buildCard(
                      title: 'Patroli',
                      icon: Icons.shield,
                      value: '$_patrolToday/$_patrolTarget',
                      subtitle: 'Target hari ini',
                      color: const Color(0xFF0D5AA5),
                      isPrimary: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildCard(
                            title: 'Kejadian',
                            icon: Icons.notifications_active,
                            value: '$_rekapCount',
                            subtitle: 'Laporan',
                            color: const Color(0xFFD32F2F),
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildCard(
                            title: 'Dokumen',
                            icon: Icons.folder,
                            value: '$_dokumenCount',
                            subtitle: 'Masuk',
                            color: const Color(0xFFFB8C00),
                            compact: true,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Carpool Card
                    _buildCard(
                      title: 'Carpool',
                      icon: Icons.directions_car,
                      value: '$_carpoolAvailable',
                      subtitle: 'Dari $_carpoolTotal unit tersedia',
                      color: const Color(0xFF1976D2),
                      actionLabel: 'Lihat History',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CarpoolHistoryPage()),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: const AppDrawer(currentPage: AppPage.dashboard),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String value,
    required String subtitle,
    required Color color,
    String? actionLabel,
    VoidCallback? onAction,
    bool isPrimary = false,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: compact ? 20 : 24),
              ),
              if (!compact && actionLabel != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    backgroundColor: color.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    actionLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: compact ? 12 : 20),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 24 : 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: shiftStore.isLoading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: shiftStore.isActive,
          builder: (context, isActive, _) {
            return ValueListenableBuilder<ShiftInfo?>(
              valueListenable: shiftStore.currentShift,
              builder: (context, shift, _) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF6B7280), const Color(0xFF4B5563)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280))
                            .withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.white : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isActive ? 'Shift Aktif' : 'Tidak Ada Shift Aktif',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (isActive && shift != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Shift ${shift.shiftType == 'pagi' ? 'Pagi' : 'Malam'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Mulai: ${_formatTime(shift.clockIn)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _handleClockOut(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFDC2626),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text(
                                    'Selesai Shift',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildShiftButton('pagi', 'Shift Pagi', isLoading),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildShiftButton('malam', 'Shift Malam', isLoading),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildShiftButton(String type, String label, bool isLoading) {
    return ElevatedButton(
      onPressed: isLoading ? null : () => _handleClockIn(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D5AA5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
    );
  }

  Future<void> _handleClockIn(String shiftType) async {
    final success = await shiftStore.clockIn(shiftType);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shift ${shiftType == 'pagi' ? 'Pagi' : 'Malam'} dimulai!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleClockOut() async {
    final success = await shiftStore.clockOut();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift selesai!'),
          backgroundColor: Color(0xFF0D5AA5),
        ),
      );
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}
