import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../data/user_repository.dart';
import '../models/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges();
});

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authUserAsync = ref.watch(authStateChangesProvider);
  final user = authUserAsync.value;
  if (user == null) {
    return Stream.value(null);
  }
  final userRepo = ref.watch(userRepositoryProvider);
  return userRepo.watchUser(user.uid);
});

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);

      final cred = await authRepo.signInWithGoogle();
      if (cred == null || cred.user == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      await userRepo.createInitialUserIfMissing(cred.user!);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> submitRegistration({
    required String name,
    required String phone,
    required String area,
    String? upiId,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) throw Exception('No user logged in');

    state = const AsyncValue.loading();
    try {
      final userRepo = ref.read(userRepositoryProvider);
      await userRepo.submitOwnerRegistration(
        uid: user.uid,
        name: name,
        phone: phone,
        area: area,
        upiId: upiId,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
