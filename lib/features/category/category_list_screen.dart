import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);
    const primaryPurple = Color(0xFF6366F1);

    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFECFDF5);
    const greenBorderColor = Color(0xFFD1FAE5);
    const textDarkColor = Color(0xFF1E293B);

    // Compute product count map per category
    final Map<int, int> productCountMap = {};
    if (productsAsync.hasValue && productsAsync.value != null) {
      for (var p in productsAsync.value!) {
        productCountMap[p.categoryId] = (productCountMap[p.categoryId] ?? 0) + 1;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search categories...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text(
                'Categories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.add_rounded, size: 28),
          //   onPressed: () => context.push('/add-category'),
          // ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final query = _searchController.text.trim().toLowerCase();
          final filteredCategories = query.isEmpty
              ? categories
              : categories.where((c) => c.name.toLowerCase().contains(query)).toList();

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No categories added yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Category'),
                    onPressed: () => context.push('/add-category'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Reorder Guide Banner Box
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: lightGreenBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: greenBorderColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.touch_app_outlined,
                        color: Color(0xFF059669),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Press and hold, then drag up or down\nto reorder the categories.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reorderable Category List
              Expanded(
                child: filteredCategories.isEmpty
                    ? const Center(child: Text('No categories match search.'))
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                        itemCount: filteredCategories.length,
                        onReorder: (oldIndex, newIndex) async {
                          if (query.isNotEmpty) return; // Disable reorder during search filter
                          final list = List<Category>.from(categories);
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = list.removeAt(oldIndex);
                          list.insert(newIndex, item);
                          await ref.read(categoryRepoProvider).reorderCategories(list);
                          ref.invalidate(categoriesProvider);
                        },
                        itemBuilder: (context, index) {
                          final cat = filteredCategories[index];
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Drag indicator handle
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                      child: Icon(
                                        Icons.drag_indicator_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Category Icon circle (without logo as requested)
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: lightGreenBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.category_rounded,
                                      color: Color(0xFF059669),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

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
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Edit Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
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
                                          content: Text('Are you sure you want to delete "${cat.name}"? Products in this category will also be deleted.'),
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
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading categories: $e')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              backgroundColor: primaryPurple,
              elevation: 4,
              shape: const CircleBorder(),
              onPressed: () => context.push('/add-category'),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add Category',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
