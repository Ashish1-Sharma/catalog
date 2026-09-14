import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../../core/services/image_export_service.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/product_image_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../services/analytics_service.dart';

class ExportShareScreen extends ConsumerStatefulWidget {
  final Catalog catalog;

  const ExportShareScreen({super.key, required this.catalog});

  @override
  ConsumerState<ExportShareScreen> createState() => _ExportShareScreenState();
}

class _ExportShareScreenState extends ConsumerState<ExportShareScreen> {
  static const Color _primaryPurple = Color(0xFF6366F1);
  static const Color _deepPurple = Color(0xFF4338CA);

  bool _isBusy = false;

  /// The generated catalog PDF, built once and reused by the preview, the
  /// download button and the share sheet.
  File? _pdfFile;

  // Created once — building it inside build() restarted the query on every
  // setState, blanking the screen mid-export.
  late final Future<List<Product>> _productsFuture = _loadProductsForCatalog();

  List<Product> _loadedProducts = [];

  /// Products whose image file is gone from disk, so the user is told why a
  /// photo-only catalog would come out empty instead of silently getting one.
  int _missingImageCount = 0;

  // -------------------------------------------------------------------
  // PDF
  // -------------------------------------------------------------------

  /// Builds the catalog PDF exactly as configured when the catalog was
  /// created (grid vs list, and the chosen style), caching the result so the
  /// preview, download and share all use the same file.
  Future<File> _buildPdf() async {
    final cached = _pdfFile;
    if (cached != null) return cached;

    final profile = ref.read(businessProfileProvider).value;
    final safeProfile = profile ??
        const BusinessProfile(
          id: 0,
          userId: '0',
          businessName: 'Business Name',
          address: '',
          email: '',
          phone: '',
          website: '',
          gstin: '',
          currency: '₹',
          termsAndConditions: '',
        );

    // Category id -> name, used by templates that display a category column
    final categories = await ref.read(categoryRepoProvider).getCategories();
    final categoryNames = {for (final c in categories) c.id: c.name};

    final isList = widget.catalog.type == 'list';
    final file = isList
        ? await PdfExportService.generateListCatalogPdf(
            products: _loadedProducts,
            profile: safeProfile,
            templateId: widget.catalog.styleId.toString(),
            catalogName: widget.catalog.name,
            categoryNames: categoryNames,
            styleId: widget.catalog.styleId,
          )
        : await PdfExportService.generateCatalogPdf(
            products: _loadedProducts,
            profile: safeProfile,
            templateId: widget.catalog.styleId.toString(),
            catalogName: widget.catalog.name,
            categoryNames: categoryNames,
            catalogType: widget.catalog.type,
            styleId: widget.catalog.styleId,
          );

    _pdfFile = file;
    return file;
  }

  /// Bytes for the on-screen preview.
  Future<Uint8List> _pdfBytes(_) async {
    final file = await _buildPdf();
    return file.readAsBytes();
  }

  Future<void> _downloadPdf() async {
    setState(() => _isBusy = true);
    try {
      final pdf = await _buildPdf();
      final saved =
          await PdfExportService.savePdfToDevice(pdf, widget.catalog.name);

      AnalyticsService.instance.logCatalogExported(
        catalogId: widget.catalog.id.toString(),
        format: 'pdf',
      );

      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to ${saved.parent.path}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: _sharePdf,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save PDF: $e')),
      );
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isBusy = true);
    try {
      final pdf = await _buildPdf();

      AnalyticsService.instance.logCatalogShared(
        catalogId: widget.catalog.id.toString(),
        method: 'pdf',
      );

      if (!mounted) return;
      setState(() => _isBusy = false);
      await ImageExportService.shareFile(
        pdf,
        text: 'Check out our product catalog: ${widget.catalog.name}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share PDF: $e')),
      );
    }
  }

  // -------------------------------------------------------------------
  // DATA
  // -------------------------------------------------------------------

  Future<List<Product>> _loadProductsForCatalog() async {
    final catalogRepo = ref.read(catalogRepoProvider);
    final productRepo = ref.read(productRepoProvider);

    // Last-chance rescue for images still in a temporary cache path.
    try {
      final repaired = await productRepo.repairImagePaths();
      // Cached product lists still hold the old paths — drop them so other
      // screens (and the edit form) see the repaired ones.
      if (repaired > 0) ref.invalidate(productsProvider);
    } catch (_) {}

    final catProds = await catalogRepo.getProductsForCatalog(widget.catalog.id);
    if (catProds.isNotEmpty) {
      return catProds;
    }
    // Fallback: if no catalog_products mappings exist, load all products
    final allProds = await productRepo.getProducts();
    if (allProds.isNotEmpty) {
      final prodIds = allProds.map((p) => p.id).toList();
      await catalogRepo.setCatalogProducts(widget.catalog.id, prodIds);
      return allProds;
    }
    return [];
  }

  // -------------------------------------------------------------------
  // UI
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: _primaryPurple, size: 24),
          onPressed: () => context.go('/dashboard'),
          tooltip: 'Home',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Catalog Preview',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.catalog.name,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.ios_share_rounded,
                  color: _primaryPurple, size: 20),
              onPressed: _isBusy ? null : _sharePdf,
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = snapshot.data ?? [];
          _loadedProducts = products;
          _missingImageCount = products
              .where((p) => ProductImageService.isMissing(p.imagePath))
              .length;

          return Column(
            children: [
              if (_missingImageCount > 0)
                _buildMissingImagesBanner(products.length),
              _buildSummaryStrip(products.length),

              // Scrollable, pinch-to-zoom PDF preview
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PdfPreview(
                    build: _pdfBytes,
                    // We provide our own Download / Share buttons below.
                    useActions: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    maxPageWidth: 900,
                    scrollViewDecoration:
                        const BoxDecoration(color: Color(0xFFF1F5F9)),
                    pdfFileName: '${widget.catalog.name}.pdf',
                    loadingWidget:
                        const Center(child: CircularProgressIndicator()),
                    onError: (context, error) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Could not render this catalog.\n$error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              _buildActionBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissingImagesBanner(int totalProducts) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.image_not_supported_outlined,
              color: Color(0xFFB45309), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$_missingImageCount of $totalProducts products have a missing image file. '
              'Re-add their photos so they show up in the catalog.',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStrip(int productCount) {
    final isGrid = widget.catalog.type == 'grid';
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E7FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isGrid
                  ? Icons.grid_view_rounded
                  : Icons.format_list_bulleted_rounded,
              color: _primaryPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.catalog.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$productCount items  •  ${isGrid ? 'Grid' : 'List'} Style ${widget.catalog.styleId}',
                  style: const TextStyle(fontSize: 11, color: _deepPurple),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Download PDF
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepPurple,
                    side: const BorderSide(color: _deepPurple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isBusy ? null : _downloadPdf,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Download',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Share Catalog
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepPurple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isBusy ? null : _sharePdf,
                  icon: _isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Icon(Icons.share_rounded, size: 18),
                  label: const Text(
                    'Share',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Home Screen Button
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF045435),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Home',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
