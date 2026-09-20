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

    // 5. Status is pending approval
    if (userDoc.status == UserStatuses.pending) {
      return currentPath == pendingPath ? null : pendingPath;
    }

    // 6. Status is rejected or disabled
    if (userDoc.status == UserStatuses.rejected || userDoc.status == UserStatuses.disabled) {
      return currentPath == blockedPath ? null : blockedPath;
    }

    // 7. Role-based routing for active users
    if (userDoc.role == UserRoles.superAdmin) {
      // Super admin can access admin routes and settings
      if (currentPath.startsWith('/admin') || currentPath.startsWith('/settings')) {
        return null;
      }
      return adminApprovalsPath;
    }

    if (userDoc.role == UserRoles.owner && userDoc.status == UserStatuses.active) {
      // Owner can access owner routes, car routes, trip routes, expense routes, and settings
      if (currentPath.startsWith('/owner') ||
          currentPath.startsWith('/settings') ||
          currentPath.startsWith('/cars') ||
          currentPath.startsWith('/trips') ||
          currentPath.startsWith('/expenses')) {
        return null;
      }
      return ownerHomePath;
    }

    if (userDoc.role == UserRoles.driver && userDoc.status == UserStatuses.active) {
      // Driver can access driver routes and settings
      if (currentPath.startsWith('/driver') || currentPath.startsWith('/settings')) {
        return null;
      }
      return driverFleetPath;
    }

    // Fallback if role is unassigned or invalid
    return loginPath;
  }
}
