/// Centralized Firestore collection/document names.
/// Keeping these in one place avoids "magic strings" scattered through
/// the codebase and makes future refactors safe. Every later phase
/// (transactions, budgets, savings, investments, ...) will add its
/// collection name here instead of hardcoding it in a repository.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';

  // Subcollections under users/{userId}
  static const String profile = 'profile';
  static const String transactions = 'transactions';
  static const String budgets = 'budgets';
  static const String savingGoals = 'saving_goals';
  static const String investments = 'investments';
  static const String categories = 'categories';
  static const String recurringTransactions = 'recurring_transactions';

  /// Top-level directory for user discovery (email, displayName, photoUrl)
  static const String userDirectory = 'user_directory';

  /// Top-level collections for direct 1-on-1 chats and real-time messaging
  static const String chats = 'chats';
  static const String messages = 'messages';

  /// Subcollection under users/{userId}/saving_goals/{goalId}
  static const String contributions = 'contributions';

  /// The profile subcollection currently holds a single document,
  /// since a user only ever has one profile.
  static const String profileDocId = 'data';
}
