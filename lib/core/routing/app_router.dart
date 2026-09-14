import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/database/app_database.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/business_profile/business_profile_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/dashboard/marketing_screen.dart';
import '../../features/dashboard/tutorial_screen.dart';
import '../../features/category/category_list_screen.dart';
import '../../features/category/add_edit_category_screen.dart';
import '../../features/product/product_list_screen.dart';
import '../../features/product/add_edit_product_screen.dart';
import '../../features/catalog_builder/catalog_list_screen.dart';
import '../../features/catalog_builder/catalog_category_select_screen.dart';
import '../../features/catalog_builder/catalog_product_select_screen.dart';
import '../../features/catalog_builder/catalog_type_select_screen.dart';
import '../../features/catalog_builder/catalog_style_select_screen.dart';
import '../../features/catalog_builder/catalog_list_style_select_screen.dart';
import '../../features/catalog_builder/catalog_preview_screen.dart';
import '../../features/catalog_builder/export_share_screen.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../features/settings/settings_screen.dart';

class MainShellLayout extends StatelessWidget {
  final Widget child;
  final String location;
  const MainShellLayout({
    super.key,
    required this.child,
    required this.location,
  });

  int _calculateSelectedIndex(String path) {
    if (path.startsWith('/catalog-list')) {
      return 1;
    }
    return 0;
  }

  void _onTabTapped(int index, BuildContext context) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/catalog-list');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    final selectedIndex = _calculateSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onTabTapped(index, context),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE8F5E9),
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF64748B), size: 24),
              selectedIcon: Icon(Icons.home_rounded, color: primaryGreen, size: 24),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open_outlined, color: Color(0xFF64748B), size: 24),
              selectedIcon: Icon(Icons.folder_rounded, color: primaryGreen, size: 24),
              label: 'Catalogs',
            ),
          ],
        ),
      ),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/business-profile-setup',
      builder: (context, state) => const BusinessProfileScreen(isEdit: false),
    ),
    ShellRoute(
      builder: (context, state, child) {
        return MainShellLayout(
          location: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/catalog-list',
          builder: (context, state) => const CatalogListScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/category-list',
      builder: (context, state) => const CategoryListScreen(),
    ),
    GoRoute(
      path: '/add-category',
      builder: (context, state) => const AddEditCategoryScreen(),
    ),
    GoRoute(
      path: '/edit-category',
      builder: (context, state) {
        final category = state.extra as Category?;
        return AddEditCategoryScreen(category: category);
      },
    ),
    GoRoute(
      path: '/product-list',
      builder: (context, state) => const ProductListScreen(),
    ),
    GoRoute(
      path: '/add-product',
      builder: (context, state) => const AddEditProductScreen(),
    ),
    GoRoute(
      path: '/edit-product',
      builder: (context, state) {
        final product = state.extra as Product?;
        return AddEditProductScreen(product: product);
      },
    ),
    GoRoute(
      path: '/catalog-step1',
      builder: (context, state) => const CatalogCategorySelectScreen(),
    ),
    GoRoute(
      path: '/catalog-step2',
      builder: (context, state) => const CatalogProductSelectScreen(),
    ),
    GoRoute(
      path: '/catalog-step3',
      builder: (context, state) => const CatalogTypeSelectScreen(),
    ),
    GoRoute(
      path: '/catalog-step4',
      builder: (context, state) => const CatalogStyleSelectScreen(),
    ),
    GoRoute(
      path: '/catalog-step4-list',
      builder: (context, state) => const CatalogListStyleSelectScreen(),
    ),
    GoRoute(
      path: '/catalog-preview',
      builder: (context, state) => const CatalogPreviewScreen(),
    ),
    GoRoute(
      path: '/export-share',
      builder: (context, state) {
        final catalog = state.extra as Catalog;
        return ExportShareScreen(catalog: catalog);
      },
    ),
    GoRoute(
      path: '/subscription',
      builder: (context, state) => const SubscriptionScreen(),
    ),
    GoRoute(
      path: '/edit-business-profile',
      builder: (context, state) => const BusinessProfileScreen(isEdit: true),
    ),
    GoRoute(
      path: '/marketing',
      builder: (context, state) => const MarketingScreen(),
    ),
    GoRoute(
      path: '/tutorial',
      builder: (context, state) => const TutorialScreen(),
    ),
  ],
);
