import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/models/app_user.dart';
import 'approvals_screen.dart';

final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.watchAllUsers();
});

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: const UsersScreenBody(),
    );
  }
}

class UsersScreenBody extends ConsumerStatefulWidget {
  const UsersScreenBody({super.key});

  @override
  ConsumerState<UsersScreenBody> createState() => _UsersScreenBodyState();
}

class _UsersScreenBodyState extends ConsumerState<UsersScreenBody> {
  String _searchQuery = '';

  void _showEditUserDialog(AppUser user) {
    String selectedRole = user.role;
    String selectedStatus = user.status;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Manage ${user.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: ${user.email}'),
              const SizedBox(height: 16),
              const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedRole,
                isExpanded: true,
                items: [
                  UserRoles.owner,
                  UserRoles.driver,
                  UserRoles.pending,
                  UserRoles.superAdmin,
                ].map((role) {
                  return DropdownMenuItem(value: role, child: Text(role.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedRole = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: selectedStatus,
                isExpanded: true,
                items: [
                  UserStatuses.active,
                  UserStatuses.pending,
                  UserStatuses.rejected,
                  UserStatuses.disabled,
                ].map((status) {
                  return DropdownMenuItem(value: status, child: Text(status.toUpperCase()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedStatus = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await ref.read(adminRepositoryProvider).updateUserRoleAndStatus(
                    uid: user.uid,
                    role: selectedRole,
                    status: selectedStatus,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Updated ${user.name}')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name, email or phone...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const LoadingView(message: 'Loading users...'),
            error: (err, _) => ErrorView(
              message: err.toString(),
              onRetry: () => ref.invalidate(allUsersProvider),
            ),
            data: (users) {
              final filteredUsers = users.where((u) {
                if (_searchQuery.isEmpty) return true;
                final matchName = u.name.toLowerCase().contains(_searchQuery);
                final matchEmail = u.email.toLowerCase().contains(_searchQuery);
                final matchPhone = u.phone.toLowerCase().contains(_searchQuery);
                return matchName || matchEmail || matchPhone;
              }).toList();

              if (filteredUsers.isEmpty) {
                return const EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: 'No users found',
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredUsers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final user = filteredUsers[idx];
                  final isSuperAdmin = user.role == UserRoles.superAdmin;

                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U'),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('${user.email}\nPhone: ${user.phone.isNotEmpty ? user.phone : "N/A"}'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(
                            status: isSuperAdmin ? 'Reserved' : 'Available',
                            label: user.role.toUpperCase(),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            status: user.status == UserStatuses.active ? 'Available' : 'Cancelled',
                            label: user.status.toUpperCase(),
                          ),
                        ],
                      ),
                      onTap: () => _showEditUserDialog(user),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
