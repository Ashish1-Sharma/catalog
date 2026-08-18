import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/plan_constants.dart';
import '../../core/services/revenuecat_service.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/app_providers.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _validityDateStr = 'Loading...';
  int _daysRemaining = 0;
  int _subFlag = 0;
  bool _isLoading = false;
  String _selectedPlan = PlanConstants.catalogMonthly;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final validity = prefs.getString(AppConstants.keyValidityDate) ?? '2026-08-19';
    final flag = prefs.getInt(AppConstants.keySubFlag) ?? 0;
    final days = AppDateUtils.getDaysRemaining(validity);

    if (mounted) {
      setState(() {
        _validityDateStr = validity;
        _subFlag = flag;
        _daysRemaining = days;
      });
    }
  }

  Future<void> _subscribe() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.keyUserId) ?? 0;
    final planCode = _selectedPlan;

    // 1. Attempt RevenueCat purchase
    final customerInfo = await RevenueCatService.purchasePlan(planCode);

    // If RevenueCat returns customerInfo or as fallback test:
    String purchaseId = customerInfo?.originalPurchaseDate ?? 'rc_transaction_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Call backend update_purchase.php
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.updatePurchase(
      userId: userId,
      planCode: planCode,
      purchaseId: purchaseId,
    );

    if (response.isSuccess && response.body is Map<String, dynamic>) {
      final newValidity = response.body['validity']?.toString();
      if (newValidity != null) {
        await prefs.setString(AppConstants.keyValidityDate, newValidity);
        await prefs.setInt(AppConstants.keySubFlag, 1);
      }
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription Successful! Valid until: ${newValidity ?? _validityDateStr}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Subscription update message: ${response.message}')),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFF0FDF4);
    const greenBorderColor = Color(0xFFDCFCE7);
    const goldAccent = Color(0xFFD97706);
    const textDarkColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Subscription & Plans',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Unlock premium features and grow your business',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Trial / Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightGreenBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: greenBorderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _subFlag == 1 ? 'PREMIUM SUBSCRIPTION ACTIVE' : 'FREE TRIAL ACTIVE',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF065F46),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Enjoy all Premium features\nabsolutely free.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF047857),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF059669),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Valid Until', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  _validityDateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textDarkColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF059669),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Days Remaining', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text(
                                  '$_daysRemaining days',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textDarkColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Title
            const Text(
              'Choose the perfect plan for you',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textDarkColor,
              ),
            ),

            const SizedBox(height: 14),

            // Plan Card 1: Monthly Catalog Pro (Most Popular)
            _buildPlanCard(
              planCode: PlanConstants.catalogMonthly,
              title: 'Monthly Catalog Pro',
              priceText: '₹99',
              periodText: '/ month',
              ribbonText: 'Most Popular',
              ribbonColor: primaryGreen,
              isGoldIcon: true,
              isSelected: _selectedPlan == PlanConstants.catalogMonthly,
              features: const [
                'Unlimited PDF & image catalog exports',
                'Custom branding with your logo & details',
                'All premium catalog styles & templates',
                'Priority support',
              ],
              onTap: () => setState(() => _selectedPlan = PlanConstants.catalogMonthly),
            ),

            const SizedBox(height: 14),

            // Plan Card 2: Intro Offer (50% OFF)
            _buildPlanCard(
              planCode: PlanConstants.catalogMonthlyIntro50,
              title: 'Intro Offer',
              priceText: '₹49',
              periodText: '/ first month',
              ribbonText: '50% OFF',
              ribbonColor: goldAccent,
              isGoldIcon: false,
              isSelected: _selectedPlan == PlanConstants.catalogMonthlyIntro50,
              features: const [
                'All features of Monthly Catalog Pro',
                'Special introductory price for new users',
                'Cancel anytime',
              ],
              onTap: () => setState(() => _selectedPlan = PlanConstants.catalogMonthlyIntro50),
            ),

            const SizedBox(height: 20),

            // Security Guarantee Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: goldAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancel anytime',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'You can cancel your subscription anytime.\nNo hidden charges.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Primary Action Subscribe Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isLoading ? null : _subscribe,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Subscribe Now',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Footer Lock Notice
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Text(
                  'Secure payments • 100% safe & trusted',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planCode,
    required String title,
    required String priceText,
    required String periodText,
    required String ribbonText,
    required Color ribbonColor,
    required bool isGoldIcon,
    required bool isSelected,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    const primaryGreen = Color(0xFF045435);
    const goldAccent = Color(0xFFD97706);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? primaryGreen : const Color(0xFFE2E8F0),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Radio Icon
                    Icon(
                      isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                      color: isSelected ? primaryGreen : Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),

                    // Avatar Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isGoldIcon ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isGoldIcon ? Icons.workspace_premium_rounded : Icons.local_offer_rounded,
                        color: isGoldIcon ? goldAccent : primaryGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Title & Price
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                periodText,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Features List
                Column(
                  children: features.map((feat) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF059669),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              feat,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Ribbon Badge Tag
          Positioned(
            top: 0,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ribbonColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Text(
                ribbonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
