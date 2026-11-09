import '../../shared/models/transaction_type.dart';

class DefaultCategory {
  final String name;
  final TransactionType type;
  final String icon;

  const DefaultCategory(this.name, this.type, this.icon);
}

/// Seeded once into a new user's `categories` subcollection right after
/// registration (see CategoryRepository.seedDefaultCategoriesIfNeeded).
/// The user can rename, add to, or delete any of these afterward.
/// Note: Tabungan (Savings) is excluded from categories as it is directly
/// managed via Goals / Target Tabungan.
const List<DefaultCategory> defaultCategories = [
  // Income
  DefaultCategory('Gaji', TransactionType.income, 'salary'),
  DefaultCategory('Bonus', TransactionType.income, 'bonus'),
  DefaultCategory('Freelance', TransactionType.income, 'freelance'),
  DefaultCategory('Pendapatan lainnya', TransactionType.income, 'income_other'),

  // Expense
  DefaultCategory('Makan', TransactionType.expense, 'food'),
  DefaultCategory('Makan di luar', TransactionType.expense, 'food_out'),
  DefaultCategory('Transportasi', TransactionType.expense, 'transport'),
  DefaultCategory('Internet', TransactionType.expense, 'internet'),
  DefaultCategory('Pulsa', TransactionType.expense, 'phone_credit'),
  DefaultCategory('Belanja', TransactionType.expense, 'shopping'),
  DefaultCategory('Hiburan', TransactionType.expense, 'entertainment'),
  DefaultCategory('Nongkrong', TransactionType.expense, 'hangout'),
  DefaultCategory('Pacar / Date', TransactionType.expense, 'date'),
  DefaultCategory('Keluarga', TransactionType.expense, 'family'),
  DefaultCategory('Kesehatan', TransactionType.expense, 'health'),
  DefaultCategory('Pendidikan', TransactionType.expense, 'education'),
  DefaultCategory('Tagihan', TransactionType.expense, 'bill'),
  DefaultCategory('Cicilan', TransactionType.expense, 'installment'),
  DefaultCategory('Gereja', TransactionType.expense, 'church'),
  DefaultCategory('Lainnya', TransactionType.expense, 'other'),

  // Investment
  DefaultCategory('Reksa Dana', TransactionType.investment, 'mutual_fund'),
  DefaultCategory('SBN', TransactionType.investment, 'bond'),
  DefaultCategory('Saham', TransactionType.investment, 'stock'),
  DefaultCategory('Emas', TransactionType.investment, 'gold'),
  DefaultCategory('Crypto', TransactionType.investment, 'crypto'),
  DefaultCategory('Investasi lainnya', TransactionType.investment, 'investment_other'),
];
