import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'simple_list_template.dart';
import 'price_discount_template.dart';
import 'with_description_template.dart';
import 'with_size_qty_template.dart';
import 'with_gst_template.dart';
import 'with_thumbnail_template.dart';
import 'with_category_template.dart';
import 'with_total_summary_template.dart';

/// Shared palette for every List catalog template.
class ListTemplateStyle {
  static final PdfColor emerald = PdfColor.fromHex('#0B6E4F');
  static final PdfColor emeraldLight = PdfColor.fromHex('#ECFDF5');
  static final PdfColor darkText = PdfColor.fromHex('#0F172A');
  static final PdfColor subText = PdfColor.fromHex('#64748B');
  static final PdfColor mutedText = PdfColor.fromHex('#94A3B8');
  static final PdfColor divider = PdfColor.fromHex('#E2E8F0');
  static final PdfColor white = PdfColor.fromHex('#FFFFFF');
  static final PdfColor offWhite = PdfColor.fromHex('#FAFAF7');
  static final PdfColor gold = PdfColor.fromHex('#D4A537');

  /// Zebra striping: even rows white, odd rows off-white.
  static PdfColor rowFill(int serialNumber) =>
      serialNumber.isEven ? offWhite : white;

  /// Placeholder shown wherever a product field is missing.
  static const String emptyValue = '—';

  /// Zebra fill + thin light-gray divider under every product row.
  static pw.BoxDecoration rowDecoration(int serialNumber) {
    return pw.BoxDecoration(
      color: rowFill(serialNumber),
      border: pw.Border(bottom: pw.BorderSide(color: divider, width: 0.5)),
    );
  }

  static pw.BoxDecoration get headerDecoration =>
      pw.BoxDecoration(color: emerald);

  static pw.BoxDecoration get totalDecoration =>
      pw.BoxDecoration(color: emerald);
}

/// A single List catalog design. Everything except [columnHeaders] and
/// [buildProductRow] (page structure, cover page, terms page, pagination,
/// fonts, currency) is shared and lives in `PdfExportService`.
abstract class ListCatalogTemplate {
  String get id;
  String get displayName;
  List<String> get columnHeaders;

  /// Relative widths for each column, keyed by column index.
  Map<int, pw.TableColumnWidth> get columnWidths;

  /// Set to true by templates that need the business GSTIN rendered above
  /// the table (only `list_gst` does).
  bool get showsGstin => false;

  /// Set to true by templates that append an aggregate row after the last
  /// product row (only `list_total_summary` does).
  bool get hasTotalRow => false;

  pw.TableRow buildProductRow({
    required int serialNumber,
    required Product product,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
    String? categoryName,
    pw.MemoryImage? productImage,
  });

  /// Aggregate row appended after all product rows. Only meaningful when
  /// [hasTotalRow] is true; the default returns null so most templates ignore it.
  pw.TableRow? buildTotalRow({
    required List<Product> products,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
  }) =>
      null;
}

/// Shared cell helpers so all 8 templates render with identical metrics.
class ListCellBuilder {
  static const double _rowVPad = 6;
  static const double _rowHPad = 6;
  static const double thumbSize = 40;

