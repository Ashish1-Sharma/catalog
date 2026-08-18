import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_providers.dart';
import '../../providers/catalog_builder_provider.dart';

class CatalogCategorySelectScreen extends ConsumerStatefulWidget {
  const CatalogCategorySelectScreen({super.key});

  @override
  ConsumerState<CatalogCategorySelectScreen> createState() => _CatalogCategorySelectScreenState();
}

class _CatalogCategorySelectScreenState extends ConsumerState<CatalogCategorySelectScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final builderState = ref.read(catalogBuilderProvider);
    _nameController = TextEditingController(text: builderState.name.isEmpty ? 'My Catalog' : builderState.name);
    if (builderState.name.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(catalogBuilderProvider.notifier).setName('My Catalog');
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final builderState = ref.watch(catalogBuilderProvider);
    final notifier = ref.read(catalogBuilderProvider.notifier);
    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFECFDF5);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Catalog',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Step 1 of 3',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select categories and drag to reorder for your catalog.')),
              );
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (allCategories) {
          if (allCategories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category_outlined, size: 48, color: primaryGreen),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No categories available',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please add at least one category before creating a catalog.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category Now', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/add-category'),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedIds = builderState.selectedCategoryIds;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3-Step Stepper Bar
                      _buildStepperHeader(),

                      const SizedBox(height: 20),

                      // Catalog Name Input Field
                      const Row(
                        children: [
                          Text(
                            'Catalog Name',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            ' *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: inputBorderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: lightGreenBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.menu_book_outlined, color: primaryGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Enter catalog name',
                                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.normal),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) => notifier.setName(val),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section Title
                      const Text(
                        'Select categories to include',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Drag and drop to reorder the categories',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),

                      const SizedBox(height: 14),

                      // Reorderable Categories List Card Box
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allCategories.length,
                        onReorder: (oldIndex, newIndex) {
                          notifier.reorderCategories(oldIndex, newIndex);
                        },
                        itemBuilder: (context, index) {
                          final cat = allCategories[index];
                          final isChecked = selectedIds.contains(cat.id);

                          return Container(
                            key: ValueKey('cat_${cat.id}'),
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => notifier.toggleCategory(cat.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Drag Handle
                                      const Icon(
                                        Icons.drag_indicator_rounded,
                                        color: Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),

                                      // Folder Icon Avatar
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: lightGreenBg,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.folder_outlined,
                                          color: Color(0xFF059669),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Category Name
                                      Expanded(
                                        child: Text(
                                          cat.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),

                                      // Checkbox Indicator
                                      Icon(
                                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                        color: isChecked ? primaryGreen : const Color(0xFFCBD5E1),
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Tip Banner Card Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tip',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'You can select multiple categories and reorder them to set the display order.',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF047857), height: 1.3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFDCFCE7),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.folder_copy_rounded,
                                color: Color(0xFF059669),
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Fixed Primary Action Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      if (builderState.selectedCategoryIds.isEmpty) {
                        notifier.setSelectedCategories(allCategories.map((c) => c.id).toList());
                      }
                      context.push('/catalog-step2');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next: Select Products',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildStepperHeader() {
    const activeColor = Color(0xFF045435);
    const inactiveColor = Color(0xFFE2E8F0);
    const textInactive = Color(0xFF94A3B8);

    return Row(
      children: [
        // Step 1 Active
        Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '1',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select Categories',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: activeColor),
              ),
            ],
          ),
        ),

        // Line 1-2
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20),
            color: const Color(0xFF86EFAC),
          ),
        ),

        // Step 2 Inactive
        Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(color: textInactive, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select Products',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textInactive),
              ),
            ],
          ),
        ),

        // Line 2-3
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20),
            color: inactiveColor,
          ),
        ),

        // Step 3 Inactive
        Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: inactiveColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '3',
                    style: TextStyle(color: textInactive, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review & Create',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textInactive),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
