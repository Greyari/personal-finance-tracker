import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/goal_contribution_model.dart';
import '../../data/models/saving_goal_model.dart';
import '../../data/repositories/saving_goal_repository.dart';

final savingGoalRepositoryProvider = Provider<SavingGoalRepository>((ref) {
  return SavingGoalRepository();
});

final savingGoalsProvider = StreamProvider<List<SavingGoalModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(savingGoalRepositoryProvider).watchGoals(userId);
});

final goalContributionsProvider =
    StreamProvider.family<List<GoalContributionModel>, String>((ref, goalId) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(savingGoalRepositoryProvider).watchContributions(userId, goalId);
});

class SavingGoalController extends StateNotifier<AsyncValue<void>> {
  final SavingGoalRepository _repository;
  final String? _userId;

  SavingGoalController(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<bool> addGoal({required String name, required double targetAmount}) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addGoal(
        SavingGoalModel(id: '', userId: _userId, name: name, targetAmount: targetAmount),
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateGoal(SavingGoalModel goal) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateGoal(goal);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteGoal(String goalId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGoal(userId: _userId, goalId: goalId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> addContribution({
    required String goalId,
    required double amount,
    required String note,
    required DateTime date,
  }) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addContribution(
        userId: _userId,
        goalId: goalId,
        amount: amount,
        note: note,
        date: date,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final savingGoalControllerProvider =
    StateNotifierProvider<SavingGoalController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return SavingGoalController(ref.watch(savingGoalRepositoryProvider), userId);
});
