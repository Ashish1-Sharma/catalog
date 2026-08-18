import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 8 — S.N. | Image | Product Name | MRP | Sale Price
/// Plus one aggregate row after the last product summing MRP and Sale Price,
/// rendered on a solid emerald background with white bold text.
class WithTotalSummaryTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_total_summary';

  @override
  String get displayName => 'With Total Summary';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'MRP', 'Sale Price'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(32),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(5),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2.2),
      };

  @override
  bool get showsGstin => false;

  @override
  bool get hasTotalRow => true;

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
    return pw.TableRow(
      decoration: ListTemplateStyle.rowDecoration(serialNumber),
      children: [
        ListCellBuilder.serialCell(serialNumber, mainFont),
        ListCellBuilder.imageCell(productImage, mainFont),
        ListCellBuilder.nameCell(product.name, boldFont),
        ListCellBuilder.mrpCell(product.mrp, currencySymbol, mainFont,
            strikeThrough: product.mrp > product.salePrice),
        ListCellBuilder.priceCell(product.salePrice, currencySymbol, boldFont),
      ],
    );
  }

  @override
  pw.TableRow buildTotalRow({
    required List<Product> products,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
  }) {
    var totalMrp = 0.0;
    var totalSale = 0.0;
    for (final product in products) {
      totalMrp += product.mrp;
      totalSale += product.salePrice;
    }

    return pw.TableRow(
      decoration: ListTemplateStyle.totalDecoration,
      children: [
        // S.N. + Image columns are merged visually by leaving them blank.
        ListCellBuilder.totalCell('', boldFont),
        ListCellBuilder.totalCell('', boldFont),
        ListCellBuilder.totalCell(
          'TOTAL (${products.length} ${products.length == 1 ? 'Item' : 'Items'})',
          boldFont,
          alignment: pw.Alignment.centerLeft,
        ),
        ListCellBuilder.totalCell(
          ListCurrency.format(totalMrp, currencySymbol),
          boldFont,
        ),
        ListCellBuilder.totalCell(
          ListCurrency.format(totalSale, currencySymbol),
          boldFont,
        ),
      ],
    );
  }
}
