import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatalogBuilderState {
  final String name;
  final List<int> selectedCategoryIds;
  final List<int> selectedProductIds;
  final String type; // 'grid' or 'list'
  final int styleId;

  CatalogBuilderState({
    this.name = 'My Catalog',
    this.selectedCategoryIds = const [],
    this.selectedProductIds = const [],
    this.type = 'grid',
    this.styleId = 1,
  });

  CatalogBuilderState copyWith({
    String? name,
    List<int>? selectedCategoryIds,
    List<int>? selectedProductIds,
    String? type,
    int? styleId,
  }) {
    return CatalogBuilderState(
      name: name ?? this.name,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      type: type ?? this.type,
      styleId: styleId ?? this.styleId,
    );
  }
}

class CatalogBuilderNotifier extends StateNotifier<CatalogBuilderState> {
  CatalogBuilderNotifier() : super(CatalogBuilderState());

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setSelectedCategories(List<int> catIds) {
    state = state.copyWith(selectedCategoryIds: catIds);
  }

  void toggleCategory(int catId) {
    final current = List<int>.from(state.selectedCategoryIds);
    if (current.contains(catId)) {
      current.remove(catId);
    } else {
      current.add(catId);
    }
    state = state.copyWith(selectedCategoryIds: current);
  }

  void reorderCategories(int oldIndex, int newIndex) {
    final list = List<int>.from(state.selectedCategoryIds);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(selectedCategoryIds: list);
  }

  void setSelectedProducts(List<int> prodIds) {
    state = state.copyWith(selectedProductIds: prodIds);
  }

  void toggleProduct(int prodId) {
    final current = List<int>.from(state.selectedProductIds);
    if (current.contains(prodId)) {
      current.remove(prodId);
    } else {
      current.add(prodId);
    }
    state = state.copyWith(selectedProductIds: current);
  }

  void reorderProducts(int oldIndex, int newIndex) {
    final list = List<int>.from(state.selectedProductIds);
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(selectedProductIds: list);
  }

  void setType(String type) {
    state = state.copyWith(type: type);
  }

  void setStyleId(int styleId) {
    state = state.copyWith(styleId: styleId);
  }

  void reset() {
    state = CatalogBuilderState();
  }
}

final catalogBuilderProvider =
    StateNotifierProvider<CatalogBuilderNotifier, CatalogBuilderState>((ref) {
  return CatalogBuilderNotifier();
});
