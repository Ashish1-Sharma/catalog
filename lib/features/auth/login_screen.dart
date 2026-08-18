import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/services/revenuecat_service.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  
  bool _isRegisterMode = true; // Defaults to Register Mode as shown in design
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final apiService = ref.read(apiServiceProvider);
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();

    ApiResponse response;

    if (_isRegisterMode) {
      // 1. Register
      response = await apiService.register(
        userName: name.isNotEmpty ? name : 'User',
        userEmail: email,
        userMobile: mobile,
      );
      // Fallback to login if already exists
      if (!response.isSuccess &&
          (response.statusCode == 400 ||
              response.message.toLowerCase().contains('already exists'))) {
        response = await apiService.login(
          userEmail: email,
          userMobile: mobile,
        );
      }
    } else {
      // 2. Login
      response = await apiService.login(
        userEmail: email,
        userMobile: mobile,
      );
      // Fallback to register if no account found
      if (!response.isSuccess &&
          (response.statusCode == 401 ||
              response.message.toLowerCase().contains('no account'))) {
        response = await apiService.register(
          userName: name.isNotEmpty ? name : 'User',
          userEmail: email,
          userMobile: mobile,
        );
      }
    }

    if (!mounted) return;

    if (response.isSuccess && response.body is Map<String, dynamic>) {
      final body = response.body as Map<String, dynamic>;
      final rawUserId = body['user_id'];
      final int? userId = rawUserId is int ? rawUserId : int.tryParse(rawUserId?.toString() ?? '');
      final validity = body['validity']?.toString();
      final flag = body['flag'];
      final returnedName = body['username']?.toString() ?? body['userName']?.toString() ?? name;

      if (userId != null && userId > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.keyUserId, userId);
        await prefs.setString(AppConstants.keyUserName, returnedName.isNotEmpty ? returnedName : name);
        await prefs.setString(AppConstants.keyUserEmail, email);
        await prefs.setString(AppConstants.keyUserMobile, mobile);
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

        await RevenueCatService.logInUser(userId);

        if (!mounted) return;
        final profile = await ref.read(businessProfileRepoProvider).getProfile();
        if (!mounted) return;
        if (profile == null) {
          context.go('/business-profile-setup');
        } else {
          context.go('/dashboard');
        }
        return;
      }
    }

    setState(() {
      _isLoading = false;
      _errorMessage = response.message.isNotEmpty
          ? response.message
          : 'Authentication failed. Please verify your details.';
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const goldColor = Color(0xFFCA8A04);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Navigation Bar
                // Align(
                //   alignment: Alignment.centerLeft,
                //   child: InkWell(
                //     onTap: () {
                //       if (_isRegisterMode) {
                //         setState(() => _isRegisterMode = false);
                //       } else {
                //         context.go('/onboarding');
                //       }
                //     },
                //     borderRadius: BorderRadius.circular(8),
                //     child: Padding(
                //       padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                //       child: Row(
                //         mainAxisSize: MainAxisSize.min,
                //         children: [
                //           const Icon(Icons.arrow_back_rounded, color: primaryGreen, size: 20),
                //           const SizedBox(width: 6),
                //           Text(
                //             _isRegisterMode ? 'Back to Login' : 'Back',
                //             style: const TextStyle(
                //               color: primaryGreen,
                //               fontWeight: FontWeight.bold,
                //               fontSize: 14,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                const SizedBox(height: 12),

                // Brand Header Section
                Image.asset(
                  'assets/app_logo.png',
                  width: 76,
                  height: 76,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: primaryGreen, size: 36),
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Catalogue Maker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),

                const Text(
                  'Create. Brand. Share. Grow.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                // Star Divider
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 40, height: 1, color: const Color(0xFFE2E8F0)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.0),
                      child: Icon(Icons.star_rounded, color: goldColor, size: 12),
                    ),
                    Container(width: 40, height: 1, color: const Color(0xFFE2E8F0)),
                  ],
                ),

                const SizedBox(height: 20),

                // Form Title & Subtitle
                Text(
                  _isRegisterMode ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isRegisterMode
                      ? 'Start building beautiful catalogs\nin just a few seconds.'
                      : 'Enter your email and mobile number\nto log in to your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                ),

                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Full Name Field (Register Mode only)
                if (_isRegisterMode) ...[
                  _buildInputFieldContainer(
                    icon: Icons.person_outline_rounded,
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    controller: _nameController,
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Please enter your full name' : null,
                  ),
                  const SizedBox(height: 14),
                ],

                // 2. Email Address Field
                _buildInputFieldContainer(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email Address',
                  hintText: 'Enter your email address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Please enter email address';
                    if (!val.contains('@') || !val.contains('.')) return 'Invalid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // 3. Mobile Number Field with Country Code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: inputBorderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: primaryGreen, size: 22),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 14)),
                            SizedBox(width: 4),
                            Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          decoration: const InputDecoration(
                            hintText: 'Enter your mobile number',
                            hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Enter mobile number';
                            if (val.trim().length < 10) return 'Enter 10-digit number';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: primaryGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isRegisterMode ? 'Create Account' : 'Log In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Security Banner Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF059669),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No password needed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Just your email and mobile number to get started.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Mode Switcher Footer
                Text(
                  _isRegisterMode ? 'Already have an account?' : "Don't have an account?",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),

                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = null;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isRegisterMode ? 'Back to Login' : 'Create an Account',
                        style: const TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: primaryGreen, size: 16),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputFieldContainer({
    required IconData icon,
    required String label,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    const primaryGreen = Color(0xFF045435);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: inputBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: primaryGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 2),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
