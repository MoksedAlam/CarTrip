import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/screens/admin_fleet_screen.dart';
import '../../features/admin/screens/approvals_screen.dart';
import '../../features/admin/screens/users_screen.dart';
import '../../features/auth/models/app_user.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/blocked_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/owner_registration_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/cars/screens/car_detail_screen.dart';
import '../../features/cars/screens/car_form_screen.dart';
import '../../features/cars/screens/my_cars_screen.dart';
import '../../features/chat/screens/group_chat_screen.dart';
import '../../features/expenses/screens/expense_form_screen.dart';
import '../../features/fleet_board/screens/fleet_board_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/about_screen.dart';
import '../../features/settings/screens/profile_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/shell/admin_shell.dart';
import '../../features/shell/driver_shell.dart';
import '../../features/shell/owner_shell.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/trips/screens/complete_trip_screen.dart';
import '../../features/trips/screens/payment_qr_screen.dart';
import '../../features/trips/screens/reservation_form_screen.dart';
import '../../features/trips/screens/trip_detail_screen.dart';
import '../../features/trips/screens/trips_screen.dart';
import 'route_guards.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateChangesProvider);
  final userDocAsync = ref.watch(currentUserDocProvider);

  final isAuthInitialized = !authStateAsync.isLoading;
  final isSignedIn = authStateAsync.value != null;
  final isUserDocLoaded = !userDocAsync.isLoading;
  final AppUser? userDoc = userDocAsync.value;

  return GoRouter(
    initialLocation: RouteGuards.splashPath,
    redirect: (context, state) {
      return RouteGuards.guard(
        isAuthInitialized: isAuthInitialized,
        isSignedIn: isSignedIn,
        isUserDocLoaded: isUserDocLoaded,
        userDoc: userDoc,
        currentPath: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: RouteGuards.splashPath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteGuards.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteGuards.registerPath,
        builder: (context, state) => const OwnerRegistrationScreen(),
      ),
      GoRoute(
        path: RouteGuards.pendingPath,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: RouteGuards.blockedPath,
        builder: (context, state) => const BlockedScreen(),
      ),

      // Cars management routes
      GoRoute(
        path: '/cars',
        builder: (context, state) => const MyCarsScreen(),
      ),
      GoRoute(
        path: '/cars/add',
        builder: (context, state) => const CarFormScreen(),
      ),
      GoRoute(
        path: '/cars/:carId',
        builder: (context, state) => CarDetailScreen(
          carId: state.pathParameters['carId']!,
        ),
      ),
      GoRoute(
        path: '/cars/:carId/edit',
        builder: (context, state) => CarFormScreen(
          carId: state.pathParameters['carId']!,
        ),
      ),

      // Trips management routes
      GoRoute(
        path: '/trips/new',
        builder: (context, state) => ReservationFormScreen(
          initialCarId: state.uri.queryParameters['carId'],
        ),
      ),
      GoRoute(
        path: '/trips/:tripId',
        builder: (context, state) => TripDetailScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/complete',
        builder: (context, state) => CompleteTripScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/pay',
        builder: (context, state) => PaymentQrScreen(
          tripId: state.pathParameters['tripId']!,
        ),
      ),

      // Expenses routes
      GoRoute(
        path: '/expenses/new',
        builder: (context, state) => ExpenseFormScreen(
          initialCarId: state.uri.queryParameters['carId'],
        ),
      ),
      GoRoute(
        path: '/expenses/:expenseId/edit',
        builder: (context, state) => ExpenseFormScreen(
          expenseId: state.pathParameters['expenseId'],
        ),
      ),

      // Global Settings routes
      GoRoute(
        path: '/settings/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),

      // Owner Shell (5 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return OwnerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/fleet',
                builder: (context, state) => const FleetBoardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/trips',
                builder: (context, state) => const TripsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/community',
                builder: (context, state) => const GroupChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/owner/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone reports route for owner
      GoRoute(
        path: '/owner/reports',
        builder: (context, state) => const ReportsScreen(),
      ),

      // Driver Shell (3 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DriverShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/fleet',
                builder: (context, state) => const FleetBoardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/community',
                builder: (context, state) => const GroupChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Super Admin Shell (4 Tabs)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/approvals',
                builder: (context, state) => const ApprovalsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const UsersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/fleet',
                builder: (context, state) => const AdminFleetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
