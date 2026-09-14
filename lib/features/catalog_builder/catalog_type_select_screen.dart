import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/catalog_builder_provider.dart';

class CatalogTypeSelectScreen extends ConsumerWidget {
  const CatalogTypeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builderState = ref.watch(catalogBuilderProvider);
    final notifier = ref.read(catalogBuilderProvider.notifier);
    const primaryPurple = Color(0xFF6366F1);
    const deepPurple = Color(0xFF4338CA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryPurple),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Select Layout Type',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: primaryPurple),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Choose grid layout or list layout for your catalog.')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Section Header
            const Text(
              'Choose Layout Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose how products will be displayed in your catalog.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),

            const SizedBox(height: 20),

            // Option 1: Grid Layout (Multiple Columns)
            _buildLayoutOptionCard(
              layoutType: 'grid',
              selectedType: builderState.type,
              icon: Icons.grid_view_rounded,
              title: 'Grid Layout (Multiple Columns)',
              subtitle: 'Best for visually displaying multiple products per page.',
              showRecommended: true,
              onTap: () => notifier.setType('grid'),
            ),

            const SizedBox(height: 14),

            // Option 2: List Layout (Single Column)
            _buildLayoutOptionCard(
              layoutType: 'list',
              selectedType: builderState.type,
              icon: Icons.format_list_bulleted_rounded,
              title: 'List Layout (Single Column)',
              subtitle: 'Detailed view showing description, size, colour & specs.',
              showRecommended: false,
              onTap: () => notifier.setType('list'),
            ),

            const Spacer(),

            // Bottom Primary Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: deepPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  if (builderState.type == 'list') {
                    context.push('/catalog-step4-list');
                  } else {
                    context.push('/catalog-step4');
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next: Choose Catalog Style',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutOptionCard({
    required String layoutType,
    required String selectedType,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showRecommended,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedType == layoutType;
    const primaryPurple = Color(0xFF6366F1);
    const deepPurpleText = Color(0xFF4338CA);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.04 : 0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio Indicator
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? primaryPurple : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 14),

            // Icon Avatar Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE0E7FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: primaryPurple,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                  ),
                  if (showRecommended) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Recommended',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: deepPurpleText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
