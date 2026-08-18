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

    // --- PAGE 1: COVER PAGE ---
    pdf.addPage(_buildCoverPage(
      profile: profile,
      fonts: fonts,
      logoImage: logoImage,
      catalogName: catalogName,
      productCount: products.length,
    ));

    // --- PAGES 2 ONWARD: PRODUCT GRID PAGES ---
    final int cols = template.columns;
    final List<List<Product>> productRows = [];
    for (var i = 0; i < products.length; i += cols) {
      productRows.add(products.sublist(
          i, i + cols > products.length ? products.length : i + cols));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _buildRunningHeader(context, profile, fonts, logoImage),
        footer: (context) => _buildRunningFooter(profile, fonts),
        build: (pw.Context context) {
          return [
            pw.Column(
              children: productRows.map((row) {
                return pw.Row(
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
                    // Pad empty columns if row is not full
                    if (row.length < cols)
                      for (var k = 0; k < (cols - row.length); k++)
                        pw.Expanded(child: pw.Container()),
                  ],
                );
              }).toList(),
            ),
          ];
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

  /// Builds a List-style catalog: same cover page, running header/footer and
  /// terms page as the Grid catalogs, with the products rendered as a paginated
  /// data table instead of a card grid.
  static Future<File> generateListCatalogPdf({
    required List<Product> products,
    required BusinessProfile profile,
    required String templateId,
    String catalogName = 'Product Catalog',
    Map<int, String>? categoryNames,
    int styleId = 1,
  }) async {
    final pdf = pw.Document();

    // 1. Same embedded Poppins setup as the Grid catalogs
    final fonts = await _loadFonts();

    // 2. Lookup matching ListCatalogTemplate implementation
    final template = templateId.startsWith('list_')
        ? ListTemplateRegistry.getTemplate(templateId)
        : ListTemplateRegistry.getTemplateByStyleId(styleId);

    // 3. Pre-load business logo + product images
    final logoImage = await _loadLogoImage(profile);
    final productImages = await _loadProductImages(products);

    final currency = profile.currency.trim().isEmpty ? '₹' : profile.currency;

    // --- PAGE 1: COVER PAGE (shared with Grid) ---
    pdf.addPage(_buildCoverPage(
      profile: profile,
      fonts: fonts,
      logoImage: logoImage,
      catalogName: catalogName,
      productCount: products.length,
    ));

    // --- PAGES 2 ONWARD: THE TABLE ---
    // Header row repeats automatically at the top of every overflow page.
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

    final bodyRows = <pw.TableRow>[];
    for (var i = 0; i < products.length; i++) {
      final prod = products[i];
      bodyRows.add(
        template.buildProductRow(
          serialNumber: i + 1,
          product: prod,
          currencySymbol: currency,
          mainFont: fonts.main,
          boldFont: fonts.bold,
          categoryName: categoryNames?[prod.categoryId],
          productImage: productImages[prod.id],
        ),
      );
    }

    // Only WithTotalSummaryTemplate contributes an aggregate row.
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
            // Catalog title strip above the table
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  catalogName,
                  style: pw.TextStyle(
                    font: fonts.bold,
                    fontSize: 13,
                    color: _darkText,
                  ),
                ),
                // GSTIN sits next to the table header for the GST template only
                if (template.showsGstin && profile.gstin.trim().isNotEmpty)
                  pw.Text(
                    'GSTIN: ${profile.gstin}',
                    style: pw.TextStyle(
                      font: fonts.bold,
                      fontSize: 9,
                      color: _emeraldGreen,
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 8),

            if (products.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'No products in this catalog.',
                  style: pw.TextStyle(font: fonts.main, fontSize: 11, color: _mutedText),
                ),
              )
            else
              pw.Table(
                columnWidths: template.columnWidths,
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [headerRow, ...bodyRows],
              ),
          ];
        },
      ),
    );

    // --- LAST PAGE: TERMS & CONDITIONS (shared with Grid) ---
    final termsPage = _buildTermsPage(profile: profile, fonts: fonts);
    if (termsPage != null) pdf.addPage(termsPage);

    return _savePdf(pdf);
  }

  // ---------------------------------------------------------------------
  // SHARED BUILDING BLOCKS (used by both Grid and List generation)
  // ---------------------------------------------------------------------

  static Future<_PdfFonts> _loadFonts() async {
    try {
      return _PdfFonts(
        await PdfGoogleFonts.poppinsRegular(),
        await PdfGoogleFonts.poppinsBold(),
      );
    } catch (_) {
      return _PdfFonts(pw.Font.helvetica(), pw.Font.helveticaBold());
    }
  }

  static Future<pw.MemoryImage?> _loadLogoImage(BusinessProfile profile) async {
    if (profile.logoPath == null || profile.logoPath!.trim().isEmpty) return null;
    final logoFile = File(profile.logoPath!);
    if (!await logoFile.exists()) return null;
    try {
      return pw.MemoryImage(await logoFile.readAsBytes());
    } catch (_) {
      return null;
    }
  }

  static Future<Map<int, pw.MemoryImage>> _loadProductImages(
      List<Product> products) async {
    final Map<int, pw.MemoryImage> images = {};
    for (final prod in products) {
      if (prod.imagePath == null || prod.imagePath!.trim().isEmpty) continue;
      final imgFile = File(prod.imagePath!);
      if (!await imgFile.exists()) continue;
      try {
        images[prod.id] = pw.MemoryImage(await imgFile.readAsBytes());
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

            // Logo (Centered, top)
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

            // Business Name
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

            // Address, Phone, Email, Website
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

            // Catalog Title / Subtitle
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

            // Date Generated
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
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(
                font: fonts.main, fontSize: 9, color: _slateText),
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

  /// Returns null when the profile has no terms, so callers can skip the page.
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

            // Contact Call To Action Box
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


  /// Copies a generated catalog PDF out of the app's temp folder into a
  /// user-visible location and returns the saved file.
  ///
  /// Tries the public Downloads folder first; if scoped storage blocks that,
  /// it falls back to external app storage and finally to app documents, so
  /// the save never silently fails. Read the returned file's path to tell the
  /// user where it actually landed.
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

    // Should be unreachable: app documents is always writable.
    final fallback = await getApplicationDocumentsDirectory();
    final target = File('${fallback.path}/$fileName');
    await target.writeAsBytes(bytes, flush: true);
    return target;
  }

  /// Candidate save locations, most user-visible first.
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
