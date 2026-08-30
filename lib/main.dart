import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/routing/app_router.dart';
import 'core/services/revenuecat_service.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await AnalyticsService.instance.logAppOpen();
  } catch (e) {
    debugPrint('Firebase.initializeApp warning: $e');
  }
  await RevenueCatService.init();
  runApp(const ProviderScope(child: CatalogMakerApp()));
}

class CatalogMakerApp extends StatelessWidget {
  const CatalogMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Catalogue Maker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      routerConfig: appRouter,
    );
  }
}
