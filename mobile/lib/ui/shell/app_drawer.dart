import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../../services/auth_service.dart';
import '../dashboard/dashboard_page.dart';
import '../patrol/patrol_page.dart';
import '../rekap/rekap_page.dart';
import '../carpool/carpool_page.dart';
import '../dokumen/dokumen_page.dart';

enum AppPage {
  dashboard,
  patrol,
  rekap,
  carpool,
  dokumen,
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, required this.currentPage});

  final AppPage currentPage;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _name = 'Loading...';
  String _email = 'Loading...';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await AuthService.instance.getName();
    final email = await AuthService.instance.getEmail();
    final role = await AuthService.instance.getRole();
    if (mounted) {
      setState(() {
        _name = name ?? 'User';
        _email = email ?? '';
        _role = role ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Premium Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D5AA5), Color(0xFF003377)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 36,
                        color: Color(0xFF0D5AA5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _role.toUpperCase(), // Display Role
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    targetPage: AppPage.dashboard,
                  ),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    context,
                    icon: Icons.shield_rounded,
                    title: 'Patroli',
                    targetPage: AppPage.patrol,
                  ),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    context,
                    icon: Icons.receipt_long_rounded, // Changed Icon
                    title: 'Rekap Harian',
                    targetPage: AppPage.rekap,
                  ),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    context,
                    icon: Icons.directions_car_rounded,
                    title: 'Carpool',
                    targetPage: AppPage.carpool,
                  ),
                  const SizedBox(height: 4),
                  _buildMenuItem(
                    context,
                    icon: Icons.folder_shared_rounded, // Changed Icon
                    title: 'Dokumen Masuk',
                    targetPage: AppPage.dokumen,
                  ),
                ],
              ),
            ),
            
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required AppPage targetPage,
  }) {
    final isActive = widget.currentPage == targetPage;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => _handleNavigation(context, targetPage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: isActive ? const Color(0xFFEFF6FF) : Colors.transparent,
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF0D5AA5) : const Color(0xFF6B7280),
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF0D5AA5) : const Color(0xFF374151),
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  void _handleNavigation(BuildContext context, AppPage targetPage) {
    if (targetPage == widget.currentPage) {
      Navigator.pop(context);
      return;
    }

    Navigator.pop(context);

    Widget nextPage;
    switch (targetPage) {
      case AppPage.dashboard:
        nextPage = const DashboardPage();
        break;
      case AppPage.patrol:
        nextPage = const PatrolPage();
        break;
      case AppPage.rekap:
        nextPage = const RekapPage();
        break;
      case AppPage.carpool:
        nextPage = const CarpoolPage();
        break;
      case AppPage.dokumen:
        nextPage = const DokumenPage();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final rootContext = context;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(rootContext);
                Navigator.pushAndRemoveUntil(
                  rootContext,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
