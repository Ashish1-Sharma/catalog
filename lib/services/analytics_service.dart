import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  FirebaseAnalytics? _analyticsInstance;

  FirebaseAnalytics? get _analytics {
    try {
      _analyticsInstance ??= FirebaseAnalytics.instance;
      return _analyticsInstance;
    } catch (e) {
      debugPrint('FirebaseAnalytics not available: $e');
      return null;
    }
  }

  FirebaseAnalyticsObserver? get observer {
    final a = _analytics;
    if (a == null) return null;
    try {
      return FirebaseAnalyticsObserver(analytics: a);
    } catch (e) {
      debugPrint('FirebaseAnalyticsObserver creation error: $e');
      return null;
    }
  }

  Future<void> logCatalogCreated({
    required String catalogName,
    int? durationSeconds,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'catalog_created',
        parameters: {
          'catalog_name': catalogName,
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCatalogCreated error: $e');
    }
  }

  Future<void> logItemAdded({
    required String catalogId,
    required String itemName,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'item_added',
        parameters: {
          'catalog_id': catalogId,
          'item_name': itemName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logItemAdded error: $e');
    }
  }

  Future<void> logCatalogExported({
    required String catalogId,
    required String format,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'catalog_exported',
        parameters: {
          'catalog_id': catalogId,
          'format': format,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCatalogExported error: $e');
    }
  }

  Future<void> logCatalogShared({
    required String catalogId,
    required String method,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'catalog_shared',
        parameters: {
          'catalog_id': catalogId,
          'method': method,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCatalogShared error: $e');
    }
  }

  Future<void> logProductCreated({
    required String productName,
    String? categoryId,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'product_created',
        parameters: {
          'product_name': productName,
          if (categoryId != null) 'category_id': categoryId,
        },
      );
    } catch (e) {
      debugPrint('Analytics logProductCreated error: $e');
    }
  }

  Future<void> logProductViewed({
    required String productId,
    required String productName,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'product_viewed',
        parameters: {
          'product_id': productId,
          'product_name': productName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logProductViewed error: $e');
    }
  }

  Future<void> logCategoryCreated({
    required String categoryName,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'category_created',
        parameters: {
          'category_name': categoryName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCategoryCreated error: $e');
    }
  }

  Future<void> logCategoryViewed({
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      await _analytics?.logEvent(
        name: 'category_viewed',
        parameters: {
          'category_id': categoryId,
          'category_name': categoryName,
        },
      );
    } catch (e) {
      debugPrint('Analytics logCategoryViewed error: $e');
    }
  }

  Future<void> logAppOpen() async {
    try {
      await _analytics?.logAppOpen();
    } catch (e) {
      debugPrint('Analytics logAppOpen error: $e');
    }
  }
}
