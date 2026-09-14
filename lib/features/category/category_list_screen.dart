import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../services/analytics_service.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final TextEditingController _addCategoryController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _addCategoryController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCategories() async {
    final rawInput = _addCategoryController.text.trim();
    if (rawInput.isEmpty) return;

    final names = rawInput
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (names.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      final repo = ref.read(categoryRepoProvider);
      final existingCategories = await repo.getCategories();
      int currentSortOrder = existingCategories.length;

      for (final catName in names) {
        final companion = CategoriesCompanion(
          name: Value(catName),
          sortOrder: Value(currentSortOrder),
        );
        await repo.addCategory(companion);
        AnalyticsService.instance.logCategoryCreated(categoryName: catName);
        currentSortOrder++;
      }

      _addCategoryController.clear();
      ref.invalidate(categoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add category: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);

    const primaryGreen = Color(0xFF045435);
    const textDarkColor = Color(0xFF1E293B);

    // Compute product count map per category
    final Map<int, int> productCountMap = {};
    if (productsAsync.hasValue && productsAsync.value != null) {
      for (var p in productsAsync.value!) {
        productCountMap[p.categoryId] = (productCountMap[p.categoryId] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: textDarkColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Top Inline Add Category Section
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _addCategoryController,
                    onSubmitted: (_) => _handleAddCategories(),
                    decoration: InputDecoration(
                      hintText: 'Add category name(s)',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    onPressed: _isAdding ? null : _handleAddCategories,
                    child: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Subtitle instruction for multiple categories
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'To add multiple categories use , comma',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Categories List
          Expanded(
            child: categoriesAsync.when(
              data: (categories) {
                if (categories.isEmpty) {
                  return const Center(
                    child: Text(
                      'No categories added yet.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
                    ),
                  );
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                  itemCount: categories.length,
                  onReorder: (oldIndex, newIndex) async {
                    final list = List<Category>.from(categories);
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);
                    await ref.read(categoryRepoProvider).reorderCategories(list);
                    ref.invalidate(categoriesProvider);
                  },
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final count = productCountMap[cat.id] ?? 0;

                    return Container(
                      key: ValueKey(cat.id),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            // Category Title & Product count
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textDarkColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count products',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Edit Button
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF059669),
                                size: 22,
                              ),
                              onPressed: () => context.push('/edit-category', extra: cat),
                            ),

                            // Delete Button
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFFEF4444),
                                size: 22,
                              ),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Category'),
                                    content: Text(
                                        'Are you sure you want to delete "${cat.name}"? Products in this category will also be deleted.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(

                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(categoryRepoProvider).deleteCategory(cat.id);
                                  ref.invalidate(categoriesProvider);
                                  ref.invalidate(productsProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading categories: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
