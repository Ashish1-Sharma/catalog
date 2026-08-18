import 'package:pdf/widgets.dart' as pw;
import '../../../../data/database/app_database.dart';
import 'list_catalog_template.dart';

/// Style 2 — S.N. | Image | Product Name | MRP | Sale Price | Discount
/// MRP is struck through whenever there is a real discount.
class PriceDiscountTemplate implements ListCatalogTemplate {
  @override
  String get id => 'list_price_discount';

  @override
  String get displayName => 'Price + Discount';

  @override
  List<String> get columnHeaders =>
      ['S.N.', 'Image', 'Product Name', 'MRP', 'Sale Price', 'Discount'];

  @override
  Map<int, pw.TableColumnWidth> get columnWidths => const {
        0: pw.FixedColumnWidth(30),
        1: pw.FixedColumnWidth(52),
        2: pw.FlexColumnWidth(4),
        3: pw.FlexColumnWidth(2),
        4: pw.FlexColumnWidth(2.2),
        5: pw.FlexColumnWidth(1.6),
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
    final discount = ListCellBuilder.discountPercent(product);

    return pw.TableRow(
      decoration: ListTemplateStyle.rowDecoration(serialNumber),
      children: [
        ListCellBuilder.serialCell(serialNumber, mainFont),
        ListCellBuilder.imageCell(productImage, mainFont),
        ListCellBuilder.nameCell(product.name, boldFont),
        ListCellBuilder.mrpCell(
          product.mrp,
          currencySymbol,
          mainFont,
          strikeThrough: discount > 0,
        ),
        ListCellBuilder.priceCell(product.salePrice, currencySymbol, boldFont),
        ListCellBuilder.textCell(
          discount > 0 ? '$discount% OFF' : ListTemplateStyle.emptyValue,
          boldFont,
          fontSize: 8.5,
          color: discount > 0
              ? ListTemplateStyle.gold
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
}
