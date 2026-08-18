import 'package:drift/drift.dart' show Value;
import '../../core/services/product_image_service.dart';
import '../database/app_database.dart';

class ProductRepository {
  final AppDatabase _db;

  ProductRepository(this._db);

  Future<List<Product>> getProducts() => _db.getAllProducts();

  /// Moves any product image still living in a temporary cache path into
  /// permanent storage. Files the OS already purged cannot be recovered; this
  /// only stops the bleeding for the ones still on disk. Safe to call repeatedly.
  Future<int> repairImagePaths() async {
    final all = await _db.getAllProducts();
    var repaired = 0;
    for (final product in all) {
      final newPath = await ProductImageService.repairIfNeeded(product.imagePath);
      if (newPath == null) continue;
      await _db.updateProduct(product.copyWith(imagePath: Value(newPath)));
      repaired++;
    }
    return repaired;
  }

  /// Products that have an image recorded whose file no longer exists.
  Future<List<Product>> productsWithMissingImages() async {
    final all = await _db.getAllProducts();
    return all.where((p) => ProductImageService.isMissing(p.imagePath)).toList();
  }
  Future<List<Product>> getProductsByCategories(List<int> catIds) => _db.getProductsByCategories(catIds);
  Future<int> addProduct(ProductsCompanion companion) => _db.insertProduct(companion);
  Future<Product?> getProductById(int id) => _db.getProductById(id);
  Future<bool> updateProduct(Product product) => _db.updateProduct(product);
  Future<int> deleteProduct(int id) => _db.deleteProduct(id);
}