  static pw.Widget headerCell(
    String text,
    pw.Font boldFont, {
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: _rowHPad, vertical: 8),
      child: pw.Text(
        text.toUpperCase(),
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 8.5,
          color: ListTemplateStyle.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static pw.Widget textCell(
    String text,
    pw.Font font, {
    double fontSize = 9,
    PdfColor? color,
    pw.Alignment alignment = pw.Alignment.centerLeft,
    bool strikeThrough = false,
    int maxLines = 2,
  }) {
    return pw.Container(
      alignment: alignment,
      padding:
          const pw.EdgeInsets.symmetric(horizontal: _rowHPad, vertical: _rowVPad),
      child: pw.Text(
        text,
        maxLines: maxLines,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color ?? ListTemplateStyle.darkText,
          decoration:
              strikeThrough ? pw.TextDecoration.lineThrough : pw.TextDecoration.none,
        ),
      ),
    );
  }

  static pw.Widget serialCell(int serialNumber, pw.Font mainFont) {
    return textCell(
      serialNumber.toString(),
      mainFont,
      fontSize: 9,
      color: ListTemplateStyle.subText,
      alignment: pw.Alignment.center,
      maxLines: 1,
    );
  }

  static pw.Widget nameCell(String name, pw.Font boldFont) {
    return textCell(name, boldFont, fontSize: 9.5, maxLines: 2);
  }

  static pw.Widget priceCell(
    double amount,
    String currencySymbol,
    pw.Font boldFont, {
    bool emphasised = true,
  }) {
    return textCell(
      ListCurrency.format(amount, currencySymbol),
      boldFont,
      fontSize: 9.5,
      color: emphasised ? ListTemplateStyle.emerald : ListTemplateStyle.darkText,
      alignment: pw.Alignment.centerRight,
      maxLines: 1,
    );
  }

  static pw.Widget mrpCell(
    double amount,
    String currencySymbol,
    pw.Font mainFont, {
    bool strikeThrough = false,
  }) {
    return textCell(
      ListCurrency.format(amount, currencySymbol),
      mainFont,
      fontSize: 9,
      color:
          strikeThrough ? ListTemplateStyle.mutedText : ListTemplateStyle.darkText,
      alignment: pw.Alignment.centerRight,
      strikeThrough: strikeThrough,
      maxLines: 1,
    );
  }

  /// Small square product thumbnail with rounded corners, or a neutral
  /// placeholder tile when the product has no usable image.
  static pw.Widget imageCell(pw.MemoryImage? image, pw.Font mainFont) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.ClipRRect(
        horizontalRadius: 5,
        verticalRadius: 5,
        child: pw.Container(
          width: thumbSize,
          height: thumbSize,
          color: PdfColor.fromHex('#F1F5F9'),
          child: image != null
              ? pw.Image(image, fit: pw.BoxFit.cover)
              : pw.Center(
                  child: pw.Text(
                    'No\nImage',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      font: mainFont,
                      fontSize: 5.5,
                      color: ListTemplateStyle.mutedText,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Cell used inside the emerald total-summary row.
  static pw.Widget totalCell(
    String text,
    pw.Font boldFont, {
    pw.Alignment alignment = pw.Alignment.centerRight,
  }) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: _rowHPad, vertical: 8),
      child: pw.Text(
        text,
        maxLines: 1,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 9.5,
          color: ListTemplateStyle.white,
        ),
      ),
    );
  }

  /// Truncates long free text (descriptions) so a row never blows up in height.
  static String truncate(String? value, {int maxChars = 60}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return ListTemplateStyle.emptyValue;
    if (text.length <= maxChars) return text;
    // Plain dots rather than U+2026 so the Helvetica fallback still renders it.
    return '${text.substring(0, maxChars).trimRight()}...';
  }

  static String orDash(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? ListTemplateStyle.emptyValue : text;
  }

  /// Discount percent derived from the explicit field, else from MRP vs sale price.
  static int discountPercent(Product product) {
    if (product.discount != null && product.discount! > 0) {
      return product.discount!.round();
    }
    if (product.mrp > product.salePrice && product.mrp > 0) {
      return (((product.mrp - product.salePrice) / product.mrp) * 100).round();
    }
    return 0;
  }
}

/// Thin wrapper over the Grid `CurrencyFormatter` semantics so list cells format
/// money identically to grid cards.
class ListCurrency {
  static String format(double amount, String currencySymbol) {
    final symbol = currencySymbol.trim().isEmpty ? '₹' : currencySymbol;
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}

class ListTemplateRegistry {
  static final Map<String, ListCatalogTemplate> _registry = {
    'list_simple': SimpleListTemplate(),
    'list_price_discount': PriceDiscountTemplate(),
    'list_description': WithDescriptionTemplate(),
    'list_size_qty': WithSizeQtyTemplate(),
    'list_gst': WithGstTemplate(),
    'list_thumbnail': WithThumbnailTemplate(),
    'list_category': WithCategoryTemplate(),
    'list_total_summary': WithTotalSummaryTemplate(),
    // Numeric style IDs 1..8, matching CatalogListStyleSelectScreen ordering.
    '1': SimpleListTemplate(),
    '2': PriceDiscountTemplate(),
    '3': WithDescriptionTemplate(),
    '4': WithSizeQtyTemplate(),
    '5': WithGstTemplate(),
    '6': WithThumbnailTemplate(),
    '7': WithCategoryTemplate(),
    '8': WithTotalSummaryTemplate(),
  };

  static ListCatalogTemplate getTemplate(String templateId) {
    return _registry[templateId] ?? WithThumbnailTemplate();
  }

  static ListCatalogTemplate getTemplateByStyleId(int styleId) {
    return _registry[styleId.toString()] ?? WithThumbnailTemplate();
  }
}
