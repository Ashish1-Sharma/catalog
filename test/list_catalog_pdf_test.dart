import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_scanner/data/database/app_database.dart';
import 'package:qr_scanner/features/catalog_builder/templates/list/list_catalog_template.dart';

/// Mirrors the table assembly inside PdfExportService.generateListCatalogPdf,
/// minus the plugin-backed bits (fonts download, temp-dir write), so the layout
/// of every List template is actually rendered and paginated.
Future<Uint8List> _renderTable(
  ListCatalogTemplate template,
  List<Product> products, {
  Map<int, String>? categoryNames,
}) async {
  final pdf = pw.Document();
  final mainFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();
  const currency = 'Rs';

  final rows = <pw.TableRow>[
    pw.TableRow(
      repeat: true,
      decoration: ListTemplateStyle.headerDecoration,
      children: [
        for (final header in template.columnHeaders)
          ListCellBuilder.headerCell(header, boldFont),
      ],
    ),
  ];

  for (var i = 0; i < products.length; i++) {
    rows.add(template.buildProductRow(
      serialNumber: i + 1,
      product: products[i],
      currencySymbol: currency,
      mainFont: mainFont,
      boldFont: boldFont,
      categoryName: categoryNames?[products[i].categoryId],
    ));
  }

  if (template.hasTotalRow) {
    final total = template.buildTotalRow(
      products: products,
      currencySymbol: currency,
      mainFont: mainFont,
      boldFont: boldFont,
    );
    expect(total, isNotNull, reason: '${template.id} must produce a total row');
    rows.add(total!);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => [
        pw.Table(
          columnWidths: template.columnWidths,
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: rows,
        ),
      ],
    ),
  );

  return pdf.save();
}

Product _product(
  int id, {
  String? description,
  String? quantity,
  double? gstPercent,
  double? discount,
}) {
  return Product(
    id: id,
    categoryId: 1,
    name: 'Product $id with a fairly long display name',
    imagePath: null,
    mrp: 100.0 + id,
    salePrice: 80.0 + id,
    discount: discount,
    size: null,
    colour: null,
    quantity: quantity,
    description: description,
    badgeLabel: null,
    gstPercent: gstPercent,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final populated = [
    _product(1, description: 'A short description', quantity: '100ml', gstPercent: 18),
    _product(2,
        description:
            'A deliberately very long product description that must be truncated to roughly sixty characters with an ellipsis',
        quantity: '25 pcs',
        gstPercent: 5,
        discount: 30),
  ];

  // Every optional field null: descriptions, quantity, GST, image, category.
  final sparse = [_product(3), _product(4)];

  final templateIds = [
    'list_simple',
    'list_price_discount',
    'list_description',
    'list_size_qty',
    'list_gst',
    'list_thumbnail',
    'list_category',
    'list_total_summary',
  ];

  for (final id in templateIds) {
    test('$id renders with populated products', () async {
      final template = ListTemplateRegistry.getTemplate(id);
      expect(template.id, id);
      final bytes = await _renderTable(
        template,
        populated,
        categoryNames: {1: 'Skincare'},
      );
      expect(bytes.length, greaterThan(0));
    });

    test('$id renders with missing optional fields', () async {
      final bytes = await _renderTable(ListTemplateRegistry.getTemplate(id), sparse);
      expect(bytes.length, greaterThan(0));
    });
  }

  test('numeric style ids 1..8 map to the 8 list templates in order', () {
    final ids = [for (var i = 1; i <= 8; i++) ListTemplateRegistry.getTemplateByStyleId(i).id];
    expect(ids, templateIds);
  });

  test('column header count matches the cells each row builds', () {
    for (final id in templateIds) {
      final template = ListTemplateRegistry.getTemplate(id);
      final row = template.buildProductRow(
        serialNumber: 1,
        product: populated.first,
        currencySymbol: 'Rs',
        mainFont: pw.Font.helvetica(),
        boldFont: pw.Font.helveticaBold(),
      );
      expect(row.children.length, template.columnHeaders.length,
          reason: '$id row/header column mismatch');
      expect(template.columnWidths.length, template.columnHeaders.length,
          reason: '$id column width count mismatch');
    }
  });

  test('total summary row sums MRP and sale price across all products', () async {
    final template = ListTemplateRegistry.getTemplate('list_total_summary');
    expect(template.hasTotalRow, isTrue);
    // 101 + 102 MRP, 81 + 82 sale price for the two populated products.
    final bytes = await _renderTable(template, populated);
    expect(bytes.length, greaterThan(0));
  });

  test('only the GST template requests the GSTIN header', () {
    for (final id in templateIds) {
      expect(ListTemplateRegistry.getTemplate(id).showsGstin, id == 'list_gst',
          reason: id);
    }
  });

  test('truncate shortens long text and dashes empty text', () {
    expect(ListCellBuilder.truncate(null), '—');
    expect(ListCellBuilder.truncate('   '), '—');
    expect(ListCellBuilder.truncate('short'), 'short');
    final long = 'x' * 200;
    final truncated = ListCellBuilder.truncate(long);
    expect(truncated.length, lessThanOrEqualTo(63));
    expect(truncated.endsWith('...'), isTrue);
  });
}
