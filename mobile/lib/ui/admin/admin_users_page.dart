import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'admin_drawer.dart';
import 'admin_users_store.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  @override
  void initState() {
    super.initState();
    adminUsersStore.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      endDrawer: const AdminDrawer(currentPage: AdminPage.users),
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
                  "Kelola User",
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
            child: ValueListenableBuilder<List<AdminUser>>(
              valueListenable: adminUsersStore.users,
              builder: (context, users, _) {
                if (users.isEmpty) {
                  return const Center(child: Text("Belum ada user."));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final roleLabel = _roleLabel(user.role);
                    final isAdmin = user.role == 'admin';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.person, color: Color(0xFF0D5AA5), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (user.username.isNotEmpty)
                                  Text(
                                    user.username,
                                    style: const TextStyle(color: Color(0xFF6B7280)),
                                  ),
                                if (user.email.isNotEmpty)
                                  Text(
                                    user.email,
                                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                                  ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    roleLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isAdmin ? const Color(0xFFD97706) : const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert),
                            color: const Color(0xFF9CA3AF),
                            onPressed: () => _showUserActions(context, user),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUserDialog(context),
        backgroundColor: const Color(0xFF0D5AA5),
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          "Tambah User",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showUserActions(BuildContext context, AdminUser user) {
    final rootContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final roleLabel = _roleLabel(user.role);
        final isAdmin = user.role == 'admin';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF0D5AA5), size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAdmin ? const Color(0xFFD97706) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _detailRow("Username", user.username),
                const SizedBox(height: 8),
                _detailRow("Email", user.email),
                const SizedBox(height: 8),
                _detailRow("Role", roleLabel),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditUserDialog(rootContext, user);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D5AA5),
                          side: const BorderSide(color: Color(0xFF0D5AA5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Ubah Data"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(rootContext, user);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Hapus Akun"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final rootContext = context;
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role = 'security';
    bool obscure = true;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Tambah User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: "Username"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: "Password",
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: "security", child: Text("Security")),
                        DropdownMenuItem(value: "admin", child: Text("Admin")),
                      ],
                      onChanged: (value) => role = value ?? "security",
                      decoration: const InputDecoration(labelText: "Role"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text.trim();
                    if (name.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text("Lengkapi semua field.")),
                      );
                      return;
                    }
                    try {
                      final created = await adminUsersStore.create(
                        name: name,
                        username: username,
                        email: email,
                        password: password,
                        role: role,
                      );
                      if (!mounted) {
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text("User ${created.name} dibuat.")),
                      );
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text(_errorMessage(error, fallback: "Gagal membuat user."))),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, AdminUser user) {
    final rootContext = context;
    final nameCtrl = TextEditingController(text: user.name);
    final usernameCtrl = TextEditingController(text: user.username);
    final emailCtrl = TextEditingController(text: user.email);
    final passwordCtrl = TextEditingController();
    String role = user.role.isEmpty ? 'security' : user.role;
    bool obscure = true;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Ubah User"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameCtrl,
                      decoration: const InputDecoration(labelText: "Username"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        labelText: "Password (opsional)",
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: "security", child: Text("Security")),
                        DropdownMenuItem(value: "admin", child: Text("Admin")),
                      ],
                      onChanged: (value) => role = value ?? "security",
                      decoration: const InputDecoration(labelText: "Role"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final username = usernameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text.trim();
                    if (name.isEmpty || username.isEmpty || email.isEmpty) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text("Lengkapi semua field wajib.")),
                      );
                      return;
                    }
                    if (user.id == null) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text("User tidak memiliki id.")),
                      );
                      return;
                    }
                    try {
                      final updated = await adminUsersStore.update(
                        id: user.id!,
                        name: name,
                        username: username,
                        email: email,
                        password: password.isEmpty ? null : password,
                        role: role,
                      );
                      if (!mounted) {
                        return;
                      }
                      Navigator.pop(context);
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text("User ${updated.name} diperbarui.")),
                      );
                    } catch (error) {
                      if (!mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        SnackBar(content: Text(_errorMessage(error, fallback: "Gagal memperbarui user."))),
                      );
                    }
                  },
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, AdminUser user) {
    final rootContext = context;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Hapus User"),
          content: Text("Hapus akun ${user.name}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () async {
                if (user.id == null) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    const SnackBar(content: Text("User tidak memiliki id.")),
                  );
                  Navigator.pop(context);
                  return;
                }
                try {
                  await adminUsersStore.delete(user.id!);
                  if (!mounted) {
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text("User ${user.name} dihapus.")),
                  );
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(content: Text(_errorMessage(error, fallback: "Gagal menghapus user."))),
                  );
                }
              },
              child: const Text(
                "Hapus",
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    final display = value.isEmpty ? "-" : value;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ),
        const Text(": ", style: TextStyle(color: Color(0xFF9CA3AF))),
        Expanded(
          child: Text(
            display,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
        ),
      ],
    );
  }

  String _errorMessage(Object error, {required String fallback}) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty && first.first is String) {
            return first.first as String;
          }
          if (first is String) {
            return first;
          }
        }
        final message = data['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
      }
      if (statusCode == 401) {
        return "Sesi login habis. Silakan login ulang.";
      }
      if (statusCode == 403) {
        return "Akses ditolak.";
      }
    }
    return fallback;
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'security':
        return 'Security';
      default:
        if (role.isEmpty) {
          return 'Security';
        }
        return role[0].toUpperCase() + role.substring(1);
    }
  }
}
