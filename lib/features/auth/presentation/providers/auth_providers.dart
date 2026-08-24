import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../categories/data/repositories/category_repository.dart';
import '../../../recurring/data/repositories/recurring_transaction_repository.dart';
import '../../data/models/app_user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Streams the raw FirebaseAuth user. Null means signed out.
/// This is what AuthGate in main.dart watches to decide Login vs Home.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Streams the current user's Firestore profile document.
/// Automatically re-subscribes whenever the signed-in user changes,
/// and emits null while signed out.
final userProfileProvider = StreamProvider<AppUserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchProfile(user.uid);
});

/// Drives the login/register/forgot-password screens. Exposes loading and
/// error state via AsyncValue without leaking FirebaseAuth types into the
/// UI layer — screens only ever see AsyncValue<void>.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  final CategoryRepository _categoryRepository;
  final RecurringTransactionRepository _recurringRepository;

  AuthController(
    this._authRepository,
    this._userRepository,
    this._categoryRepository,
    this._recurringRepository,
  ) : super(const AsyncValue.data(null));

  Future<bool> signIn(
      {required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user =
          await _authRepository.register(email: email, password: password);
      // Create the Firestore profile document right after the auth
      // account is created, so the two never drift out of sync.
      await _userRepository.createProfile(
        AppUserModel(
          userId: user.uid,
          email: email.trim(),
          displayName: displayName.trim(),
        ),
      );
      // Give every new user a starting set of categories (Section 6 of
      // the spec) so Transactions isn't empty/unusable on first login.
      // Guarded internally against double-seeding, so it's safe even if
      // register() were somehow retried.
      await _categoryRepository.seedDefaultCategoriesIfNeeded(user.uid);

      // Section 13: default "Gereja 10%" recurring config, linked to the
      // "Gereja" category that seeding above just created. Looked up by
      // name rather than hardcoding an ID, since category IDs are
      // Firestore-generated.
      final gerejaCategoryId =
          await _categoryRepository.getCategoryIdByName(user.uid, 'Gereja');
      if (gerejaCategoryId != null) {
        await _recurringRepository.seedDefaultChurchRecurringIfNeeded(
          userId: user.uid,
          categoryId: gerejaCategoryId,
        );
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
    // Instantiated directly rather than via their respective feature
    // providers to avoid circular imports (category_providers.dart and
    // recurring_providers.dart both already import from this file).
    CategoryRepository(),
    RecurringTransactionRepository(),
  );
});
