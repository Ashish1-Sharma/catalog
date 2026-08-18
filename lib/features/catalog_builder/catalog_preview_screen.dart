import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/utils/currency_utils.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';
import '../../providers/catalog_builder_provider.dart';

class CatalogPreviewScreen extends ConsumerStatefulWidget {
  const CatalogPreviewScreen({super.key});

  @override
  ConsumerState<CatalogPreviewScreen> createState() => _CatalogPreviewScreenState();
}

class _CatalogPreviewScreenState extends ConsumerState<CatalogPreviewScreen> {
  bool _isSaving = false;

  Future<void> _saveCatalog(List<Product> selectedProducts) async {
    setState(() => _isSaving = true);
    final builderState = ref.read(catalogBuilderProvider);
    final catalogRepo = ref.read(catalogRepoProvider);

    final companion = CatalogsCompanion(
      name: drift.Value(builderState.name.isEmpty ? 'My Catalog' : builderState.name),
      type: drift.Value(builderState.type),
      styleId: drift.Value(builderState.styleId),
    );

    final catalogId = await catalogRepo.addCatalog(companion);
    final prodIds = selectedProducts.map((p) => p.id).toList();
    await catalogRepo.setCatalogProducts(catalogId, prodIds);

    ref.invalidate(catalogsProvider);

    final newCatalog = await catalogRepo.getCatalogById(catalogId);

    setState(() => _isSaving = false);

    if (mounted && newCatalog != null) {
      context.push('/export-share', extra: newCatalog);
    }
  }

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(catalogBuilderProvider);
    final profileAsync = ref.watch(businessProfileProvider);
    final productsAsync = ref.watch(productsProvider);
    final currency = profileAsync.value?.currency ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${builderState.name}'),
      ),
      body: productsAsync.when(
        data: (allProducts) {
          List<Product> selectedProducts = [];
          if (builderState.selectedProductIds.isNotEmpty) {
            selectedProducts = allProducts.where((p) => builderState.selectedProductIds.contains(p.id)).toList();
          }
          if (selectedProducts.isEmpty && builderState.selectedCategoryIds.isNotEmpty) {
            selectedProducts = allProducts.where((p) => builderState.selectedCategoryIds.contains(p.categoryId)).toList();
          }
          if (selectedProducts.isEmpty) {
            selectedProducts = allProducts;
          }

          return Column(
            children: [
              // Header preview
              profileAsync.when(
                data: (profile) => Card(
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profile?.logoPath != null && File(profile!.logoPath!).existsSync())
                          Image.file(File(profile.logoPath!), width: 60, height: 60, fit: BoxFit.contain)
                        else
                          const Icon(Icons.store, size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(profile?.businessName ?? 'Business Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              if (profile?.phone != null) Text('Phone: ${profile!.phone}'),
                              if (profile?.email != null) Text('Email: ${profile!.email}'),
                              if (profile?.address != null) Text('Address: ${profile!.address}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Divider(),

              // Selected Products View
              Expanded(
                child: builderState.type == 'grid'
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: selectedProducts.length,
                        itemBuilder: (context, index) {
                          final prod = selectedProducts[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: prod.imagePath != null && File(prod.imagePath!).existsSync()
                                        ? Center(child: Image.file(File(prod.imagePath!), fit: BoxFit.contain))
                                        : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.inventory_2, size: 36))),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    'Price: ${CurrencyUtils.formatAmount(prod.salePrice, currency: currency)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                  if (prod.mrp > prod.salePrice)
                                    Text(
                                      'MRP: ${CurrencyUtils.formatAmount(prod.mrp, currency: currency)}',
                                      style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: selectedProducts.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final prod = selectedProducts[index];
                          return ListTile(
                            leading: prod.imagePath != null && File(prod.imagePath!).existsSync()
                                ? Image.file(File(prod.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                                : Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2)),
                            title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(prod.description ?? 'No description'),
                            trailing: Text(
                              CurrencyUtils.formatAmount(prod.salePrice, currency: currency),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          );
                        },
                      ),
              ),

              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                child: PrimaryButton(
                  text: 'Save Catalog & Continue to Export',
                  onPressed: () => _saveCatalog(selectedProducts),
                  isLoading: _isSaving,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
