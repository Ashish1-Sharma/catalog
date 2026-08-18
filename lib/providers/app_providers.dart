import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../data/database/app_database.dart';
import '../data/repositories/business_profile_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/catalog_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final businessProfileRepoProvider = Provider<BusinessProfileRepository>((ref) {
  return BusinessProfileRepository(ref.watch(databaseProvider));
});

final categoryRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

final productRepoProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider));
});

final catalogRepoProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(ref.watch(databaseProvider));
});

final businessProfileProvider = FutureProvider<BusinessProfile?>((ref) async {
  return ref.watch(businessProfileRepoProvider).getProfile();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(categoryRepoProvider).getCategories();
});

final productsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productRepoProvider).getProducts();
});

final catalogsProvider = FutureProvider<List<Catalog>>((ref) async {
  return ref.watch(catalogRepoProvider).getCatalogs();
});
