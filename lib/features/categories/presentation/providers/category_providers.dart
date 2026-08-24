import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/transaction_type.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Streams categories for the signed-in user, optionally filtered by
/// type. `categoriesProvider(null)` returns every category;
/// `categoriesProvider(TransactionType.expense)` returns only expense
/// categories, e.g. for the transaction form's category dropdown.
final categoriesProvider =
    StreamProvider.family<List<CategoryModel>, TransactionType?>((ref, type) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId == null) return Stream.value(const []);
  return ref.watch(categoryRepositoryProvider).watchCategories(userId, type: type);
});

class CategoryController extends StateNotifier<AsyncValue<void>> {
  final CategoryRepository _repository;
  final String? _userId;

  CategoryController(this._repository, this._userId)
      : super(const AsyncValue.data(null));

  Future<bool> addCategory({
    required String name,
    required TransactionType type,
    required String icon,
  }) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.addCategory(userId: _userId, name: name, type: type, icon: icon);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCategory(CategoryModel category) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.updateCategory(userId: _userId, category: category);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    if (_userId == null) return false;
    state = const AsyncValue.loading();
    try {
      await _repository.deleteCategory(userId: _userId, categoryId: categoryId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<void>>((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  return CategoryController(ref.watch(categoryRepositoryProvider), userId);
});
