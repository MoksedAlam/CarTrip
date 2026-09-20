import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/car_trip_nav_bar.dart';
import '../../core/widgets/offline_banner.dart';
import '../auth/providers/auth_providers.dart';

class OwnerShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const OwnerShell({super.key, required this.navigationShell});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  DateTime? _lastBackPressTime;

  void _handleBackPress() {
    // If not on Home tab, switch to Home tab
    if (widget.navigationShell.currentIndex != 0) {
      widget.navigationShell.goBranch(0);
      return;
    }

    // On Home tab: double back press to exit
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit CarTrip'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  int _getUiIndex(int branchIndex, bool isSuperAdmin) {
    if (isSuperAdmin) return branchIndex;
    // For non-superadmin: branch 5 (Settings) is shown as UI index 4
    if (branchIndex >= 5) return 4;
    return branchIndex;
  }

  int _getBranchIndex(int uiIndex, bool isSuperAdmin) {
    if (isSuperAdmin) return uiIndex;
    // For non-superadmin: UI index 4 (Settings) points to branch 5
    if (uiIndex >= 4) return 5;
    return uiIndex;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final isSuperAdmin = user?.role == UserRoles.superAdmin;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(child: widget.navigationShell),
          ],
        ),
        bottomNavigationBar: CarTripNavBar(
          selectedIndex: _getUiIndex(widget.navigationShell.currentIndex, isSuperAdmin),
          onItemSelected: (uiIndex) {
            final branch = _getBranchIndex(uiIndex, isSuperAdmin);
            widget.navigationShell.goBranch(
              branch,
              initialLocation: branch == widget.navigationShell.currentIndex,
            );
          },
          items: [
            const CarTripNavItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard_rounded,
              label: 'Home',
            ),
            const CarTripNavItem(
              icon: Icons.directions_car_outlined,
              selectedIcon: Icons.directions_car_rounded,
              label: 'All Cars',
            ),
            const CarTripNavItem(
              icon: Icons.route_outlined,
              selectedIcon: Icons.route_rounded,
              label: 'Trips',
            ),
            const CarTripNavItem(
              icon: Icons.forum_outlined,
              selectedIcon: Icons.forum_rounded,
              label: 'Group',
            ),
            if (isSuperAdmin)
              const CarTripNavItem(
                icon: Icons.admin_panel_settings_outlined,
                selectedIcon: Icons.admin_panel_settings_rounded,
                label: 'Console',
                isHighlight: true,
              ),
            const CarTripNavItem(
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
