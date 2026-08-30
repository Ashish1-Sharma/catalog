import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/database/app_database.dart';
import '../../features/catalog_builder/templates/grid_catalog_template.dart';
import '../../features/catalog_builder/templates/list/list_catalog_template.dart';

/// Fonts embedded once per document and passed down to every page/template.
class _PdfFonts {
  final pw.Font main;
  final pw.Font bold;
  const _PdfFonts(this.main, this.bold);
}

class PdfExportService {
  static const PdfColor _emeraldGreen = PdfColor.fromInt(0xFF0B6E4F);
  static const PdfColor _warmGold = PdfColor.fromInt(0xFFD4A537);
  static const PdfColor _darkText = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor _subText = PdfColor.fromInt(0xFF475569);
  static const PdfColor _mutedText = PdfColor.fromInt(0xFF94A3B8);
  static const PdfColor _divider = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor _slateText = PdfColor.fromInt(0xFF64748B);

  // ---------------------------------------------------------------------
  // GRID CATALOG
  // ---------------------------------------------------------------------

  static Future<File> generateCatalogPdf({
    required List<Product> products,
    required BusinessProfile profile,
    required String templateId,
    String catalogName = 'Product Catalog',
    Map<int, String>? categoryNames,
    String catalogType = 'grid',
    int styleId = 1,
  }) async {
    final pdf = pw.Document();

    // 1. Embed Google Fonts (Poppins) for clean sans-serif typography
    final fonts = await _loadFonts();

    // 2. Lookup matching GridCatalogTemplate implementation
    final template = templateId.startsWith('grid_')
        ? GridTemplateRegistry.getTemplate(templateId)
        : GridTemplateRegistry.getTemplateByStyleId(styleId);

    // 3. Pre-load business logo + product images
    final logoImage = await _loadLogoImage(profile);
    final productImages = await _loadProductImages(products);

    final currency = profile.currency.trim().isEmpty ? '₹' : profile.currency;

    // Build category map
    final Map<int, String> categoryMap = {};
    for (final prod in products) {
      final catName = categoryNames?[prod.categoryId];
      if (catName != null && catName.trim().isNotEmpty) {
        categoryMap[prod.categoryId] = catName.trim();
      } else {
        categoryMap[prod.categoryId] = 'Category ${prod.categoryId}';
      }
    }

    // --- PAGE 1: COVER PAGE ---
    pdf.addPage(_buildCoverPage(
      profile: profile,
      fonts: fonts,
      logoImage: logoImage,
      catalogName: catalogName,
      productCount: products.length,
    ));

    // --- PAGE 2: TABLE OF CONTENTS (Categories Overview) ---
    if (categoryMap.isNotEmpty) {
      pdf.addPage(_buildTableOfContentsPage(
        categoryMap: categoryMap,
        fonts: fonts,
        catalogName: catalogName,
        profile: profile,
      ));
    }

    // --- PAGES 3 ONWARD: PRODUCT GRID PAGES GROUPED BY CATEGORY ---
    final int cols = template.columns;
    final Map<int, List<Product>> categoryProductsMap = {};
    for (final prod in products) {
      categoryProductsMap.putIfAbsent(prod.categoryId, () => []).add(prod);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildRunningHeader(context, profile, fonts, logoImage),
        footer: (context) => _buildRunningFooter(profile, fonts),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          for (final entry in categoryProductsMap.entries) {
            final catId = entry.key;
            final catProds = entry.value;
            final catName = categoryMap[catId] ?? 'Category $catId';

            // Category Section Destination Anchor
            widgets.add(
              pw.Anchor(
                name: 'cat_$catId',
                child: pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.only(top: 8, bottom: 8),
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF1F5F9),
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        catName.toUpperCase(),
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 12,
                          color: _emeraldGreen,
                        ),
                      ),
                      pw.Text(
                        '${catProds.length} items',
                        style: pw.TextStyle(
                          font: fonts.main,
                          fontSize: 9,
                          color: _slateText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

            // Chunk products into rows for grid template
            final List<List<Product>> rows = [];
            for (var i = 0; i < catProds.length; i += cols) {
              rows.add(catProds.sublist(
                  i, i + cols > catProds.length ? catProds.length : i + cols));
            }

            for (final row in rows) {
              widgets.add(
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    for (final prod in row)
                      pw.Expanded(
                        child: template.buildProductCard(
                          product: prod,
                          currencySymbol: currency,
                          mainFont: fonts.main,
                          boldFont: fonts.bold,
                          categoryName: categoryNames?[prod.categoryId],
                          productImage: productImages[prod.id],
                        ),
                      ),
                    if (row.length < cols)
                      for (var k = 0; k < (cols - row.length); k++)
                        pw.Expanded(child: pw.Container()),
                  ],
                ),
              );
            }

            widgets.add(pw.SizedBox(height: 10));
          }

          return widgets;
        },
      ),
    );

    // --- LAST PAGE: TERMS & CONDITIONS PAGE ---
    final termsPage = _buildTermsPage(profile: profile, fonts: fonts);
    if (termsPage != null) pdf.addPage(termsPage);

    return _savePdf(pdf);
  }

  // ---------------------------------------------------------------------
  // LIST CATALOG
  // ---------------------------------------------------------------------

  static Future<File> generateListCatalogPdf({
    required List<Product> products,
    required BusinessProfile profile,
    required String templateId,
    String catalogName = 'Product Catalog',
    Map<int, String>? categoryNames,
    int styleId = 1,
  }) async {
    final pdf = pw.Document();

    final fonts = await _loadFonts();

    final template = templateId.startsWith('list_')
        ? ListTemplateRegistry.getTemplate(templateId)
        : ListTemplateRegistry.getTemplateByStyleId(styleId);

    final logoImage = await _loadLogoImage(profile);
    final productImages = await _loadProductImages(products);

    final currency = profile.currency.trim().isEmpty ? '₹' : profile.currency;

    final Map<int, String> categoryMap = {};
    for (final prod in products) {
      final catName = categoryNames?[prod.categoryId];
      if (catName != null && catName.trim().isNotEmpty) {
        categoryMap[prod.categoryId] = catName.trim();
      } else {
        categoryMap[prod.categoryId] = 'Category ${prod.categoryId}';
      }
    }

    // --- PAGE 1: COVER PAGE ---
    pdf.addPage(_buildCoverPage(
      profile: profile,
      fonts: fonts,
      logoImage: logoImage,
      catalogName: catalogName,
      productCount: products.length,
    ));

    // --- PAGE 2: TABLE OF CONTENTS ---
    if (categoryMap.isNotEmpty) {
      pdf.addPage(_buildTableOfContentsPage(
        categoryMap: categoryMap,
        fonts: fonts,
        catalogName: catalogName,
        profile: profile,
      ));
    }

    // --- PAGES 3 ONWARD: THE TABLE ---
    final headerRow = pw.TableRow(
      repeat: true,
      decoration: ListTemplateStyle.headerDecoration,
      children: [
        for (var i = 0; i < template.columnHeaders.length; i++)
          ListCellBuilder.headerCell(
            template.columnHeaders[i],
            fonts.bold,
            alignment: i == 0
                ? pw.Alignment.center
                : (i >= 3 ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
          ),
      ],
    );

    final Map<int, List<Product>> categoryProductsMap = {};
    for (final prod in products) {
      categoryProductsMap.putIfAbsent(prod.categoryId, () => []).add(prod);
    }

    final bodyRows = <pw.TableRow>[];
    int serialCounter = 1;

    for (final entry in categoryProductsMap.entries) {
      final catId = entry.key;
      final catProds = entry.value;
      final catName = categoryMap[catId] ?? 'Category $catId';

      // Section Category Row with Anchor
      bodyRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF1F5F9)),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: pw.Anchor(
                name: 'cat_$catId',
                child: pw.Text(
                  catName.toUpperCase(),
                  style: pw.TextStyle(font: fonts.bold, fontSize: 11, color: _emeraldGreen),
                ),
              ),
            ),
            for (var c = 1; c < template.columnHeaders.length; c++)
              pw.Container(padding: const pw.EdgeInsets.all(4)),
          ],
        ),
      );

      for (var i = 0; i < catProds.length; i++) {
        final prod = catProds[i];
        bodyRows.add(
          template.buildProductRow(
            serialNumber: serialCounter++,
            product: prod,
            currencySymbol: currency,
            mainFont: fonts.main,
            boldFont: fonts.bold,
            categoryName: categoryNames?[prod.categoryId],
            productImage: productImages[prod.id],
          ),
        );
      }
    }

    if (template.hasTotalRow) {
      final totalRow = template.buildTotalRow(
        products: products,
        currencySymbol: currency,
        mainFont: fonts.main,
        boldFont: fonts.bold,
      );
      if (totalRow != null) bodyRows.add(totalRow);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildRunningHeader(context, profile, fonts, logoImage),
        footer: (context) => _buildRunningFooter(profile, fonts),
        build: (pw.Context context) {
          return [
            pw.Table(
              columnWidths: template.columnWidths,
              border: const pw.TableBorder(bottom: pw.BorderSide(color: _divider)),
              children: [
                headerRow,
                ...bodyRows,
              ],
            ),
          ];
        },
      ),
    );

    final termsPage = _buildTermsPage(profile: profile, fonts: fonts);
    if (termsPage != null) pdf.addPage(termsPage);

    return _savePdf(pdf);
  }

  // ---------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------

  static Future<_PdfFonts> _loadFonts() async {
    final main = await PdfGoogleFonts.poppinsRegular();
    final bold = await PdfGoogleFonts.poppinsBold();
    return _PdfFonts(main, bold);
  }

  static Future<pw.MemoryImage?> _loadLogoImage(BusinessProfile profile) async {
    if (profile.logoPath == null) return null;
    final file = File(profile.logoPath!);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static Future<Map<int, pw.MemoryImage>> _loadProductImages(
      List<Product> products) async {
    final images = <int, pw.MemoryImage>{};
    for (final prod in products) {
      if (prod.imagePath == null) continue;
      final file = File(prod.imagePath!);
      if (!await file.exists()) continue;
      try {
        final bytes = await file.readAsBytes();
        images[prod.id] = pw.MemoryImage(bytes);
      } catch (_) {}
    }
    return images;
  }

  static pw.Page _buildCoverPage({
    required BusinessProfile profile,
    required _PdfFonts fonts,
    required pw.MemoryImage? logoImage,
    required String catalogName,
    required int productCount,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Spacer(),

            if (logoImage != null)
              pw.Container(
                width: 100,
                height: 100,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              )
            else
              pw.Container(
                width: 80,
                height: 80,
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFECFDF5),
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    _getInitials(profile.businessName),
                    style: pw.TextStyle(
                        font: fonts.bold, fontSize: 26, color: _emeraldGreen),
                  ),
                ),
              ),

            pw.Text(
              profile.businessName.toUpperCase(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 22,
                color: _emeraldGreen,
              ),
            ),

            pw.SizedBox(height: 10),

            if (profile.address.trim().isNotEmpty)
              pw.Text(
                profile.address,
                textAlign: pw.TextAlign.center,
                style:
                    pw.TextStyle(font: fonts.main, fontSize: 11, color: _subText),
              ),
            pw.SizedBox(height: 4),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (profile.phone.trim().isNotEmpty)
                  pw.Text('Phone: ${profile.phone}  ',
                      style: pw.TextStyle(
                          font: fonts.main, fontSize: 10, color: _subText)),
                if (profile.email.trim().isNotEmpty)
                  pw.Text('Email: ${profile.email}',
                      style: pw.TextStyle(
                          font: fonts.main, fontSize: 10, color: _subText)),
              ],
            ),

            if (profile.website.trim().isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(profile.website,
                  style: pw.TextStyle(
                      font: fonts.main, fontSize: 10, color: _subText)),
            ],

            if (profile.gstin.trim().isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text('GSTIN: ${profile.gstin}',
                  style: pw.TextStyle(
                      font: fonts.bold, fontSize: 10, color: _darkText)),
            ],

            if (profile.currency.trim().isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text('All prices in ${profile.currency}',
                  style: pw.TextStyle(
                      font: fonts.main, fontSize: 9, color: _subText)),
            ],

            pw.SizedBox(height: 30),
            pw.Container(width: 80, height: 2, color: _warmGold),
            pw.SizedBox(height: 20),

            pw.Text(
              catalogName.toUpperCase(),
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 18,
                color: _darkText,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '$productCount Products Included',
              style: pw.TextStyle(
                font: fonts.main,
                fontSize: 12,
                color: _warmGold,
              ),
            ),

            pw.Spacer(),

            pw.Text(
              'Generated on: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style:
                  pw.TextStyle(font: fonts.main, fontSize: 9, color: _mutedText),
            ),
          ],
        );
      },
    );
  }

  static pw.Page _buildTableOfContentsPage({
    required Map<int, String> categoryMap,
    required _PdfFonts fonts,
    required String catalogName,
    required BusinessProfile profile,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        final entries = categoryMap.entries.toList();
        return pw.Anchor(
          name: 'toc_page',
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'TABLE OF CONTENTS',
                        style: pw.TextStyle(
                          font: fonts.bold,
                          fontSize: 18,
                          color: _emeraldGreen,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Click on any category to jump directly to its products',
                        style: pw.TextStyle(
                          font: fonts.main,
                          fontSize: 10,
                          color: _slateText,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    profile.businessName,
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 11,
                      color: _warmGold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Container(height: 1.5, color: _emeraldGreen),
              pw.SizedBox(height: 20),

              pw.Expanded(
                child: pw.ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (ctx, index) {
                    final catId = entries[index].key;
                    final catName = entries[index].value;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Link(
                        destination: 'cat_$catId',
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFFF8FAFC),
                            borderRadius: pw.BorderRadius.circular(8),
                            border: pw.Border.all(color: const PdfColor.fromInt(0xFFCBD5E1), width: 1),
                          ),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const pw.BoxDecoration(
                                      color: PdfColor.fromInt(0xFFECFDF5),
                                      shape: pw.BoxShape.circle,
                                    ),
                                    child: pw.Center(
                                      child: pw.Text(
                                        '${index + 1}',
                                        style: pw.TextStyle(font: fonts.bold, fontSize: 10, color: _emeraldGreen),
                                      ),
                                    ),
                                  ),
                                  pw.SizedBox(width: 12),
                                  pw.Text(
                                    catName,
                                    style: pw.TextStyle(
                                      font: fonts.bold,
                                      fontSize: 13,
                                      color: _darkText,
                                    ),
                                  ),
                                ],
                              ),
                              pw.Text(
                                'Go to section  ➜',
                                style: pw.TextStyle(
                                  font: fonts.bold,
                                  fontSize: 10,
                                  color: _emeraldGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFEF3C7),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Tip: ',
                      style: pw.TextStyle(font: fonts.bold, fontSize: 9, color: const PdfColor.fromInt(0xFF92400E)),
                    ),
                    pw.Text(
                      'Tap the "TOC 🏠" button on the top right of any page to return here.',
                      style: pw.TextStyle(font: fonts.main, fontSize: 9, color: const PdfColor.fromInt(0xFF92400E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static pw.Widget _buildRunningHeader(
    pw.Context context,
    BusinessProfile profile,
    _PdfFonts fonts,
    pw.MemoryImage? logoImage,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.only(bottom: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _divider, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              if (logoImage != null)
                pw.Container(
                  width: 20,
                  height: 20,
                  margin: const pw.EdgeInsets.only(right: 6),
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
              pw.Text(
                profile.businessName,
                style: pw.TextStyle(
                    font: fonts.bold, fontSize: 11, color: _emeraldGreen),
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Link(
                destination: 'toc_page',
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFECFDF5),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: const PdfColor.fromInt(0xFFA7F3D0)),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        'TOC ',
                        style: pw.TextStyle(font: fonts.bold, fontSize: 8, color: _emeraldGreen),
                      ),
                      pw.Text(
                        '🏠',
                        style: pw.TextStyle(font: fonts.main, fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                    font: fonts.main, fontSize: 9, color: _slateText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRunningFooter(BusinessProfile profile, _PdfFonts fonts) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Center(
        child: pw.Text(
          'Contact: ${profile.phone} | ${profile.email}',
          style: pw.TextStyle(font: fonts.main, fontSize: 8, color: _mutedText),
        ),
      ),
    );
  }

  static pw.Page? _buildTermsPage({
    required BusinessProfile profile,
    required _PdfFonts fonts,
  }) {
    if (profile.termsAndConditions.trim().isEmpty) return null;

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Terms & Conditions',
              style: pw.TextStyle(
                font: fonts.bold,
                fontSize: 16,
                color: _emeraldGreen,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 1, color: _divider),
            pw.SizedBox(height: 14),

            pw.Text(
              profile.termsAndConditions,
              style: pw.TextStyle(
                font: fonts.main,
                fontSize: 10,
                color: _darkText,
                lineSpacing: 1.4,
              ),
            ),

            pw.Spacer(),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFECFDF5),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(12)),
                border: pw.Border(
                  top: pw.BorderSide(color: _emeraldGreen, width: 1),
                  bottom: pw.BorderSide(color: _emeraldGreen, width: 1),
                  left: pw.BorderSide(color: _emeraldGreen, width: 1),
                  right: pw.BorderSide(color: _emeraldGreen, width: 1),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Contact us to place your order',
                    style: pw.TextStyle(
                        font: fonts.bold, fontSize: 13, color: _emeraldGreen),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    'Phone: ${profile.phone}  |  Email: ${profile.email}',
                    style: pw.TextStyle(
                        font: fonts.main, fontSize: 10, color: _darkText),
                  ),
                  if (profile.website.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Website: ${profile.website}',
                      style: pw.TextStyle(
                          font: fonts.main, fontSize: 9, color: _subText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<File> _savePdf(pw.Document pdf) async {
    final outputDir = await getTemporaryDirectory();
    final file = File(
        '${outputDir.path}/catalog_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<File> savePdfToDevice(File pdfFile, String catalogName) async {
    final bytes = await pdfFile.readAsBytes();
    final trimmed = catalogName.trim();
    final sanitized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '').trim();
    final base = sanitized.isEmpty ? 'catalog' : sanitized.replaceAll(' ', '_');
    final fileName = '${base}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    for (final dir in await _saveTargets()) {
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        final target = File('${dir.path}/$fileName');
        await target.writeAsBytes(bytes, flush: true);
        return target;
      } catch (e) {
        debugPrint('PdfExportService: cannot save to ${dir.path} - $e');
      }
    }

    final fallback = await getApplicationDocumentsDirectory();
    final target = File('${fallback.path}/$fileName');
    await target.writeAsBytes(bytes, flush: true);
    return target;
  }

  static Future<List<Directory>> _saveTargets() async {
    final targets = <Directory>[];

    if (Platform.isAndroid) {
      targets.add(Directory('/storage/emulated/0/Download'));
      try {
        final external = await getExternalStorageDirectory();
        if (external != null) targets.add(external);
      } catch (_) {}
    }

    targets.add(await getApplicationDocumentsDirectory());
    return targets;
  }

  static Future<void> printOrSharePdf(File pdfFile) async {
    await Printing.sharePdf(
      bytes: await pdfFile.readAsBytes(),
      filename: pdfFile.path.split('/').last,
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'CM';
  }
}
