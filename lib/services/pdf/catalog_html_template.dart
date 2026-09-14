import '../../data/database/app_database.dart';

/// Helper to sanitize HTML strings and convert ₹ to HTML entity &#8377;
String _escapeHtml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;')
      .replaceAll('₹', '&#8377;');
}

/// Pure function to build complete HTML string for catalog PDF generation.
/// No PDF or file I/O logic is contained in this file.
String buildCatalogHtml({
  required List<Product> products,
  required BusinessProfile profile,
  String catalogName = 'Product Catalog',
  Map<int, String>? categoryNames,
  String catalogType = 'grid',
  int styleId = 1,
  String? logoBase64,
  Map<int, String> productImagesBase64 = const {},
}) {
  final rawCurrency = profile.currency.trim().isEmpty ? '₹' : profile.currency;
  final currencySymbol =
      rawCurrency == '₹' ? '&#8377;' : _escapeHtml(rawCurrency);

  // Group products by category ID
  final Map<int, List<Product>> categoryProductsMap = {};
  final Map<int, String> categoryMap = {};

  for (final prod in products) {
    categoryProductsMap.putIfAbsent(prod.categoryId, () => []).add(prod);
    final catName = categoryNames?[prod.categoryId];
    if (catName != null && catName.trim().isNotEmpty) {
      categoryMap[prod.categoryId] = catName.trim();
    } else {
      categoryMap[prod.categoryId] = 'Category ${prod.categoryId}';
    }
  }

  // Format base64 image strings as Data URIs
  String formatDataUri(String? b64) {
    if (b64 == null || b64.isEmpty) return '';
    if (b64.startsWith('data:image/')) return b64;
    return 'data:image/jpeg;base64,$b64';
  }

  final logoUri = formatDataUri(logoBase64);

  final buffer = StringBuffer();

  buffer.writeln('<!DOCTYPE html>');
  buffer.writeln('<html>');
  buffer.writeln('<head>');
  buffer.writeln('  <meta charset="utf-8">');
  buffer.writeln('  <title>${_escapeHtml(catalogName)}</title>');
  buffer.writeln('  <style>');
  buffer.writeln('    @page {');
  buffer.writeln('      size: A4;');
  buffer.writeln('      margin: 14mm 12mm 16mm 12mm;');
  buffer.writeln('    }');
  buffer.writeln('    body {');
  buffer.writeln(
      '      font-family: \'Segoe UI\', Arial, sans-serif;');
  buffer.writeln('      color: #0f172a;');
  buffer.writeln('      margin: 0;');
  buffer.writeln('      padding: 0;');
  buffer.writeln('      background-color: #ffffff;');
  buffer.writeln('      -webkit-print-color-adjust: exact;');
  buffer.writeln('    }');
  buffer.writeln('    .cover-page {');
  buffer.writeln('      page-break-after: always;');
  buffer.writeln('      display: flex;');
  buffer.writeln('      flex-direction: column;');
  buffer.writeln('      justify-content: center;');
  buffer.writeln('      align-items: center;');
  buffer.writeln('      min-height: 85vh;');
  buffer.writeln('      text-align: center;');
  buffer.writeln('      padding: 40px 20px;');
  buffer.writeln('      box-sizing: border-box;');
  buffer.writeln('    }');
  buffer.writeln('    .cover-logo {');
  buffer.writeln('      max-width: 160px;');
  buffer.writeln('      max-height: 160px;');
  buffer.writeln('      margin-bottom: 24px;');
  buffer.writeln('      object-fit: contain;');
  buffer.writeln('    }');
  buffer.writeln('    .cover-title {');
  buffer.writeln('      font-size: 32px;');
  buffer.writeln('      font-weight: 700;');
  buffer.writeln('      color: #0b6e4f;');
  buffer.writeln('      margin: 0 0 12px 0;');
  buffer.writeln('    }');
  buffer.writeln('    .cover-subtitle {');
  buffer.writeln('      font-size: 20px;');
  buffer.writeln('      font-weight: 600;');
  buffer.writeln('      color: #334155;');
  buffer.writeln('      margin: 0 0 8px 0;');
  buffer.writeln('    }');
  buffer.writeln('    .cover-meta {');
  buffer.writeln('      font-size: 14px;');
  buffer.writeln('      color: #64748b;');
  buffer.writeln('      margin-top: 16px;');
  buffer.writeln('      line-height: 1.6;');
  buffer.writeln('    }');
  buffer.writeln('    .category-section {');
  buffer.writeln('      margin-bottom: 24px;');
  buffer.writeln('    }');
  buffer.writeln('    .category-header {');
  buffer.writeln('      background-color: #f1f5f9;');
  buffer.writeln('      padding: 8px 12px;');
  buffer.writeln('      border-radius: 6px;');
  buffer.writeln('      margin: 16px 0 12px 0;');
  buffer.writeln('      font-size: 14px;');
  buffer.writeln('      font-weight: 700;');
  buffer.writeln('      color: #0b6e4f;');
  buffer.writeln('      display: flex;');
  buffer.writeln('      justify-content: space-between;');
  buffer.writeln('      align-items: center;');
  buffer.writeln('      border-left: 4px solid #0b6e4f;');
  buffer.writeln('    }');
  buffer.writeln('    .product-grid {');
  buffer.writeln('      display: grid;');
  buffer.writeln('      grid-template-columns: repeat(2, 1fr);');
  buffer.writeln('      gap: 16px;');
  buffer.writeln('    }');
  buffer.writeln('    .product-card {');
  buffer.writeln('      page-break-inside: avoid;');
  buffer.writeln('      border: 1px solid #e2e8f0;');
  buffer.writeln('      border-radius: 8px;');
  buffer.writeln('      padding: 12px;');
  buffer.writeln('      box-sizing: border-box;');
  buffer.writeln('      background-color: #ffffff;');
  buffer.writeln('    }');
  buffer.writeln('    .product-img {');
  buffer.writeln('      width: 100%;');
  buffer.writeln('      height: 150px;');
  buffer.writeln('      object-fit: cover;');
  buffer.writeln('      border-radius: 6px;');
  buffer.writeln('      margin-bottom: 10px;');
  buffer.writeln('      background-color: #f8fafc;');
  buffer.writeln('    }');
  buffer.writeln('    .product-name {');
  buffer.writeln('      font-size: 15px;');
  buffer.writeln('      font-weight: 600;');
  buffer.writeln('      color: #0f172a;');
  buffer.writeln('      margin: 0 0 6px 0;');
  buffer.writeln('    }');
  buffer.writeln('    .product-price-row {');
  buffer.writeln('      display: flex;');
  buffer.writeln('      align-items: baseline;');
  buffer.writeln('      gap: 8px;');
  buffer.writeln('      margin-bottom: 6px;');
  buffer.writeln('    }');
  buffer.writeln('    .product-sale-price {');
  buffer.writeln('      font-size: 16px;');
  buffer.writeln('      font-weight: 700;');
  buffer.writeln('      color: #0b6e4f;');
  buffer.writeln('    }');
  buffer.writeln('    .product-mrp {');
  buffer.writeln('      font-size: 12px;');
  buffer.writeln('      color: #94a3b8;');
  buffer.writeln('      text-decoration: line-through;');
  buffer.writeln('    }');
  buffer.writeln('    .badge-label {');
  buffer.writeln('      display: inline-block;');
  buffer.writeln('      background-color: #d4a537;');
  buffer.writeln('      color: #ffffff;');
  buffer.writeln('      font-size: 10px;');
  buffer.writeln('      font-weight: 700;');
  buffer.writeln('      padding: 2px 6px;');
  buffer.writeln('      border-radius: 4px;');
  buffer.writeln('      margin-bottom: 6px;');
  buffer.writeln('      text-transform: uppercase;');
  buffer.writeln('    }');
  buffer.writeln('    .product-meta {');
  buffer.writeln('      font-size: 11px;');
  buffer.writeln('      color: #64748b;');
  buffer.writeln('      margin-bottom: 4px;');
  buffer.writeln('    }');
  buffer.writeln('    .product-desc {');
  buffer.writeln('      font-size: 11px;');
  buffer.writeln('      color: #475569;');
  buffer.writeln('      line-height: 1.4;');
  buffer.writeln('      margin-top: 4px;');
  buffer.writeln('    }');
  buffer.writeln('    .terms-section {');
  buffer.writeln('      page-break-inside: avoid;');
  buffer.writeln('      margin-top: 32px;');
  buffer.writeln('      padding-top: 16px;');
  buffer.writeln('      border-top: 1px solid #e2e8f0;');
  buffer.writeln('      font-size: 12px;');
  buffer.writeln('      color: #475569;');
  buffer.writeln('    }');
  buffer.writeln('    .terms-title {');
  buffer.writeln('      font-weight: 700;');
  buffer.writeln('      color: #0f172a;');
  buffer.writeln('      margin-bottom: 6px;');
  buffer.writeln('    }');
  buffer.writeln('  </style>');
  buffer.writeln('</head>');
  buffer.writeln('<body>');

  // --- COVER PAGE ---
  buffer.writeln('  <div class="cover-page">');
  if (logoUri.isNotEmpty) {
    buffer.writeln(
        '    <img class="cover-logo" src="$logoUri" alt="Business Logo" />');
  }
  buffer.writeln(
      '    <h1 class="cover-title">${_escapeHtml(catalogName)}</h1>');
  if (profile.businessName.trim().isNotEmpty) {
    buffer.writeln(
        '    <div class="cover-subtitle">${_escapeHtml(profile.businessName)}</div>');
  }

  buffer.writeln('    <div class="cover-meta">');
  if (profile.phone.trim().isNotEmpty) {
    buffer.writeln('      <div>Phone: ${_escapeHtml(profile.phone)}</div>');
  }
  if (profile.email.trim().isNotEmpty) {
    buffer.writeln('      <div>Email: ${_escapeHtml(profile.email)}</div>');
  }
  if (profile.website.trim().isNotEmpty) {
    buffer.writeln('      <div>Website: ${_escapeHtml(profile.website)}</div>');
  }
  if (profile.address.trim().isNotEmpty) {
    buffer.writeln('      <div>${_escapeHtml(profile.address)}</div>');
  }
  if (profile.gstin.trim().isNotEmpty) {
    buffer.writeln('      <div>GSTIN: ${_escapeHtml(profile.gstin)}</div>');
  }
  buffer.writeln(
      '      <div style="margin-top: 12px; font-weight: 600;">Total Products: ${products.length}</div>');
  buffer.writeln('    </div>');
  buffer.writeln('  </div>');

  // --- CATALOG CONTENT BY CATEGORY ---
  for (final entry in categoryProductsMap.entries) {
    final catId = entry.key;
    final catProds = entry.value;
    final catName = categoryMap[catId] ?? 'Category $catId';

    buffer.writeln('  <div class="category-section">');
    buffer.writeln('    <div class="category-header">');
    buffer.writeln('      <span>${_escapeHtml(catName.toUpperCase())}</span>');
    buffer.writeln('      <span>${catProds.length} items</span>');
    buffer.writeln('    </div>');

    buffer.writeln('    <div class="product-grid">');
    for (final prod in catProds) {
      final imgUri = formatDataUri(productImagesBase64[prod.id]);

      buffer.writeln('      <div class="product-card">');
      if (imgUri.isNotEmpty) {
        buffer.writeln(
            '        <img class="product-img" src="$imgUri" alt="${_escapeHtml(prod.name)}" />');
      }

      if (prod.badgeLabel != null && prod.badgeLabel!.trim().isNotEmpty) {
        buffer.writeln(
            '        <span class="badge-label">${_escapeHtml(prod.badgeLabel!)}</span>');
      }

      buffer.writeln(
          '        <div class="product-name">${_escapeHtml(prod.name)}</div>');

      buffer.writeln('        <div class="product-price-row">');
      buffer.writeln(
          '          <span class="product-sale-price">$currencySymbol${prod.salePrice.toStringAsFixed(2)}</span>');
      if (prod.mrp > prod.salePrice) {
        buffer.writeln(
            '          <span class="product-mrp">$currencySymbol${prod.mrp.toStringAsFixed(2)}</span>');
      }
      buffer.writeln('        </div>');

      final metaDetails = <String>[];
      if (prod.size != null && prod.size!.trim().isNotEmpty) {
        metaDetails.add('Size: ${_escapeHtml(prod.size!)}');
      }
      if (prod.colour != null && prod.colour!.trim().isNotEmpty) {
        metaDetails.add('Color: ${_escapeHtml(prod.colour!)}');
      }
      if (prod.quantity != null && prod.quantity!.trim().isNotEmpty) {
        metaDetails.add('Qty: ${_escapeHtml(prod.quantity!)}');
      }
      if (prod.gstPercent != null && prod.gstPercent! > 0) {
        metaDetails.add('GST: ${prod.gstPercent}%');
      }

      if (metaDetails.isNotEmpty) {
        buffer.writeln(
            '        <div class="product-meta">${metaDetails.join(' | ')}</div>');
      }

      if (prod.description != null && prod.description!.trim().isNotEmpty) {
        buffer.writeln(
            '        <div class="product-desc">${_escapeHtml(prod.description!)}</div>');
      }

      buffer.writeln('      </div>'); // product-card
    }
    buffer.writeln('    </div>'); // product-grid
    buffer.writeln('  </div>'); // category-section
  }

  // --- TERMS AND CONDITIONS SECTION ---
  if (profile.termsAndConditions.trim().isNotEmpty) {
    buffer.writeln('  <div class="terms-section">');
    buffer.writeln('    <div class="terms-title">Terms &amp; Conditions</div>');
    buffer.writeln(
        '    <div>${_escapeHtml(profile.termsAndConditions)}</div>');
    buffer.writeln('  </div>');
  }

  buffer.writeln('</body>');
  buffer.writeln('</html>');

  return buffer.toString();
}
