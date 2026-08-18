import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 3 — S.N. | Image | Product Name | Description | MRP | Sale Price
/// Descriptions are truncated to ~60 characters so rows stay uniform.
class WithDescriptionTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_description';

  @override
  String get displayName => 'With Description';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'Description', 'MRP', 'Sale Price'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(3),
        3: pw.FlexColumnWidth(4.5),
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
          ListCellBuilder.truncate(product.description),
          mainFont,
          fontSize: 8,
          color: ListTemplateStyle.subText,
          maxLines: 2,
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
