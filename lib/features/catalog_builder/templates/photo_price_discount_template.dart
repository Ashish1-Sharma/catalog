import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/database/app_database.dart';
import 'grid_catalog_template.dart';

class PhotoPriceDiscountTemplate implements GridCatalogTemplate {
  @override
  String get id => 'grid_photo_price_discount';

  @override
  String get displayName => 'Photo + Price + Discount';

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
    final salePriceStr = CurrencyFormatter.format(product.salePrice, currencySymbol);
    final mrpStr = CurrencyFormatter.format(product.mrp, currencySymbol);

    int discountPercent = 0;
    if (product.discount != null && product.discount! > 0) {
      discountPercent = product.discount!.round();
    } else if (product.mrp > product.salePrice && product.mrp > 0) {
      discountPercent = (((product.mrp - product.salePrice) / product.mrp) * 100).round();
    }

    return pw.Container(
      margin: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAFAF7'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
      ),
      child: pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.ClipRRect(
                horizontalRadius: 12,
                verticalRadius: 12,
                child: pw.Container(
                  height: 130,
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
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      product.name,
                      maxLines: 1,
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 11,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Row(
                      children: [
                        if (discountPercent > 0) ...[
                          pw.Text(
                            mrpStr,
                            style: pw.TextStyle(
                              font: mainFont,
                              fontSize: 9,
                              color: PdfColor.fromHex('#94A3B8'),
                              decoration: pw.TextDecoration.lineThrough,
                            ),
                          ),
                          pw.SizedBox(width: 4),
                        ],
                        pw.Text(
                          salePriceStr,
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 12,
                            color: PdfColor.fromHex('#0B6E4F'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (discountPercent > 0)
            pw.Positioned(
              top: 6,
              left: 6,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFD4A537),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  '$discountPercent% OFF',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 8,
                    color: PdfColor.fromHex('#FFFFFF'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
