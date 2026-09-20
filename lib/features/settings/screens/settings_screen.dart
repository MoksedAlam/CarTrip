import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../auth/providers/auth_providers.dart';
import '../../updater/providers/update_providers.dart';
import '../../updater/widgets/update_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeControllerProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('System Default'),
              leading: Icon(
                currentTheme == ThemeMode.system
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setThemeMode(ThemeMode.system);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Light'),
              leading: Icon(
                currentTheme == ThemeMode.light
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setThemeMode(ThemeMode.light);
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Icon(
                currentTheme == ThemeMode.dark
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                ref.read(themeControllerProvider.notifier).setThemeMode(ThemeMode.dark);
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleClearLocalData(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Clear Local Data',
      content: 'This will reset your local app settings on this device. Cloud data will remain safe.',
      confirmLabel: 'Clear',
      isDestructive: false,
    );

    if (confirmed) {
      await ref.read(localPrefsProvider).clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local data cleared.')),
        );
      }
    }
  }

  Future<void> _handleCheckUpdate(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checking for updates...'),
        duration: Duration(seconds: 1),
      ),
    );
    final service = ref.read(updateServiceProvider);
    final update = await service.checkForUpdate();
    if (!context.mounted) return;

    if (update != null && update.hasUpdate) {
      UpdateDialog.show(
        context,
        updateInfo: update,
        updateService: service,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FleetBoard is up to date!')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserDocProvider);
    final user = userAsync.value;
    final themeMode = ref.watch(themeControllerProvider);

    String themeModeLabel;
    switch (themeMode) {
      case ThemeMode.light:
        themeModeLabel = 'Light';
        break;
      case ThemeMode.dark:
        themeModeLabel = 'Dark';
        break;
      case ThemeMode.system:
        themeModeLabel = 'System';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Profile card
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${user.email}\nRole: ${user.role.toUpperCase()}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/settings/profile'),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (user?.role == UserRoles.superAdmin) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Super Admin Tools',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
              title: const Text('Super Admin Console'),
              subtitle: const Text('Approvals, users, fleet overview, reports, and app updates'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go('/owner/console'),
            ),
            const Divider(height: 24),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Preferences',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: Text(themeModeLabel),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showThemeDialog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('Clear Local Data'),
            subtitle: const Text('Reset device preferences'),
            onTap: () => _handleClearLocalData(context, ref),
          ),

          const Divider(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Information & Support',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded),
            title: const Text('Check for Updates'),
            subtitle: const Text('Check for new version on GitHub'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _handleCheckUpdate(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About ${AppConstants.appName}'),
            subtitle: const Text('Version, Terms & Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/settings/about'),
          ),

          const Divider(height: 24),
          ListTile(
            leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
            title: Text('Logout', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
            onTap: () async {
              final confirm = await ConfirmDialog.show(
                context: context,
                title: 'Logout',
                content: 'Are you sure you want to sign out?',
                confirmLabel: 'Logout',
              );
              if (confirm) {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
          ),
        ],
      ),
    );
  }
}
