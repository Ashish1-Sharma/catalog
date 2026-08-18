import 'package:pdf/widgets.dart' as pw;
import '../../../data/database/app_database.dart';
import 'photo_only_2col_template.dart';
import 'photo_only_3col_template.dart';
import 'photo_price_template.dart';
import 'photo_price_stock_template.dart';
import 'photo_name_price_template.dart';
import 'photo_price_discount_template.dart';
import 'photo_description_price_template.dart';
import 'photo_badge_price_template.dart';
import 'photo_category_price_template.dart';

abstract class GridCatalogTemplate {
  String get id;
  String get displayName;
  int get columns; // 2 or 3

  pw.Widget buildProductCard({
    required Product product,
    required String currencySymbol,
    required pw.Font mainFont,
    required pw.Font boldFont,
    String? categoryName,
    pw.MemoryImage? productImage,
  });
}

class CurrencyFormatter {
  static String format(double amount, String currencySymbol) {
    final symbol = currencySymbol.trim().isEmpty ? '₹' : currencySymbol;
    return '$symbol ${amount.toStringAsFixed(2)}';
  }
}

class GridTemplateRegistry {
  static final Map<String, GridCatalogTemplate> _registry = {
    'grid_photo_only_2col': PhotoOnly2ColTemplate(),
    'grid_photo_only_3col': PhotoOnly3ColTemplate(),
    'grid_photo_price': PhotoPriceTemplate(),
    'grid_photo_price_stock': PhotoPriceStockTemplate(),
    'grid_photo_name_price': PhotoNamePriceTemplate(),
    'grid_photo_price_discount': PhotoPriceDiscountTemplate(),
    'grid_photo_description_price': PhotoDescriptionPriceTemplate(),
    'grid_photo_badge_price': PhotoBadgePriceTemplate(),
    'grid_photo_category_price': PhotoCategoryPriceTemplate(),
    // Also map numeric string IDs 1..9 for seamless compatibility
    '1': PhotoOnly2ColTemplate(),
    '2': PhotoOnly3ColTemplate(),
    '3': PhotoPriceTemplate(),
    '4': PhotoPriceStockTemplate(),
    '5': PhotoNamePriceTemplate(),
    '6': PhotoPriceDiscountTemplate(),
    '7': PhotoDescriptionPriceTemplate(),
    '8': PhotoBadgePriceTemplate(),
    '9': PhotoCategoryPriceTemplate(),
  };

  static GridCatalogTemplate getTemplate(String templateId) {
    return _registry[templateId] ?? PhotoNamePriceTemplate();
  }

  static GridCatalogTemplate getTemplateByStyleId(int styleId) {
    return _registry[styleId.toString()] ?? PhotoNamePriceTemplate();
  }
}
