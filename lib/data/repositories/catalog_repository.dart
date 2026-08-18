import '../database/app_database.dart';

class CatalogRepository {
  final AppDatabase _db;

  CatalogRepository(this._db);

  Future<List<Catalog>> getCatalogs() => _db.getAllCatalogs();
  Future<Catalog?> getCatalogById(int id) => _db.getCatalogById(id);
  Future<int> addCatalog(CatalogsCompanion companion) => _db.insertCatalog(companion);
  Future<int> deleteCatalog(int id) => _db.deleteCatalog(id);
  Future<void> setCatalogProducts(int catalogId, List<int> productIds) =>
      _db.setCatalogProducts(catalogId, productIds);
  Future<List<Product>> getProductsForCatalog(int catalogId) =>
      _db.getProductsForCatalog(catalogId);
}
