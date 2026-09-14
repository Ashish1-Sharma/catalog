import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/app_providers.dart';
import '../../providers/catalog_builder_provider.dart';

class CatalogProductSelectScreen extends ConsumerStatefulWidget {
  const CatalogProductSelectScreen({super.key});

  @override
  ConsumerState<CatalogProductSelectScreen> createState() => _CatalogProductSelectScreenState();
}

class _CatalogProductSelectScreenState extends ConsumerState<CatalogProductSelectScreen> {
  String _searchQuery = '';
  String _filterStock = 'All'; // Options: All, In Stock, Low Stock

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(catalogBuilderProvider);
    final notifier = ref.read(catalogBuilderProvider.notifier);
    final productsAsync = ref.watch(productsProvider);
    final profileAsync = ref.watch(businessProfileProvider);
    final currency = profileAsync.value?.currency ?? '₹';
    const primaryPurple = Color(0xFF6366F1);
    const deepPurple = Color(0xFF4338CA);
    const lightPurpleBg = Color(0xFFF3E8FF);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryPurple),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Select Products',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: primaryPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select products to include in your catalog.')),
              );
            },
          ),
        ],
      ),
      body: productsAsync.when(
        data: (allProducts) {
          // 1. Filter by categories selected in Step 1
          final categoryFiltered = builderState.selectedCategoryIds.isEmpty
              ? allProducts
              : allProducts.where((p) => builderState.selectedCategoryIds.contains(p.categoryId)).toList();

          // 2. Filter by search query & stock filter
          final filteredProducts = categoryFiltered.where((p) {
            final matchesQuery = _searchQuery.isEmpty || p.name.toLowerCase().contains(_searchQuery);
            if (_filterStock == 'In Stock') {
              return matchesQuery && (p.quantity == null || p.quantity != '0');
            }
            if (_filterStock == 'Low Stock') {
              return matchesQuery && (p.quantity != null && (p.quantity == '1' || p.quantity == '2' || p.quantity == '3'));
            }
            return matchesQuery;
          }).toList();

          if (categoryFiltered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: lightPurpleBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2_outlined, size: 48, color: primaryPurple),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No products match your selected categories',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please add products to your categories or select different categories in Step 1.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Products', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.push('/add-product'),
                    ),
                  ],
                ),
              ),
            );
          }

          final selectedIds = builderState.selectedProductIds;
          final isAllSelected = selectedIds.length == categoryFiltered.length && categoryFiltered.isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar & Filter Button Row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: inputBorderColor, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      style: const TextStyle(fontSize: 14),
                                      decoration: const InputDecoration(
                                        hintText: 'Search products...',
                                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val.trim().toLowerCase();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<String>(
                            onSelected: (val) => setState(() => _filterStock = val),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: inputBorderColor, width: 1.5),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.tune_rounded, color: Color(0xFF475569), size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'All', child: Text('All Products')),
                              PopupMenuItem(value: 'In Stock', child: Text('In Stock Only')),
                              PopupMenuItem(value: 'Low Stock', child: Text('Low Stock Only')),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Selection Header Counter Bar Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryPurple,
                                    borderRadius: BorderRadius.all(Radius.circular(6)),
                                  ),
                                  child: const Icon(
                                    Icons.remove_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${selectedIds.length} of ${categoryFiltered.length} selected',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                if (isAllSelected) {
                                  notifier.setSelectedProducts([]);
                                } else {
                                  notifier.setSelectedProducts(categoryFiltered.map((p) => p.id).toList());
                                }
                              },
                              child: Text(
                                isAllSelected ? 'Deselect All' : 'Select All',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: primaryPurple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Product Items List Cards
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final prod = filteredProducts[index];
                          final isChecked = selectedIds.contains(prod.id);
                          final hasImage = prod.imagePath != null && File(prod.imagePath!).existsSync();
                          final formattedPrice = CurrencyUtils.formatAmount(prod.salePrice, currency: currency);
                          final isLowStock = prod.quantity != null && (prod.quantity == '1' || prod.quantity == '2' || prod.quantity == '3');

                          return Container(
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
                                onTap: () => notifier.toggleProduct(prod.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Product Image Thumbnail
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          color: const Color(0xFFF1F5F9),
                                          child: hasImage
                                              ? Image.file(File(prod.imagePath!), fit: BoxFit.cover)
                                              : const Center(
                                                  child: Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8), size: 28),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              prod.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            // Stock Badge
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isLowStock ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isLowStock ? 'Low Stock' : 'In Stock',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: isLowStock ? const Color(0xFFD97706) : const Color(0xFF15803D),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 4),
                                            Text(
                                              'Price: $formattedPrice',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Right Checkbox
                                      Icon(
                                        isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                        color: isChecked ? primaryPurple : const Color(0xFFCBD5E1),
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
                    ],
                  ),
                ),
              ),

              // Bottom Fixed Selection Counter & Action Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Count Circle Badge Box
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: lightPurpleBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${selectedIds.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Selected Count (Price Total Removed)
                    Expanded(
                      child: Text(
                        '${selectedIds.length} items selected',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Next Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: deepPurple,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        if (builderState.selectedProductIds.isEmpty) {
                          notifier.setSelectedProducts(categoryFiltered.map((p) => p.id).toList());
                        }
                        context.push('/catalog-step3');
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Next: Select Layout Type',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ],
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
}
