import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 7 — S.N. | Image | Product Name | Category | MRP | Sale Price
/// Category name is resolved by the service from the product's categoryId.
class WithCategoryTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_category';

  @override
  String get displayName => 'With Category';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'Category', 'MRP', 'Sale Price'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(2.6),
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
          ListCellBuilder.orDash(categoryName),
          mainFont,
          fontSize: 8.5,
          color: ListTemplateStyle.subText,
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
