import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/catalog_builder_provider.dart';
import '../../services/analytics_service.dart';

class CatalogListStyleSelectScreen extends ConsumerStatefulWidget {
  const CatalogListStyleSelectScreen({super.key});

  @override
  ConsumerState<CatalogListStyleSelectScreen> createState() => _CatalogListStyleSelectScreenState();
}

class _CatalogListStyleSelectScreenState extends ConsumerState<CatalogListStyleSelectScreen> {
  bool _isSaving = false;

  Future<void> _generateAndSaveCatalog() async {
    setState(() => _isSaving = true);
    final builderState = ref.read(catalogBuilderProvider);
    final catalogRepo = ref.read(catalogRepoProvider);
    final allProducts = (await ref.read(productsProvider.future));

    try {
      List<Product> selectedProducts = [];
      if (builderState.selectedProductIds.isNotEmpty) {
        selectedProducts = allProducts.where((p) => builderState.selectedProductIds.contains(p.id)).toList();
      } else if (builderState.selectedCategoryIds.isNotEmpty) {
        selectedProducts = allProducts.where((p) => builderState.selectedCategoryIds.contains(p.categoryId)).toList();
      }
      if (selectedProducts.isEmpty) {
        selectedProducts = allProducts;
      }

      // 3. Create list catalog entry in database
      final catalogName = builderState.name.isEmpty ? 'My List Catalog' : builderState.name;
      final companion = CatalogsCompanion(
        name: drift.Value(catalogName),
        type: const drift.Value('list'),
        styleId: drift.Value(builderState.styleId),
      );

      final catalogId = await catalogRepo.addCatalog(companion);
      final prodIds = selectedProducts.map((p) => p.id).toList();
      await catalogRepo.setCatalogProducts(catalogId, prodIds);

      // Firebase Analytics logging
      AnalyticsService.instance.logCatalogCreated(catalogName: catalogName);
      for (final p in selectedProducts) {
        AnalyticsService.instance.logItemAdded(
          catalogId: catalogId.toString(),
          itemName: p.name,
        );
      }

      ref.invalidate(catalogsProvider);

      final newCatalog = await catalogRepo.getCatalogById(catalogId);

      setState(() => _isSaving = false);

      if (mounted && newCatalog != null) {
        context.push('/export-share', extra: newCatalog);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating catalog: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(catalogBuilderProvider);
    final notifier = ref.read(catalogBuilderProvider.notifier);
    const emeraldGreen = Color(0xFF0B6E4F);
    const pageBg = Color(0xFFFAFAF7);

    final sections = [
      {
        'number': 1,
        'title': 'Simple List',
        'asset': 'assets/list_temp_1.png',
        'styleId': 1,
        'label': 'Style 1',
        'fallback': _buildListPreviewSimple(),
      },
      {
        'number': 2,
        'title': 'Price + Discount',
        'asset': 'assets/list_temp_2.png',
        'styleId': 2,
        'label': 'Style 2',
        'fallback': _buildListPreviewDiscount(),
      },
      {
        'number': 3,
        'title': 'With Description',
        'asset': 'assets/list_temp_3.png',
        'styleId': 3,
        'label': 'Style 3',
        'fallback': _buildListPreviewDescription(),
      },
      {
        'number': 4,
        'title': 'With Size / Quantity',
        'asset': 'assets/list_temp_4.png',
        'styleId': 4,
        'label': 'Style 4',
        'fallback': _buildListPreviewSpecs(),
      },
      {
        'number': 5,
        'title': 'With GST',
        'asset': 'assets/list_temp_5.png',
        'styleId': 5,
        'label': 'Style 5',
        'fallback': _buildListPreviewGst(),
      },
      {
        'number': 6,
        'title': 'With Thumbnail',
        'asset': 'assets/list_temp_6.png',
        'styleId': 6,
        'label': 'Style 6',
        'fallback': _buildListPreviewThumbnail(),
      },
      {
        'number': 7,
        'title': 'With Category',
        'asset': 'assets/list_temp_7.png',
        'styleId': 7,
        'label': 'Style 7',
        'fallback': _buildListPreviewCategory(),
      },
      {
        'number': 8,
        'title': 'With Total Summary',
        'asset': 'assets/list_temp_8.png',
        'styleId': 8,
        'label': 'Style 8',
        'fallback': _buildListPreviewSummary(),
      },
    ];

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: emeraldGreen),
          onPressed: () => context.pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Your List Style',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Select a list template layout for your catalog',
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
            icon: const Icon(Icons.help_outline_rounded, color: emeraldGreen),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select a list template style for displaying your product rows.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stepper Header Progress Bar
                  _buildStepperHeader(),

                  const SizedBox(height: 24),

                  // 8 Vertical Sections
                  for (final item in sections) ...[
                    _buildFullWidthStyleSection(
                      number: item['number'] as int,
                      title: item['title'] as String,
                      assetPath: item['asset'] as String,
                      styleId: item['styleId'] as int,
                      label: item['label'] as String,
                      fallbackChild: item['fallback'] as Widget,
                      isSelected: builderState.styleId == (item['styleId'] as int),
                      onTap: () => notifier.setStyleId(item['styleId'] as int),
                    ),
                    const SizedBox(height: 28),
                  ],
                ],
              ),
            ),
          ),

          // Pinned Bottom Emerald Button
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _generateAndSaveCatalog,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Next Step →',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Full-Width Style Section Component
  Widget _buildFullWidthStyleSection({
    required int number,
    required String title,
    required String assetPath,
    required int styleId,
    required String label,
    required Widget fallbackChild,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const emeraldGreen = Color(0xFF0B6E4F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: [Star Icon] [Number]. [Title] ....... [Chevron Right]
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: emeraldGreen,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$number. $title',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
              onPressed: onTap,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Large Full-Width Template Preview Image Card
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? emeraldGreen : const Color(0xFFE2E8F0),
                width: isSelected ? 2.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    assetPath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: fallbackChild,
                      );
                    },
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: emeraldGreen,
                        size: 26,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Style Label, Centered & Bold below Image
        Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? emeraldGreen : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  // Fallback List Previews
  static Widget _buildListPreviewSimple() {
    return Column(
      children: [
        _buildListRow('Product Name A', '₹299'),
        const Divider(height: 12),
        _buildListRow('Product Name B', '₹499'),
        const Divider(height: 12),
        _buildListRow('Product Name C', '₹199'),
      ],
    );
  }

  static Widget _buildListPreviewDiscount() {
    return Column(
      children: [
        _buildListDiscountRow('Product A', '₹399', '₹299', '25% OFF'),
        const Divider(height: 12),
        _buildListDiscountRow('Product B', '₹599', '₹449', '25% OFF'),
      ],
    );
  }

  static Widget _buildListPreviewDescription() {
    return Column(
      children: [
        _buildListDescRow('Premium Skin Serum', 'Nourishing oil for hydrated skin', '₹299'),
        const Divider(height: 12),
        _buildListDescRow('Gentle Face Wash', 'Deep cleansing natural extract formula', '₹199'),
      ],
    );
  }

  static Widget _buildListPreviewSpecs() {
    return Column(
      children: [
        _buildListSpecRow('Moisturizing Cream', 'Size: 100ml | Stock: 25', '₹350'),
        const Divider(height: 12),
        _buildListSpecRow('Body Lotion', 'Size: 200ml | Stock: 40', '₹450'),
      ],
    );
  }

  static Widget _buildListPreviewGst() {
    return Column(
      children: [
        _buildListGstRow('Organic Shampoo', '₹299', '+ 18% GST'),
        const Divider(height: 12),
        _buildListGstRow('Hair Conditioner', '₹349', '+ 18% GST'),
      ],
    );
  }

  static Widget _buildListPreviewThumbnail() {
    return Column(
      children: [
        _buildListThumbRow(Icons.sanitizer_outlined, 'Face Serum', '₹299'),
        const Divider(height: 12),
        _buildListThumbRow(Icons.water_drop_outlined, 'Hydrating Toner', '₹499'),
      ],
    );
  }

  static Widget _buildListPreviewCategory() {
    return Column(
      children: [
        _buildListCatRow('SKINCARE', 'Anti-Aging Serum', '₹299'),
        const Divider(height: 12),
        _buildListCatRow('HAIRCARE', 'Repair Shampoo', '₹399'),
      ],
    );
  }

  static Widget _buildListPreviewSummary() {
    return Column(
      children: [
        _buildListRow('Product A', '₹299'),
        _buildListRow('Product B', '₹499'),
        Container(
          padding: const EdgeInsets.all(6),
          color: const Color(0xFFECFDF5),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total (2 Items)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
              Text('₹798', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildListRow(String title, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
      ],
    );
  }

  static Widget _buildListDiscountRow(String title, String oldPrice, String newPrice, String badge) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        Row(
          children: [
            Text(oldPrice, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8), decoration: TextDecoration.lineThrough)),
            const SizedBox(width: 4),
            Text(newPrice, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
          ],
        ),
      ],
    );
  }

  static Widget _buildListDescRow(String title, String desc, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(desc, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
      ],
    );
  }

  static Widget _buildListSpecRow(String title, String specs, String price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text(specs, style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
      ],
    );
  }

  static Widget _buildListGstRow(String title, String price, String gst) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
            Text(gst, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  static Widget _buildListThumbRow(IconData icon, String title, String price) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
          child: Icon(icon, size: 14, color: const Color(0xFF0B6E4F)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
      ],
    );
  }

  static Widget _buildListCatRow(String cat, String title, String price) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(3)),
          child: Text(cat, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)))),
        Text(price, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0B6E4F))),
      ],
    );
  }

  // Stepper Bar Header
  Widget _buildStepperHeader() {
    const activeColor = Color(0xFF0B6E4F);

    return Row(
      children: [
        _buildStepCircle(activeColor, isCheck: true),
        Expanded(child: Container(height: 2, color: activeColor)),
        _buildStepCircle(activeColor, isCheck: true),
        Expanded(child: Container(height: 2, color: activeColor)),
        _buildStepCircle(activeColor, isCheck: true),
        Expanded(child: Container(height: 2, color: activeColor)),
        _buildStepCircle(activeColor, text: '4'),
      ],
    );
  }

  Widget _buildStepCircle(Color color, {bool isCheck = false, String? text}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: isCheck
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
            : Text(text ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
