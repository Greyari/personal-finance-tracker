/// Shared across categories and transactions — every category and every
/// transaction has exactly one of these four types. Lives in shared/
/// because it's a cross-feature concept, not owned by either feature.
enum TransactionType { income, expense, saving, investment }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.saving:
        return 'Tabungan';
      case TransactionType.investment:
        return 'Investasi';
    }
  }

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TransactionType.expense,
    );
  }
}
