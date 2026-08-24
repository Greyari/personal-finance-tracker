import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_providers.dart';

enum HealthStatus { good, warning, risky }

extension HealthStatusX on HealthStatus {
  String get emoji {
    switch (this) {
      case HealthStatus.good:
        return '🟢';
      case HealthStatus.warning:
        return '🟡';
      case HealthStatus.risky:
        return '🔴';
    }
  }

  String get label {
    switch (this) {
      case HealthStatus.good:
        return 'Bagus';
      case HealthStatus.warning:
        return 'Perlu diperhatikan';
      case HealthStatus.risky:
        return 'Berisiko';
    }
  }
}

// Simple heuristic bands — generic personal-finance rules of thumb (e.g.
// "aim to save at least ~20% of income"), NOT tailored advice for any
// individual's situation. Per Section 17, this screen must not give
// specific or return-promising investment advice; these thresholds only
// classify the user's own recorded numbers, the same way the Budget
// screen's 🟢/⚠️/🔴 classifies budget usage.
HealthStatus _savingStatus(double rate) {
  if (rate >= 20) return HealthStatus.good;
  if (rate >= 10) return HealthStatus.warning;
  return HealthStatus.risky;
}

HealthStatus _investmentStatus(double rate) {
  if (rate >= 10) return HealthStatus.good;
  if (rate >= 5) return HealthStatus.warning;
  return HealthStatus.risky;
}

HealthStatus _expenseStatus(double rate) {
  if (rate <= 50) return HealthStatus.good;
  if (rate <= 70) return HealthStatus.warning;
  return HealthStatus.risky;
}

class FinancialHealth {
  final double savingRate;
  final double investmentRate;
  final double expenseRate;

  const FinancialHealth({
    required this.savingRate,
    required this.investmentRate,
    required this.expenseRate,
  });

  HealthStatus get savingStatus => _savingStatus(savingRate);
  HealthStatus get investmentStatus => _investmentStatus(investmentRate);
  HealthStatus get expenseStatus => _expenseStatus(expenseRate);
}

final financialHealthProvider = Provider<FinancialHealth>((ref) {
  final summary = ref.watch(monthlySummaryProvider);
  return FinancialHealth(
    savingRate: summary.savingRate,
    investmentRate: summary.investmentRate,
    expenseRate: summary.expenseRate,
  );
});
