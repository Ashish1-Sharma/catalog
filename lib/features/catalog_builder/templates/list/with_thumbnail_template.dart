import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 6 — S.N. | Image | Product Name | MRP | Sale Price
/// The baseline priced list; also the fallback template for unknown IDs.
class WithThumbnailTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_thumbnail';

  @override
  String get displayName => 'With Thumbnail';

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
