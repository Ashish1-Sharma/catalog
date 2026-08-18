import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/services/product_image_service.dart';
import '../../data/database/app_database.dart';
import '../../providers/app_providers.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedCategoryId;
  final _nameController = TextEditingController();
  final _mrpController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _discountController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colourController = TextEditingController();
  final _quantityController = TextEditingController();
  final _gstPercentController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _imagePath;
  bool _isLoading = false;
  int _descLength = 0;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _selectedCategoryId = p.categoryId;
      _nameController.text = p.name;
      _mrpController.text = p.mrp > 0 ? p.mrp.toString() : '';
      _salePriceController.text = p.salePrice > 0 ? p.salePrice.toString() : '';
      _discountController.text = p.discount?.toString() ?? '';
      _sizeController.text = p.size ?? '';
      _colourController.text = p.colour ?? '';
      _quantityController.text = p.quantity ?? '';
      _gstPercentController.text = p.gstPercent?.toString() ?? '';
      _descriptionController.text = p.description ?? '';
      _imagePath = p.imagePath;
      _descLength = p.description?.length ?? 0;
    }
    _descriptionController.addListener(() {
      setState(() {
        _descLength = _descriptionController.text.length;
      });
    });
    _refreshImagePathFromDb();
  }

  /// The Product handed to this screen comes from a cached provider list, so
  /// its imagePath can be stale — the startup repair pass may have moved the
  /// file into permanent storage since. Re-read the row so the form shows the
  /// current image instead of a dead path.
  Future<void> _refreshImagePathFromDb() async {
    final existing = widget.product;
    if (existing == null) return;
    try {
      final fresh = await ref.read(productRepoProvider).getProductById(existing.id);
      if (!mounted || fresh == null) return;
      if (fresh.imagePath != _imagePath) {
        setState(() => _imagePath = fresh.imagePath);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mrpController.dispose();
    _salePriceController.dispose();
    _discountController.dispose();
    _sizeController.dispose();
    _colourController.dispose();
    _quantityController.dispose();
    _gstPercentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (img == null) return;

    // image_picker returns a cache path the OS can purge. Copy it into
    // permanent storage before it ever reaches the database.
    final persistedPath = await ProductImageService.persist(img.path);
    if (!mounted) return;
    setState(() {
      _imagePath = persistedPath;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final name = _nameController.text.trim();
    final mrp = double.tryParse(_mrpController.text.trim()) ?? 0.0;
    final salePrice = double.tryParse(_salePriceController.text.trim()) ?? mrp;
    final discount = double.tryParse(_discountController.text.trim());
    final size = _sizeController.text.trim();
    final colour = _colourController.text.trim();
    final quantity = _quantityController.text.trim();
    final gstPercent = double.tryParse(_gstPercentController.text.trim());
    final description = _descriptionController.text.trim();

    final repo = ref.read(productRepoProvider);

    try {
      if (widget.product != null) {
        // Base the update on the CURRENT row, not the (possibly stale) copy
        // this screen was constructed with — otherwise saving would write an
        // old image path back over one the repair pass already fixed.
        final base = await repo.getProductById(widget.product!.id) ?? widget.product!;
        final updated = base.copyWith(
          categoryId: _selectedCategoryId!,
          name: name,
          imagePath: drift.Value(_imagePath),
          mrp: mrp,
          salePrice: salePrice,
          discount: drift.Value(discount),
          size: drift.Value(size.isEmpty ? null : size),
          colour: drift.Value(colour.isEmpty ? null : colour),
          quantity: drift.Value(quantity.isEmpty ? null : quantity),
          gstPercent: drift.Value(gstPercent),
          description: drift.Value(description.isEmpty ? null : description),
        );
        final ok = await repo.updateProduct(updated);
        if (!ok) throw Exception('No product row matched id ${updated.id}');
      } else {
        final companion = ProductsCompanion(
          categoryId: drift.Value(_selectedCategoryId!),
          name: drift.Value(name),
          imagePath: drift.Value(_imagePath),
          mrp: drift.Value(mrp),
          salePrice: drift.Value(salePrice),
          discount: drift.Value(discount),
          size: drift.Value(size.isEmpty ? null : size),
          colour: drift.Value(colour.isEmpty ? null : colour),
          quantity: drift.Value(quantity.isEmpty ? null : quantity),
          gstPercent: drift.Value(gstPercent),
          description: drift.Value(description.isEmpty ? null : description),
        );
        await repo.addProduct(companion);
      }

      ref.invalidate(productsProvider);
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.pop();
    } catch (e) {
      // Without this the spinner stayed on forever and the save looked "stuck".
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEdit = widget.product != null;
    const primaryGreen = Color(0xFF045435);
    const lightGreenBg = Color(0xFFECFDF5);
    const inputBorderColor = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryGreen),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Edit Product' : 'Add Product',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Add detailed information about your product',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF64748B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill in product details and save to add to catalog.')),
              );
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'You must add at least one Category before adding products.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category Now'),
                      onPressed: () => context.push('/add-category'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_selectedCategoryId == null && categories.isNotEmpty) {
            _selectedCategoryId = categories.first.id;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker Card
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                      ),
                      child: _imagePath != null && File(_imagePath!).existsSync()
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity, height: 140),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                      SizedBox(width: 4),
                                      Text('Change Image', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: lightGreenBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: Color(0xFF059669),
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add Product Image',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'JPG, PNG up to 5MB',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 1. Category Dropdown
                  _buildLabel('Category', isRequired: true),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          child: const Icon(Icons.folder_outlined, color: primaryGreen, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedCategoryId,
                              isExpanded: true,
                              hint: const Text('Select category', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                              items: categories.map((cat) {
                                return DropdownMenuItem<int>(
                                  value: cat.id,
                                  child: Text(cat.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedCategoryId = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Product Name Field
                  _buildLabel('Product Name', isRequired: true),
                  const SizedBox(height: 6),
                  _buildIconInputField(
                    icon: Icons.shopping_bag_outlined,
                    hintText: 'Enter product name',
                    controller: _nameController,
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),

                  // 3. MRP (₹) & Sale Price (₹) Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('MRP (₹)', isRequired: true),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.currency_rupee_rounded,
                              hintText: 'Enter MRP',
                              controller: _mrpController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Sale Price (₹)', isRequired: true),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.local_offer_outlined,
                              hintText: 'Enter sale price',
                              controller: _salePriceController,
                              keyboardType: TextInputType.number,
                              validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 4. Discount (%) & Quantity / MOQ Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Discount (%)', isRequired: false),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.percent_rounded,
                              hintText: 'Enter discount',
                              controller: _discountController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Quantity / MOQ', isRequired: true),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.inventory_2_outlined,
                              hintText: 'Enter quantity or MOQ',
                              controller: _quantityController,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 5. Size & Colour Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Size', isRequired: false),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.straighten_rounded,
                              hintText: 'Enter size',
                              controller: _sizeController,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Colour', isRequired: false),
                            const SizedBox(height: 6),
                            _buildIconInputField(
                              icon: Icons.palette_outlined,
                              hintText: 'Enter colour',
                              controller: _colourController,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 6. GST (%) — optional, used by the "With GST" list template
                  _buildLabel('GST (%)', isRequired: false),
                  const SizedBox(height: 6),
                  _buildIconInputField(
                    icon: Icons.receipt_long_outlined,
                    hintText: 'e.g. 18 (shown on GST catalogs)',
                    controller: _gstPercentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),

                  const SizedBox(height: 16),

                  // 7. Description Text Area
                  _buildLabel('Description', isRequired: false),
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
                                controller: _descriptionController,
                                maxLines: 4,
                                maxLength: 500,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                decoration: const InputDecoration(
                                  hintText: 'Enter product description',
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
                            '$_descLength/500',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 8. Tip Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFDCFCE7), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
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
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tip',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Provide accurate details to help customers understand your product better.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF047857), height: 1.2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFF059669),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 9. Save Product Button
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
                      onPressed: _isLoading ? null : _save,
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
                                  isEdit ? 'Update Product' : 'Save Product',
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLabel(String label, {required bool isRequired}) {
    return Row(
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
