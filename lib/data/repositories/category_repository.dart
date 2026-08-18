import '../database/app_database.dart';

class CategoryRepository {
  final AppDatabase _db;

  CategoryRepository(this._db);

  Future<List<Category>> getCategories() => _db.getAllCategories();
  Future<int> addCategory(CategoriesCompanion companion) => _db.insertCategory(companion);
  Future<bool> updateCategory(Category category) => _db.updateCategory(category);
  Future<int> deleteCategory(int id) => _db.deleteCategory(id);
  Future<void> reorderCategories(List<Category> categories) => _db.updateCategoryOrders(categories);
}
