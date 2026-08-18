import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 4 — S.N. | Image | Product Name | Qty | MRP | Sale Price
/// Qty comes from `product.quantity` (free text, e.g. "100ml" or "25 pcs").
class WithSizeQtyTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_size_qty';

  @override
  String get displayName => 'With Size / Quantity';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'Qty', 'MRP', 'Sale Price'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(4.5),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2),
        5: pw.FlexColumnWidth(2.2),
      };

  @override
  bool get showsGstin => false;

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
    return pw.TableRow(
      decoration: ListTemplateStyle.rowDecoration(serialNumber),
      children: [
        ListCellBuilder.serialCell(serialNumber, mainFont),
        ListCellBuilder.imageCell(productImage, mainFont),
        ListCellBuilder.nameCell(product.name, boldFont),
        ListCellBuilder.textCell(
          ListCellBuilder.orDash(product.quantity),
          mainFont,
          fontSize: 9,
          color: ListTemplateStyle.subText,
          alignment: pw.Alignment.center,
          maxLines: 1,
        ),
        ListCellBuilder.mrpCell(product.mrp, currencySymbol, mainFont,
            strikeThrough: product.mrp > product.salePrice),
        ListCellBuilder.priceCell(product.salePrice, currencySymbol, boldFont),
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
}
