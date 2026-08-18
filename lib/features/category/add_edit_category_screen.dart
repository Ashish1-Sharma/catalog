import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class AddEditCategoryScreen extends ConsumerStatefulWidget {
  final Category? category;
  const AddEditCategoryScreen({super.key, this.category});

  @override
  ConsumerState<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends ConsumerState<AddEditCategoryScreen> {
  static const Color _primaryGreen = Color(0xFF045435);
  static const Color _lightGreenBg = Color(0xFFECFDF5);
  static const Color _inputBorder = Color(0xFFE2E8F0);
  static const Color _darkText = Color(0xFF0F172A);
  static const Color _subText = Color(0xFF64748B);
  static const Color _mutedText = Color(0xFF94A3B8);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  int _nameLength = 0;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _nameLength = widget.category!.name.length;
    }
    _nameController.addListener(() {
      setState(() => _nameLength = _nameController.text.length);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final rawInput = _nameController.text.trim();
    final repo = ref.read(categoryRepoProvider);
    final isEdit = widget.category != null;

    try {
      if (isEdit) {
        // Edit mode: Save single category (comma separation feature disabled)
        final updated = widget.category!.copyWith(name: rawInput);
        await repo.updateCategory(updated);
      } else {
        // Add mode: Comma separation enabled to add multiple categories at once
        final categoryNames = rawInput
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        if (categoryNames.isEmpty) {
          setState(() => _isLoading = false);
          return;
        }

        final existingCategories = await repo.getCategories();
        int currentSortOrder = existingCategories.length;

        for (final catName in categoryNames) {
          final companion = CategoriesCompanion(
            name: drift.Value(catName),
            sortOrder: drift.Value(currentSortOrder),
          );
          await repo.addCategory(companion);
          currentSortOrder++;
        }
      }

      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save category: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final maxLen = isEdit ? 40 : 200;

    final parsedCategories = !isEdit
        ? _nameController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Category' : 'Add Category',
              style: const TextStyle(
                color: _darkText,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isEdit
                  ? 'Update your product category name'
                  : 'Group your products for easier catalogs',
              style: const TextStyle(
                color: _subText,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category name field label
              _buildLabel(
                isEdit ? 'Category Name' : 'Category Name(s)',
                isRequired: true,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _inputBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: _lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.folder_outlined,
                        color: _primaryGreen,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        autofocus: !isEdit,
                        maxLength: maxLen,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _isLoading ? null : _save(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: isEdit
                              ? 'e.g. Electronics'
                              : 'e.g. Electronics, Clothing, Shoes',
                          hintStyle: const TextStyle(color: _mutedText, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          counterText: '',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter category name'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_nameLength/$maxLen',
                  style: const TextStyle(fontSize: 11, color: _mutedText),
                ),
              ),

              // Multiple Categories Live Chips Preview (Add Mode Only)
              if (!isEdit && parsedCategories.length > 1) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.style_outlined, size: 14, color: _primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      'Will create ${parsedCategories.length} categories:',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: parsedCategories
                      .map(
                        (cat) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _lightGreenBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.folder_rounded,
                                size: 12,
                                color: _primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cat,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Tip card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: Color(0xFF059669),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isEdit
                                ? 'Short, clear names work best — you can pick categories when building a catalog.'
                                : 'Use commas to add multiple categories at once! (e.g. Mobile, Laptops, Accessories)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF047857),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.save_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEdit
                                  ? 'Update Category'
                                  : parsedCategories.length > 1
                                      ? 'Save ${parsedCategories.length} Categories'
                                      : 'Save Category',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
      ],
    );
  }
}
