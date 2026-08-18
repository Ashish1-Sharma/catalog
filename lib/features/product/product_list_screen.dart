import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/currency_utils.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  int? _selectedCategoryId; // null means 'All Categories'
  String _selectedCategoryName = 'All Categories';
  String _sortBy = 'Recent'; // Options: Recent, Name A-Z, Price: Low to High, Price: High to Low
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final profileAsync = ref.watch(businessProfileProvider);
    final currency = profileAsync.value?.currency ?? '₹';
    const primaryPurple = Color(0xFF6366F1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryPurple),
          onPressed: () => context.pop(),
        ),
        title: _isSearching
            ? TextField(
                autofocus: true,
                style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              )
            : const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Manager',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage, edit and organize your products',
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
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: primaryPurple,
              size: 24,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchQuery = '';
              });
            },
          ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.tune_rounded, color: primaryPurple, size: 24),
          //   onSelected: (val) {
          //     setState(() => _sortBy = val);
          //   },
          //   itemBuilder: (context) => const [
          //     PopupMenuItem(value: 'Recent', child: Text('Sort by: Recent')),
          //     PopupMenuItem(value: 'Name A-Z', child: Text('Sort by: Name A-Z')),
          //     PopupMenuItem(value: 'Price: Low to High', child: Text('Sort by: Price (Low to High)')),
          //     PopupMenuItem(value: 'Price: High to Low', child: Text('Sort by: Price (High to Low)')),
          //   ],
          // ),
          // const SizedBox(width: 4),
        ],
      ),
      body: productsAsync.when(
        data: (allProducts) {
          final categories = categoriesAsync.value ?? [];

          // 1. Filter by category & search query
          var filtered = allProducts.where((p) {
            final matchesCategory = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
            if (!matchesCategory) return false;

            if (_searchQuery.isEmpty) return true;
            return p.name.toLowerCase().contains(_searchQuery) ||
                (p.description != null && p.description!.toLowerCase().contains(_searchQuery));
          }).toList();

          // 2. Sort
          if (_sortBy == 'Name A-Z') {
            filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          } else if (_sortBy == 'Price: Low to High') {
            filtered.sort((a, b) => a.salePrice.compareTo(b.salePrice));
          } else if (_sortBy == 'Price: High to Low') {
            filtered.sort((a, b) => b.salePrice.compareTo(a.salePrice));
          } else {
            // Recent
            filtered.sort((a, b) => b.id.compareTo(a.id));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter & View Toggle Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Row(
                  children: [
                    // Category Dropdown Pill
                    Expanded(
                      flex: 5,
                      child: PopupMenuButton<int?>(
                        onSelected: (catId) {
                          setState(() {
                            _selectedCategoryId = catId;
                            if (catId == null) {
                              _selectedCategoryName = 'All Categories';
                            } else {
                              final cat = categories.firstWhere((c) => c.id == catId);
                              _selectedCategoryName = cat.name;
                            }
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<int?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map(
                            (c) => PopupMenuItem<int?>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedCategoryName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: primaryPurple,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Sort Dropdown Pill
                    Expanded(
                      flex: 4,
                      child: PopupMenuButton<String>(
                        onSelected: (val) {
                          setState(() => _sortBy = val);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'Recent', child: Text('Recent')),
                          PopupMenuItem(value: 'Name A-Z', child: Text('Name A-Z')),
                          PopupMenuItem(value: 'Price: Low to High', child: Text('Price: Low to High')),
                          PopupMenuItem(value: 'Price: High to Low', child: Text('Price: High to Low')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _sortBy.contains(':') ? _sortBy.split(':')[0] : _sortBy,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: primaryPurple,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // View Mode Switcher Button
                    InkWell(
                      onTap: () => setState(() => _isGridView = !_isGridView),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: const Color(0xFF475569),
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Title Section: All Products (count)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'All Products (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Products List or Grid
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.inventory_2_outlined, size: 44, color: primaryPurple),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              allProducts.isEmpty ? 'No products added yet' : 'No matching products found',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Start adding products to create stunning catalogs for your customers.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            if (allProducts.isEmpty) ...[
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Product', style: TextStyle(fontWeight: FontWeight.bold)),
                                onPressed: () => context.push('/add-product'),
                              ),
                            ]
                          ],
                        ),
                      )
                    : _isGridView
                        ? GridView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.75,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final prod = filtered[index];
                              return _buildProductGridTile(
                                context: context,
                                prod: prod,
                                currency: currency,
                                onEdit: () => context.push('/edit-product', extra: prod),
                                onDelete: () => _confirmDelete(prod),
                              );
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 90),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final prod = filtered[index];
                              return _buildProductCard(
                                context: context,
                                prod: prod,
                                currency: currency,
                                onEdit: () => context.push('/edit-product', extra: prod),
                                onDelete: () => _confirmDelete(prod),
                              );
                            },
                          ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading products: $e')),
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
              onPressed: () => context.push('/add-product'),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add Product',
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

  Widget _buildProductCard({
    required BuildContext context,
    required Product prod,
    required String currency,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final hasImage = prod.imagePath != null && File(prod.imagePath!).existsSync();
    final formattedPrice = CurrencyUtils.formatAmount(prod.salePrice, currency: currency);
    final skuText = 'SKU: ${prod.name.substring(0, prod.name.length > 3 ? 3 : prod.name.length).toUpperCase()}-00${prod.id}';
    final stockText = prod.quantity != null && prod.quantity!.isNotEmpty ? prod.quantity : 'ygh';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 76,
              height: 76,
              color: const Color(0xFFF1F5F9),
              child: hasImage
                  ? Image.file(File(prod.imagePath!), fit: BoxFit.cover)
                  : Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: Color(0xFF64748B),
                          size: 32,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 14),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prod.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 4),

                // Price (e.g. ₹ 55.00)
                Text(
                  formattedPrice.startsWith(currency)
                      ? '$currency ${formattedPrice.substring(currency.length).trim()}'
                      : formattedPrice,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 4),

                // SKU & Stock Info
                Text(
                  '$skuText  •  Stock: $stockText',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 8),

                // Date & Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF94A3B8)),
                        SizedBox(width: 4),
                        Text(
                          'Created: Recently',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        // Edit Button
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Color(0xFF7E22CE),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Delete Button
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridTile({
    required BuildContext context,
    required Product prod,
    required String currency,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final hasImage = prod.imagePath != null && File(prod.imagePath!).existsSync();
    final formattedPrice = CurrencyUtils.formatAmount(prod.salePrice, currency: currency);

    return Container(
      padding: const EdgeInsets.all(10),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF1F5F9),
                child: hasImage
                    ? Image.file(File(prod.imagePath!), fit: BoxFit.cover)
                    : const Center(
                        child: Icon(Icons.inventory_2_outlined, color: Color(0xFF64748B), size: 36),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            prod.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            formattedPrice,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF7E22CE), size: 14),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(Product prod) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${prod.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(productRepoProvider).deleteProduct(prod.id);
      ref.invalidate(productsProvider);
    }
  }
}
