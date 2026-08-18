import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/database/app_database.dart';
import 'grid_catalog_template.dart';

class PhotoOnly3ColTemplate implements GridCatalogTemplate {
  @override
  String get id => 'grid_photo_only_3col';

  @override
  String get displayName => 'Photo Only — 3 Columns';

  @override
  int get columns => 3;

  @override
  pw.Widget buildProductCard({
    required Product product,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
    String? categoryName,
    pw.MemoryImage? productImage,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FAFAF7'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 10,
        verticalRadius: 10,
        child: pw.Container(
          height: 130,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(6),
          color: PdfColor.fromHex('#F8FAFC'),
          child: productImage != null
              ? pw.Center(
                  child: pw.Image(productImage, fit: pw.BoxFit.contain),
                )
              // No image: fall back to the product name so a photo-only
              // catalog never renders as a page of empty boxes.
              : pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        product.name,
                        maxLines: 3,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 10,
                          color: PdfColor.fromHex('#0F172A'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'No Image',
                        style: pw.TextStyle(font: mainFont, fontSize: 8, color: PdfColor.fromHex('#94A3B8')),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
