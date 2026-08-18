import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // Rescue any product images still sitting in a purgeable cache path
    // before they are lost (older builds stored image_picker temp paths).
    try {
      final repaired = await ref.read(productRepoProvider).repairImagePaths();
      if (repaired > 0) ref.invalidate(productsProvider);
    } catch (_) {}

    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.keyUserId);

    if (!mounted) return;

    if (userId != null && userId > 0) {
      try {
        final apiService = ApiService();
        final response = await apiService.checkStatus(userId: userId);
        if (response.isSuccess && response.body is Map<String, dynamic>) {
          final validity = response.body['validity']?.toString();
          final flag = response.body['flag'];
          if (validity != null) {
            await prefs.setString(AppConstants.keyValidityDate, validity);
          }
          if (flag != null) {
            // The API may return the flag as a number or a string ("1").
            await prefs.setInt(
              AppConstants.keySubFlag,
              flag is int ? flag : (int.tryParse(flag.toString().trim()) ?? 0),
            );
          }
        }
        await RevenueCatService.logInUser(userId);
      } catch (_) {}

      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const goldColor = Color(0xFFCA8A04);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Logo Image
            Image.asset(
              'assets/app_logo.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: primaryGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 28),

            // App Title
            const Text(
              'Catalogue Maker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            // Decorative Divider with Star
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 1.5,
                  color: const Color(0xFFE2E8F0),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(
                    Icons.star_rounded,
                    color: goldColor,
                    size: 14,
                  ),
                ),
                Container(
                  width: 50,
                  height: 1.5,
                  color: const Color(0xFFE2E8F0),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subtitle / Tagline
            const Text(
              'Create. Brand. Share. Grow.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),

            const Spacer(flex: 2),

            // Bottom Loader Section
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
