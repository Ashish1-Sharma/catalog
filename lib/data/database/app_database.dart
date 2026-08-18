import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class BusinessProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  // IMPORTANT: Stores the backend integer user_id (converted to string) returned from registration/login
  TextColumn get userId => text()();
  TextColumn get businessName => text()();
  TextColumn get address => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get website => text()();
  TextColumn get gstin => text()();
  TextColumn get currency => text().withDefault(const Constant('₹'))();
  TextColumn get termsAndConditions => text()();
  TextColumn get logoPath => text().nullable()();
}

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get imagePath => text().nullable()();
  RealColumn get mrp => real()();
  RealColumn get salePrice => real()();
  RealColumn get discount => real().nullable()();
  TextColumn get size => text().nullable()();
  TextColumn get colour => text().nullable()();
  TextColumn get quantity => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get badgeLabel => text().nullable()();
  /// GST rate in percent (e.g. 18.0). Optional — only used by the "With GST" list template.
  RealColumn get gstPercent => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Catalogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'grid' or 'list'
  IntColumn get styleId => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get exportedPdfPath => text().nullable()();
  TextColumn get exportedImagePath => text().nullable()();
}

class CatalogProducts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get catalogId => integer().references(Catalogs, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [
  BusinessProfiles,
  Categories,
  Products,
  Catalogs,
  CatalogProducts,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(products, products.gstPercent);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'catalog_maker_db');
  }

  // --- BUSINESS PROFILE DAOs ---
  Future<BusinessProfile?> getBusinessProfile() async {
    return (select(businessProfiles)..limit(1)).getSingleOrNull();
  }

  Future<int> saveBusinessProfile(BusinessProfilesCompanion companion) async {
    final existing = await getBusinessProfile();
    if (existing != null) {
      return (update(businessProfiles)..where((tbl) => tbl.id.equals(existing.id))).write(companion);
    } else {
      return into(businessProfiles).insert(companion);
    }
  }

  // --- CATEGORIES DAOs ---
  Future<List<Category>> getAllCategories() async {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
  }

  Future<int> insertCategory(CategoriesCompanion companion) async {
    return into(categories).insert(companion);
  }

  Future<bool> updateCategory(Category category) async {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) async {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateCategoryOrders(List<Category> reordered) async {
    await batch((b) {
      for (int i = 0; i < reordered.length; i++) {
        final cat = reordered[i];
        b.update(
          categories,
          CategoriesCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(cat.id),
        );
      }
    });
  }

  // --- PRODUCTS DAOs ---
  Future<List<Product>> getAllProducts() async {
    return (select(products)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<Product>> getProductsByCategories(List<int> categoryIds) async {
    if (categoryIds.isEmpty) return getAllProducts();
    return (select(products)..where((t) => t.categoryId.isIn(categoryIds))).get();
  }

  Future<int> insertProduct(ProductsCompanion companion) async {
    return into(products).insert(companion);
  }

  Future<Product?> getProductById(int id) async {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateProduct(Product product) async {
    return update(products).replace(product);
  }

  Future<int> deleteProduct(int id) async {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  // --- CATALOGS DAOs ---
  Future<List<Catalog>> getAllCatalogs() async {
    return (select(catalogs)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<Catalog?> getCatalogById(int id) async {
    return (select(catalogs)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCatalog(CatalogsCompanion companion) async {
    return into(catalogs).insert(companion);
  }

  Future<int> deleteCatalog(int id) async {
    return (delete(catalogs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setCatalogProducts(int catalogId, List<int> productIds) async {
    await (delete(catalogProducts)..where((t) => t.catalogId.equals(catalogId))).go();
    await batch((b) {
      for (int i = 0; i < productIds.length; i++) {
        b.insert(
          catalogProducts,
          CatalogProductsCompanion(
            catalogId: Value(catalogId),
            productId: Value(productIds[i]),
            sortOrder: Value(i),
          ),
        );
      }
    });
  }

  Future<List<Product>> getProductsForCatalog(int catalogId) async {
    final cpRows = await (select(catalogProducts)
          ..where((t) => t.catalogId.equals(catalogId))
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();

    if (cpRows.isEmpty) {
      return [];
    }

    final pIds = cpRows.map((r) => r.productId).toList();
    final prods = await (select(products)..where((t) => t.id.isIn(pIds))).get();

    final prodMap = {for (final p in prods) p.id: p};
    final orderedProds = <Product>[];
    for (final id in pIds) {
      if (prodMap.containsKey(id)) {
        orderedProds.add(prodMap[id]!);
      }
    }
    return orderedProds;
  }
}
