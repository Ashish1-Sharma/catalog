import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';
import 'catalog_html_template.dart';

/// Exception thrown when PDF generation fails.
class PdfGenerationException implements Exception {
  final String message;
  final Object? originalError;
  final StackTrace? stackTrace;

  PdfGenerationException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() =>
      'PdfGenerationException: $message${originalError != null ? ' ($originalError)' : ''}';
}

/// Helper function to compress an image file to max 400px longest side
/// at JPEG quality 80 and return base64 encoded string.
Future<String?> _compressAndEncodeImage(String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) return null;

  try {
    final Uint8List? compressed = await FlutterImageCompress.compressWithFile(
      imagePath,
      minWidth: 400,
      minHeight: 400,
      quality: 80,
      format: CompressFormat.jpeg,
    );

    if (compressed != null && compressed.isNotEmpty) {
      return base64Encode(compressed);
    }

    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } catch (e) {
    try {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }
}

/// Primary public entry point function for generating catalog PDF using HTML/CSS template
/// and flutter_html_to_pdf. Returns PDF bytes as Uint8List.
Future<Uint8List> generateCatalogPdf({
  required List<Product> products,
  required BusinessProfile profile,
  String catalogName = 'Product Catalog',
  Map<int, String>? categoryNames,
  String templateId = 'grid_1',
  String catalogType = 'grid',
  int styleId = 1,
  void Function(int done, int total)? onProgress,
}) async {
  return HtmlPdfService.generateCatalogPdf(
    products: products,
    profile: profile,
    catalogName: catalogName,
    categoryNames: categoryNames,
    templateId: templateId,
    catalogType: catalogType,
    styleId: styleId,
    onProgress: onProgress,
  );
}

class HtmlPdfService {
  /// Generates a PDF document from catalog data using flutter_html_to_pdf.
  static Future<Uint8List> generateCatalogPdf({
    required List<Product> products,
    required BusinessProfile profile,
    String catalogName = 'Product Catalog',
    Map<int, String>? categoryNames,
    String templateId = 'grid_1',
    String catalogType = 'grid',
    int styleId = 1,
    void Function(int done, int total)? onProgress,
  }) async {
    File? tempHtmlFile;
    File? generatedPdfFile;

    try {
      final totalItems = (profile.logoPath != null ? 1 : 0) + products.length;
      int doneCount = 0;

      // 1. Preprocess business logo image
      String? logoBase64;
      if (profile.logoPath != null && profile.logoPath!.isNotEmpty) {
        logoBase64 = await _compressAndEncodeImage(profile.logoPath!);
        doneCount++;
        onProgress?.call(doneCount, totalItems);
      }

      // 2. Preprocess product images
      final Map<int, String> productImagesBase64 = {};
      for (final prod in products) {
        if (prod.imagePath != null && prod.imagePath!.isNotEmpty) {
          final b64 = await _compressAndEncodeImage(prod.imagePath!);
          if (b64 != null) {
            productImagesBase64[prod.id] = b64;
          }
        }
        doneCount++;
        onProgress?.call(doneCount, totalItems);
      }

      // 3. Build HTML string via pure template function
      final htmlContent = buildCatalogHtml(
        products: products,
        profile: profile,
        catalogName: catalogName,
        categoryNames: categoryNames,
        catalogType: catalogType,
        styleId: styleId,
        logoBase64: logoBase64,
        productImagesBase64: productImagesBase64,
      );

      // 4. Write HTML string to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      tempHtmlFile = File('${tempDir.path}/catalog_$timestamp.html');
      await tempHtmlFile.writeAsString(htmlContent);

      // 5. Convert HTML file to PDF via flutter_html_to_pdf
      final pdfTargetName = 'catalog_pdf_$timestamp';
      generatedPdfFile = await FlutterHtmlToPdf.convertFromHtmlFilePath(
        tempHtmlFile.path,
        tempDir.path,
        pdfTargetName,
      );

      // 6. Read PDF bytes
      final Uint8List pdfBytes = await generatedPdfFile.readAsBytes();
      return pdfBytes;
    } catch (e, st) {
      debugPrint('HtmlPdfService error generating PDF: $e\n$st');
      throw PdfGenerationException(
        'Failed to generate catalog PDF: ${e.toString()}',
        e,
        st,
      );
    } finally {
      // 7. Cleanup temp HTML and PDF files
      if (tempHtmlFile != null && await tempHtmlFile.exists()) {
        try {
          await tempHtmlFile.delete();
        } catch (_) {}
      }
      if (generatedPdfFile != null && await generatedPdfFile.exists()) {
        try {
          await generatedPdfFile.delete();
        } catch (_) {}
      }
    }
  }
}

