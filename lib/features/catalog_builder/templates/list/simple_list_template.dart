import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 1 — S.N. | Image | Product Name
class SimpleListTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_simple';

  @override
  String get displayName => 'Simple List';

  @override
  List<String> get columnHeaders => ['S.N.', 'Image', 'Product Name'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(34),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(6),
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
