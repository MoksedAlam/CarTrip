import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Wraps any screen so pressing Android system back button or swipe back
/// safely pops if possible, or navigates back to [fallbackPath] (default '/owner/home')
/// instead of closing the entire app.
class AppBackHandler extends StatelessWidget {
  final Widget child;
  final String fallbackPath;
  final bool isRootTab;

  const AppBackHandler({
    super.key,
    required this.child,
    this.fallbackPath = '/owner/home',
    this.isRootTab = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // 1. If child navigator can pop, pop it
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

        // 2. If GoRouter context can pop, pop it
        if (context.canPop()) {
          context.pop();
          return;
        }

        // 3. Fallback to Home tab
        context.go(fallbackPath);
      },
      child: child,
    );
  }
}

/// Specialized back handler for the Home screen:
/// Shows a toast "Press back again to exit CarTrip" on first back press,
/// and exits only if pressed twice within 2 seconds.
class HomeExitHandler extends StatefulWidget {
  final Widget child;

  const HomeExitHandler({super.key, required this.child});

  @override
  State<HomeExitHandler> createState() => _HomeExitHandlerState();
}

class _HomeExitHandlerState extends State<HomeExitHandler> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }

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
      },
      child: widget.child,
    );
  }
}
