# List Catalog PDF — usage

`PdfExportService.generateListCatalogPdf` mirrors `generateCatalogPdf` (Grid). It reuses the
same cover page, running header/footer, terms page, Poppins font setup and currency formatting —
only the body differs: a paginated `pw.Table` whose header row repeats on every page.

Templates are resolved from `ListTemplateRegistry` by either the string id (`list_gst`) or the
numeric style id saved on the catalog (`Catalog.styleId`, 1–8, matching the order shown in
`catalog_list_style_select_screen.dart`).

| styleId | id | columns |
|---|---|---|
| 1 | `list_simple` | S.N. \| Image \| Product Name |
| 2 | `list_price_discount` | + MRP (struck) \| Sale Price \| Discount |
| 3 | `list_description` | + Description (truncated ~60 chars) \| MRP \| Sale Price |
| 4 | `list_size_qty` | + Qty \| MRP \| Sale Price |
| 5 | `list_gst` | + MRP \| Sale Price \| GST (also prints `profile.gstin` above the table) |
| 6 | `list_thumbnail` | + MRP \| Sale Price |
| 7 | `list_category` | + Category \| MRP \| Sale Price |
| 8 | `list_total_summary` | + MRP \| Sale Price, plus an emerald total row |

## Normal template (e.g. Style 7, With Category)

```dart
final categories = await ref.read(categoryRepoProvider).getCategories();

final pdfFile = await PdfExportService.generateListCatalogPdf(
  products: selectedProducts,          // List<Product>
  profile: businessProfile,            // BusinessProfile
  templateId: 'list_category',         // or catalog.styleId.toString()
  catalogName: catalog.name,
  categoryNames: {for (final c in categories) c.id: c.name},
  styleId: catalog.styleId,
);

// Same export/share flow as the Grid PDFs:
await PdfExportService.printOrSharePdf(pdfFile);
```

## With Total Summary (Style 8)

Identical call — the aggregate row is produced by the template itself, so nothing extra is
needed at the call site. After the last product row the service appends one emerald row with
white bold text summing MRP and Sale Price across every product in the catalog:

```dart
final pdfFile = await PdfExportService.generateListCatalogPdf(
  products: selectedProducts,
  profile: businessProfile,
  templateId: 'list_total_summary',
  catalogName: 'Wholesale Price List',
);
// Final table row reads:  TOTAL (12 Items) | ₹ 4,180.00 | ₹ 3,540.00
```

## How `export_share_screen.dart` wires it up

`_exportPdf` branches on the catalog type, so the list-style choice made in
`catalog_list_style_select_screen.dart` flows straight through:

```dart
final isList = widget.catalog.type == 'list';
final pdfFile = isList
    ? await PdfExportService.generateListCatalogPdf(
        products: products,
        profile: safeProfile,
        templateId: widget.catalog.styleId.toString(),
        catalogName: widget.catalog.name,
        categoryNames: categoryNames,
        styleId: widget.catalog.styleId,
      )
    : await PdfExportService.generateCatalogPdf(/* ...grid args... */);
```

## Missing data

Nothing crashes or leaves a blank-looking cell: missing images render a neutral "No Image"
tile, and missing description / quantity / GST / category render `—`.
`gstPercent` is optional on `Products` and is edited from the **GST (%)** field on the
Add/Edit Product screen.
