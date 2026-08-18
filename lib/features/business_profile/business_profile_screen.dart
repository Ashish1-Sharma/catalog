import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  final bool isEdit;
  const BusinessProfileScreen({super.key, this.isEdit = false});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gstinController = TextEditingController();
  final _currencyController = TextEditingController(text: '₹');
  final _termsController = TextEditingController(text: 'Thank you for your business!');

  String? _logoPath;
  bool _isLoading = false;
  int _termsLength = 28;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
    _termsController.addListener(() {
      setState(() {
        _termsLength = _termsController.text.length;
      });
    });
  }

  Future<void> _loadExistingProfile() async {
    final profile = await ref.read(businessProfileRepoProvider).getProfile();
    if (profile != null) {
      _nameController.text = profile.businessName;
      _addressController.text = profile.address;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
      _websiteController.text = profile.website;
      _gstinController.text = profile.gstin;
      _currencyController.text = profile.currency;
      _termsController.text = profile.termsAndConditions;
      setState(() {
        _logoPath = profile.logoPath;
        _termsLength = profile.termsAndConditions.length;
      });
    } else {
      final prefs = await SharedPreferences.getInstance();
      _emailController.text = prefs.getString(AppConstants.keyUserEmail) ?? '';
      _phoneController.text = prefs.getString(AppConstants.keyUserMobile) ?? '';
      _nameController.text = prefs.getString(AppConstants.keyUserName) ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _gstinController.dispose();
    _currencyController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _logoPath = image.path;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(AppConstants.keyUserId)?.toString() ?? '0';

    final companion = BusinessProfilesCompanion(
      userId: drift.Value(userId),
      businessName: drift.Value(_nameController.text.trim()),
      address: drift.Value(_addressController.text.trim()),
      email: drift.Value(_emailController.text.trim()),
      phone: drift.Value(_phoneController.text.trim()),
      website: drift.Value(_websiteController.text.trim()),
      gstin: drift.Value(_gstinController.text.trim()),
      currency: drift.Value(_currencyController.text.trim().isEmpty ? '₹' : _currencyController.text.trim()),
      termsAndConditions: drift.Value(_termsController.text.trim()),
      logoPath: drift.Value(_logoPath),
    );

    await ref.read(businessProfileRepoProvider).saveProfile(companion);
    ref.invalidate(businessProfileProvider);

    setState(() => _isLoading = false);

    if (!mounted) return;
    if (widget.isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile updated successfully')),
      );
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFECFDF5);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isEdit
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
                onPressed: () => context.pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEdit ? 'Edit Business Profile' : 'Business Profile Setup',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Update your business information',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Upload Box
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Container(
                    width: 140,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                    ),
                    child: _logoPath != null && File(_logoPath!).existsSync()
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(File(_logoPath!), fit: BoxFit.cover, width: double.infinity, height: 120),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text('Change Logo', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: lightGreenBg,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Color(0xFF059669),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Add Logo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'JPG, PNG up to 2MB',
                                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 1. Business Name Field
              _buildLabel('Business Name', isRequired: true),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.storefront_outlined,
                hintText: 'Enter business name',
                controller: _nameController,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 14),

              // 2. Business Address Field
              _buildLabel('Business Address', isRequired: false),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.location_on_outlined,
                hintText: 'Enter business address',
                controller: _addressController,
              ),

              const SizedBox(height: 14),

              // 3. Phone Number Field
              _buildLabel('Phone Number', isRequired: true),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.phone_outlined,
                hintText: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 14),

              // 4. Email Address Field
              _buildLabel('Email Address', isRequired: true),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.mail_outline_rounded,
                hintText: 'Enter email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 14),

              // 5. Website Field
              _buildLabel('Website', isRequired: false),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.language_rounded,
                hintText: 'Enter website URL',
                controller: _websiteController,
              ),

              const SizedBox(height: 14),

              // 6. GSTIN / Tax ID Field
              _buildLabel('GSTIN / Tax ID', isRequired: false),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.receipt_long_outlined,
                hintText: 'Enter GSTIN or Tax ID',
                controller: _gstinController,
              ),

              const SizedBox(height: 14),

              // 7. Currency Symbol Field
              _buildLabel('Currency Symbol (e.g., ₹, \$, €, £)', isRequired: false),
              const SizedBox(height: 6),
              _buildIconInputField(
                icon: Icons.currency_rupee_rounded,
                hintText: 'Enter currency symbol',
                controller: _currencyController,
              ),

              const SizedBox(height: 14),

              // 8. Terms & Conditions Field
              _buildLabel('Terms & Conditions', isRequired: false),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: inputBorderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: lightGreenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.description_outlined, color: primaryGreen, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _termsController,
                            maxLines: 3,
                            maxLength: 200,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              hintText: 'Enter terms & conditions',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '$_termsLength/200',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Primary Action Button
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
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              widget.isEdit ? 'Update Profile' : 'Save & Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label, {required bool isRequired}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconInputField({
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFECFDF5);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: inputBorderColor, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: lightGreenBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryGreen, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
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
          ),
        ],
      ),
    );
  }
}
