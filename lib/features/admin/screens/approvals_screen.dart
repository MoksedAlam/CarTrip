import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/models/app_user.dart';
import '../data/admin_repository.dart';
import 'admin_fleet_screen.dart';
import 'users_screen.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

final pendingRegistrationsProvider = StreamProvider<List<AppUser>>((ref) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.watchPendingRegistrations();
});

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove(BuildContext context, AppUser user) async {
    try {
      await ref.read(adminRepositoryProvider).approveOwner(user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} approved as Owner')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    }
  }

  Future<void> _handleReject(BuildContext context, AppUser user) async {
    final reasonController = TextEditingController();
    final shouldReject = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject ${user.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete or invalid documents',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (shouldReject == true && context.mounted) {
      try {
        await ref.read(adminRepositoryProvider).rejectRegistration(
          user.uid,
          reasonController.text.trim().isNotEmpty
              ? reasonController.text.trim()
              : 'Registration details could not be verified.',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} rejected')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reject: $e')),
          );
        }
      }
    }
  }

  Widget _buildApprovalsTab() {
    final pendingAsync = ref.watch(pendingRegistrationsProvider);
    final theme = Theme.of(context);

    return pendingAsync.when(
      loading: () => const LoadingView(message: 'Loading pending requests...'),
      error: (err, _) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(pendingRegistrationsProvider),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'No Pending Approvals',
            description: 'All submitted partner registrations have been processed.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (ctx, idx) {
            final user = users[idx];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Full Name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name.isNotEmpty ? user.name : 'Unknown Name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Role: ${user.role.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade700),
                          ),
                          child: const Text(
                            'PENDING',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Registration Details
                    _buildInfoRow(context, Icons.phone_outlined, 'Mobile', user.phone.isNotEmpty ? user.phone : 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, Icons.email_outlined, 'Email', user.email.isNotEmpty ? user.email : 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow(context, Icons.location_on_outlined, 'Area/City', user.area.isNotEmpty ? user.area : 'N/A'),
                    if (user.upiId != null && user.upiId!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(context, Icons.qr_code_rounded, 'UPI ID', user.upiId!),
                    ],
                    if (user.declarationAt != null) ...[
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        Icons.calendar_today_outlined,
                        'Submitted On',
                        Formatters.dateTime(user.declarationAt),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton.outlined(
                            label: 'Reject',
                            icon: Icons.close_rounded,
                            onPressed: () => _handleReject(context, user),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            label: 'Approve',
                            icon: Icons.check_circle_rounded,
                            onPressed: () => _handleApprove(context, user),
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
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingRegistrationsProvider).value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/owner/home');
            }
          },
        ),
        title: const Text('Super Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Approvals'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Users'),
            const Tab(text: 'Fleet'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsTab(),
          const UsersView(),
          const AdminFleetView(),
        ],
      ),
    );
  }
}

// Exportable embedded view for Users tab
class UsersView extends ConsumerWidget {
  const UsersView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const UsersScreenBody();
  }
}

// Exportable embedded view for Fleet tab
class AdminFleetView extends ConsumerWidget {
  const AdminFleetView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AdminFleetScreenBody();
  }
}
