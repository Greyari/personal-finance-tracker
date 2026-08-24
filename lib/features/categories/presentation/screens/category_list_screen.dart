import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../data/models/category_model.dart';
import '../providers/category_providers.dart';
import 'add_edit_category_screen.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _types = TransactionType.values;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Hapus kategori "${category.name}"? Transaksi lama yang memakai kategori ini tidak akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success =
          await ref.read(categoryControllerProvider.notifier).deleteCategory(category.id);
      if (!success && context.mounted) {
        final error = ref.read(categoryControllerProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorMapper.toUserMessage(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _types.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types.map((type) {
          final categoriesAsync = ref.watch(categoriesProvider(type));
          return categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('Belum ada kategori.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      child: Icon(CategoryIcons.resolve(category.icon)),
                    ),
                    title: Text(category.name),
                    subtitle: category.isDefault ? const Text('Bawaan') : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => AddEditCategoryScreen(category: category)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmDelete(context, category),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddEditCategoryScreen(initialType: _types[_tabController.index]),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
