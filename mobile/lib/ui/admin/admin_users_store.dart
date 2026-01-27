import 'package:flutter/material.dart';
import '../../services/admin_user_service.dart';

class AdminUser {
  AdminUser({
    this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
  });

  final int? id;
  final String name;
  final String username;
  final String email;
  final String role;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as int?,
      name: (json['name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'security',
    );
  }
}

class AdminUsersStore {
  final ValueNotifier<List<AdminUser>> users;

  AdminUsersStore(List<AdminUser> initial)
      : users = ValueNotifier<List<AdminUser>>(List<AdminUser>.from(initial));

  Future<void> load() async {
    final service = AdminUserService.instance;
    users.value = await service.fetchUsers();
  }

  Future<AdminUser> create({
    required String name,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final service = AdminUserService.instance;
    final created = await service.createUser(
      name: name,
      username: username,
      email: email,
      password: password,
      role: role,
    );
    users.value = [created, ...users.value];
    return created;
  }

  Future<AdminUser> update({
    required int id,
    required String name,
    required String username,
    required String email,
    String? password,
    required String role,
  }) async {
    final service = AdminUserService.instance;
    final updated = await service.updateUser(
      id: id,
      name: name,
      username: username,
      email: email,
      password: password,
      role: role,
    );
    final items = List<AdminUser>.from(users.value);
    final index = items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      items[index] = updated;
    } else {
      items.insert(0, updated);
    }
    users.value = items;
    return updated;
  }

  Future<void> delete(int id) async {
    final service = AdminUserService.instance;
    await service.deleteUser(id);
    users.value = users.value.where((item) => item.id != id).toList();
  }
}

final adminUsersStore = AdminUsersStore([]);
