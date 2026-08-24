import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/investment_model.dart';
import '../../data/repositories/investment_repository.dart';

final investmentRepositoryProvider = Provider<InvestmentRepository>((ref) {
  return InvestmentRepository();
});

final investmentsProvider = StreamProvider<List<InvestmentModel>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(investmentRepositoryProvider).watchInvestments(userId);
});

/// Portfolio-wide aggregate: total capital, current value, profit, and
/// blended return % across every recorded investment.
class InvestmentSummary {
  final double totalCapital;
  final double totalCurrentValue;

  const InvestmentSummary({required this.totalCapital, required this.totalCurrentValue});

  double get totalProfit => totalCurrentValue - totalCapital;
  double get returnPercent => totalCapital <= 0 ? 0 : (totalProfit / totalCapital) * 100;
}

final investmentSummaryProvider = Provider<InvestmentSummary>((ref) {
  final investments = ref.watch(investmentsProvider).value ?? const [];
  final totalCapital = investments.fold(0.0, (sum, i) => sum + i.capital);
  final totalCurrentValue = investments.fold(0.0, (sum, i) => sum + i.currentValue);
  return InvestmentSummary(totalCapital: totalCapital, totalCurrentValue: totalCurrentValue);
});

class InvestmentController extends StateNotifier<AsyncValue<void>> {
  final InvestmentRepository _repository;
  final String? _userId;

  InvestmentController(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<bool> addInvestment({
    required String categoryId,
    required String name,
    required double capital,
    required double currentValue,
    required DateTime date,
    required String note,
  }) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addInvestment(InvestmentModel(
        id: '',
        userId: _userId,
        categoryId: categoryId,
        name: name,
        capital: capital,
        currentValue: currentValue,
        date: date,
        note: note,
      ));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateInvestment(InvestmentModel investment) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateInvestment(investment);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteInvestment(String investmentId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteInvestment(userId: _userId, investmentId: investmentId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final investmentControllerProvider =
    StateNotifierProvider<InvestmentController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return InvestmentController(ref.watch(investmentRepositoryProvider), userId);
});
