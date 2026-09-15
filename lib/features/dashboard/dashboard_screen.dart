import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/app_providers.dart';
import 'trial_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _userName = 'Ashish Sharma';
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    _checkTrialAndUser();
  }

  Future<void> _openWhatsAppBanner() async {
    const phoneNumber = '917217316197';
    const message = 'Hi, I want an e-commerce app';
    final encodedMessage = Uri.encodeComponent(message);
    final waMeUri = Uri.parse('https://wa.me/$phoneNumber?text=$encodedMessage');

    try {
      if (!await launchUrl(waMeUri, mode: LaunchMode.externalApplication)) {
        final webUri = Uri.parse('https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage');
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  Future<void> _checkTrialAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final validityStr = prefs.getString(AppConstants.keyValidityDate);
    final days = AppDateUtils.getDaysRemaining(validityStr);
    final isExpired = AppDateUtils.isExpired(validityStr);
    final storedName = prefs.getString(AppConstants.keyUserName);

    if (mounted) {
      setState(() {
        if (storedName != null && storedName.trim().isNotEmpty) {
          _userName = storedName.trim();
        }
      });

      // Instead of showing the premium popup always, don't show it during trial.
      // Show non-removable popup only when user time has expired or reached validity.
      if (!_dialogShown && isExpired) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TrialDialog.showIfNeeded(context, days, isExpired: true);
        });
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of Catalogue Maker?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ref.invalidate(businessProfileProvider);
      ref.invalidate(categoriesProvider);
      ref.invalidate(productsProvider);
      ref.invalidate(catalogsProvider);

      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const textDarkColor = Color(0xFF1E293B);

    final profileAsync = ref.watch(businessProfileProvider);
    final profile = profileAsync.value;
    final businessName = profile?.businessName.isNotEmpty == true ? profile!.businessName : _userName;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: primaryGreen, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: textDarkColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: const [
          SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                        image: profile?.logoPath != null && File(profile!.logoPath!).existsSync()
                            ? DecorationImage(
                                image: FileImage(File(profile.logoPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: profile?.logoPath == null || !File(profile!.logoPath!).existsSync()
                          ? const Icon(Icons.person_rounded, color: primaryGreen, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            businessName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile?.email.isNotEmpty == true
                                ? profile!.email
                                : (profile?.phone.isNotEmpty == true ? profile!.phone : 'View Profile'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Settings Menus (Plain labels only - no icons, no subtitles)
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerMenuTile('Edit Business Profile', () {
                      Navigator.pop(context);
                      context.push('/edit-business-profile');
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Subscription Status', () {
                      Navigator.pop(context);
                      context.push('/subscription');
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Help & FAQ', () {
                      Navigator.pop(context);
                      context.push('/tutorial');
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Contact Us', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Contact support via email: support@ashish-dev.xyz')),
                      );
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Privacy Policy', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy: All data stored locally.')),
                      );
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Terms of Service', () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service: Standard business terms.')),
                      );
                    }),
                    const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF1F5F9)),
                    _buildDrawerMenuTile('Logout', () {
                      Navigator.pop(context);
                      _logout(context);
                    }, isDestructive: true),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image Section (Above Step 1)
              GestureDetector(
                onTap: _openWhatsAppBanner,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/banner_image.png',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Workflow Step Cards
              // Step 1: Category
              _buildStepCard(
                stepLabel: 'Step 1',
                stepColor: const Color(0xFF9333EA),
                title: 'Category',
                subtitle: 'Organize your products with categories',
                iconBgColor: const Color(0xFFF3E8FF),
                icon: const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF9333EA),
                  size: 28,
                ),
                onTap: () => context.push('/category-list'),
              ),
              const SizedBox(height: 14),

              // Step 2: Products
              _buildStepCard(
                stepLabel: 'Step 2',
                stepColor: const Color(0xFF0284C7),
                title: 'Products',
                subtitle: 'Add and manage your products',
                iconBgColor: const Color(0xFFE0F2FE),
                icon: const Icon(
                  Icons.view_in_ar_rounded,
                  color: Color(0xFF0284C7),
                  size: 28,
                ),
                onTap: () => context.push('/product-list'),
              ),
              const SizedBox(height: 14),

              // Step 3: Create Catalog
              _buildStepCard(
                stepLabel: 'Step 3',
                stepColor: const Color(0xFFEA580C),
                title: 'Create Catalog',
                subtitle: 'Select products and create your catalog',
                iconBgColor: const Color(0xFFFFEDD5),
                icon: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFFEA580C),
                  size: 28,
                ),
                onTap: () => context.push('/catalog-step1'),
              ),
              const SizedBox(height: 14),

              // Step 4: Share Catalog
              _buildStepCard(
                stepLabel: 'Step 4',
                stepColor: const Color(0xFF16A34A),
                title: 'Share Catalog',
                subtitle: 'Download or share your catalog as PDF',
                iconBgColor: const Color(0xFFDCFCE7),
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF16A34A),
                  size: 28,
                ),
                onTap: () => context.push('/catalog-list'),
              ),
              const SizedBox(height: 24),

              // OTHER TOOLS Section
              const Text(
                'OTHER TOOLS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Card: Posters & Banners
              _buildStepCard(
                title: 'Posters & Banners',
                subtitle: 'Create stylish posters and banners to promote',
                iconBgColor: const Color(0xFFFFE4E6),
                icon: const Icon(
                  Icons.campaign_rounded,
                  color: Color(0xFFE11D48),
                  size: 28,
                ),
                onTap: () => context.push('/marketing'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerMenuTile(
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildStepCard({
    String? stepLabel,
    Color? stepColor,
    required String title,
    required String subtitle,
    required Color iconBgColor,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Round Icon Container
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: 16),

                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (stepLabel != null && stepColor != null) ...[
                        Text(
                          stepLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: stepColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
