import 'package:fleetboard/core/constants/app_constants.dart';
import 'package:fleetboard/core/router/route_guards.dart';
import 'package:fleetboard/features/auth/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Route Guards Tests', () {
    test('App launching / uninitialized auth redirects to splash', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: false,
        isSignedIn: false,
        isUserDocLoaded: false,
        userDoc: null,
        currentPath: '/some/path',
      );
      expect(dest, RouteGuards.splashPath);
    });

    test('Not signed in redirects to login', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: false,
        isUserDocLoaded: true,
        userDoc: null,
        currentPath: '/owner/home',
      );
      expect(dest, RouteGuards.loginPath);
    });

    test('Signed in but user doc missing or registration not submitted redirects to register', () {
      final dest1 = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: null,
        currentPath: '/owner/home',
      );
      expect(dest1, RouteGuards.registerPath);

      final dest2 = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'test@example.com',
          name: 'Test',
          registrationSubmitted: false,
        ),
        currentPath: '/owner/home',
      );
      expect(dest2, RouteGuards.registerPath);
    });

    test('Pending or new users get direct access to owner home', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'test@example.com',
          name: 'Test',
          registrationSubmitted: true,
          status: UserStatuses.pending,
        ),
        currentPath: '/owner/home',
      );
      expect(dest, isNull);
    });

    test('Rejected or disabled status redirects to blocked screen', () {
      final dest1 = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'test@example.com',
          name: 'Test',
          registrationSubmitted: true,
          status: UserStatuses.rejected,
        ),
        currentPath: '/owner/home',
      );
      expect(dest1, RouteGuards.blockedPath);

      final dest2 = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'test@example.com',
          name: 'Test',
          registrationSubmitted: true,
          status: UserStatuses.disabled,
        ),
        currentPath: '/owner/home',
      );
      expect(dest2, RouteGuards.blockedPath);
    });

    test('Super admin redirects to owner home with full owner capabilities', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'admin@example.com',
          name: 'Admin',
          role: UserRoles.superAdmin,
          status: UserStatuses.active,
          registrationSubmitted: true,
        ),
        currentPath: '/splash',
      );
      expect(dest, RouteGuards.ownerHomePath);

      // Super admin can access /admin routes freely without redirection
      final adminDest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'admin@example.com',
          name: 'Admin',
          role: UserRoles.superAdmin,
          status: UserStatuses.active,
          registrationSubmitted: true,
        ),
        currentPath: '/admin/approvals',
      );
      expect(adminDest, isNull);
    });

    test('Active owner redirects to owner home', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'owner@example.com',
          name: 'Owner',
          role: UserRoles.owner,
          status: UserStatuses.active,
          registrationSubmitted: true,
        ),
        currentPath: '/splash',
      );
      expect(dest, RouteGuards.ownerHomePath);
    });

    test('Active driver redirects to driver fleet', () {
      final dest = RouteGuards.guard(
        isAuthInitialized: true,
        isSignedIn: true,
        isUserDocLoaded: true,
        userDoc: const AppUser(
          uid: '123',
          email: 'driver@example.com',
          name: 'Driver',
          role: UserRoles.driver,
          status: UserStatuses.active,
          registrationSubmitted: true,
        ),
        currentPath: '/splash',
      );
      expect(dest, RouteGuards.driverFleetPath);
    });
  });
}
