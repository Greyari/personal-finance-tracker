import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/error_mapper.dart';
import '../../../../shared/models/transaction_type.dart';
import '../../../../shared/widgets/glass_widgets.dart';
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
  static const _types = [
    TransactionType.expense,
    TransactionType.income,
    TransactionType.investment,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, CategoryModel category) async {
    final confirmed = await showGlassConfirmDialog(
      context: context,
      title: 'Hapus Kategori',
      message: 'Hapus kategori "${category.name}"? Transaksi lama yang memakai kategori ini tidak akan ikut terhapus.',
      confirmLabel: 'Hapus',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      final success =
          await ref.read(categoryControllerProvider.notifier).deleteCategory(category.id);
      if (success && context.mounted) {
        showGlassSnackBar(context, 'Kategori "${category.name}" telah dihapus');
      } else if (!success && context.mounted) {
        final error = ref.read(categoryControllerProvider).error;
        showGlassSnackBar(
          context,
          ErrorMapper.toUserMessage(error),
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(
          'Kelola Kategori',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x331E293B) : const Color(0x24FFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight,
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              tabs: _types.map((t) => Tab(text: t.label)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types.map((type) {
          final categoriesAsync = ref.watch(categoriesProvider(type));
          return categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada kategori untuk ${type.label}.',
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                            ),
                            child: Icon(
                              CategoryIcons.resolve(category.icon),
                              color: primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.5,
                                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  ),
                                ),
                                if (category.isDefault)
                                  Text(
                                    'Kategori Bawaan',
                                    style: TextStyle(
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      fontSize: 11.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 19),
                            tooltip: 'Edit Kategori',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddEditCategoryScreen(category: category),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                size: 19, color: AppColors.expense(context)),
                            tooltip: 'Hapus Kategori',
                            onPressed: () => _confirmDelete(context, category),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: 25 * index.clamp(0, 10)),
                        duration: 200.ms,
                      );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Terjadi kesalahan: $e')),
          );
        }).toList(),
      ),
      floatingActionButton: GlassCircularFab(
        heroTag: 'fab_add_category',
        bottomMargin: 12,
        tooltip: 'Kategori Baru',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                AddEditCategoryScreen(initialType: _types[_tabController.index]),
          ),
        ),
      ),
    );
  }
}
