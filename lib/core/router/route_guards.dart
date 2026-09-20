import '../constants/app_constants.dart';
import '../../features/auth/models/app_user.dart';

class RouteGuards {
  static const String splashPath = '/splash';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String pendingPath = '/pending';
  static const String blockedPath = '/blocked';
  static const String ownerHomePath = '/owner/home';
  static const String driverFleetPath = '/driver/fleet';
  static const String adminApprovalsPath = '/admin/approvals';

  /// Evaluates current state and returns a redirect route string if redirect is needed,
  /// or null if current route is valid.
  static String? guard({
    required bool isAuthInitialized,
    required bool isSignedIn,
    required bool isUserDocLoaded,
    required AppUser? userDoc,
    required String currentPath,
  }) {
    // 1. If auth state or user doc is not yet resolved, show splash
    if (!isAuthInitialized) {
      return currentPath == splashPath ? null : splashPath;
    }

    // 2. Not signed in -> Login screen
    if (!isSignedIn) {
      if (currentPath == loginPath || currentPath.startsWith('/settings/about')) {
        return null;
      }
      return loginPath;
    }

    // 3. User is signed in, but userDoc is still loading from firestore
    if (!isUserDocLoaded) {
      return currentPath == splashPath ? null : splashPath;
    }

    // 4. Signed in, but no user doc yet or registration has not been submitted
    if (userDoc == null || !userDoc.registrationSubmitted) {
      return currentPath == registerPath ? null : registerPath;
    }

    // 5. Super admin bypasses pending and blocked checks
    if (userDoc.role == UserRoles.superAdmin) {
      // Super admin has full owner capabilities + admin privileges
      if (currentPath.startsWith('/admin') ||
          currentPath.startsWith('/owner') ||
          currentPath.startsWith('/settings') ||
          currentPath.startsWith('/cars') ||
          currentPath.startsWith('/trips') ||
          currentPath.startsWith('/expenses') ||
          currentPath.startsWith('/fleet-board')) {
        return null;
      }
      return ownerHomePath;
    }

    // 6. Status checks for regular users
    if (userDoc.status == UserStatuses.rejected || userDoc.status == UserStatuses.disabled) {
      return currentPath == blockedPath ? null : blockedPath;
    }

    if (userDoc.status == UserStatuses.pending) {
      return currentPath == pendingPath ? null : pendingPath;
    }

    // 7. Role-based routing
    if (userDoc.role == UserRoles.driver) {
      // Driver can access driver routes and settings
      if (currentPath.startsWith('/driver') || currentPath.startsWith('/settings')) {
        return null;
      }
      return driverFleetPath;
    }

    // Regular owners cannot access admin console
    if (userDoc.role != UserRoles.superAdmin &&
        (currentPath.startsWith('/admin') || currentPath.startsWith('/owner/console'))) {
      return ownerHomePath;
    }

    // Default for all owners and general users: direct access to owner home
    if (currentPath.startsWith('/owner') ||
        currentPath.startsWith('/settings') ||
        currentPath.startsWith('/cars') ||
        currentPath.startsWith('/trips') ||
        currentPath.startsWith('/expenses') ||
        currentPath.startsWith('/fleet-board')) {
      return null;
    }
    return ownerHomePath;
  }
}
