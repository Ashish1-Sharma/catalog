import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/database/app_database.dart';
import 'grid_catalog_template.dart';

class PhotoPriceTemplate implements GridCatalogTemplate {
  @override
  String get id => 'grid_photo_price';

  @override
  String get displayName => 'Photo + Price';

  @override
  int get columns => 2;

  @override
  pw.Widget buildProductCard({
    required Product product,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
    String? categoryName,
    pw.MemoryImage? productImage,
  }) {
    final priceStr = CurrencyFormatter.format(product.salePrice, currencySymbol);

    return pw.Container(
      margin: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAFAF7'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: pw.Container(
              height: 140,
              width: double.infinity,
              padding: const pw.EdgeInsets.all(6),
              color: PdfColor.fromHex('#F8FAFC'),
              child: productImage != null
                  ? pw.Center(
                      child: pw.Image(productImage, fit: pw.BoxFit.contain),
                    )
                  : pw.Center(
                      child: pw.Text(
                        'No Image',
                        style: pw.TextStyle(font: mainFont, fontSize: 10, color: PdfColor.fromHex('#94A3B8')),
                      ),
                    ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: pw.Text(
              priceStr,
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 13,
                color: PdfColor.fromHex('#0B6E4F'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
