import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 5 — S.N. | Image | Product Name | MRP | Sale Price | GST
/// GST % comes from `product.gstPercent`; shows "—" when unset.
/// This is the only template that renders the business GSTIN above the table.
class WithGstTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_gst';

  @override
  String get displayName => 'With GST';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'MRP', 'Sale Price', 'GST'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(4.5),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2.2),
        5: pw.FlexColumnWidth(1.6),
      };

  @override
  bool get showsGstin => true;

  @override
  bool get hasTotalRow => false;

  @override
  pw.TableRow buildProductRow({
    required int serialNumber,
    required Product product,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
    String? categoryName,
    pw.MemoryImage? productImage,
  }) {
    final gst = product.gstPercent;
    final gstLabel = (gst != null && gst > 0)
        ? '${_trimZeros(gst)}%'
        : ListTemplateStyle.emptyValue;

    return pw.TableRow(
      decoration: ListTemplateStyle.rowDecoration(serialNumber),
      children: [
        ListCellBuilder.serialCell(serialNumber, mainFont),
        ListCellBuilder.imageCell(productImage, mainFont),
        ListCellBuilder.nameCell(product.name, boldFont),
        ListCellBuilder.mrpCell(product.mrp, currencySymbol, mainFont,
            strikeThrough: product.mrp > product.salePrice),
        ListCellBuilder.priceCell(product.salePrice, currencySymbol, boldFont),
        ListCellBuilder.textCell(
          gstLabel,
          mainFont,
          fontSize: 9,
          color: gst != null && gst > 0
              ? ListTemplateStyle.subText
              : ListTemplateStyle.mutedText,
          alignment: pw.Alignment.centerRight,
          maxLines: 1,
        ),
      ],
    );
  }

  @override
  pw.TableRow? buildTotalRow({
    required List<Product> products,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
  }) =>
      null;

  static String _trimZeros(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
