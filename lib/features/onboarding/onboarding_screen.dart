import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color _primaryGreen = Color(0xFF045435);
  static const Color _lightGreenBg = Color(0xFFECFDF5);
  static const Color _gold = Color(0xFFCA8A04);
  static const Color _darkText = Color(0xFF0F172A);
  static const Color _subText = Color(0xFF64748B);
  static const Color _mutedText = Color(0xFF94A3B8);

  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = const [
    {
      'icon': Icons.inventory_2_rounded,
      'title': 'Create Product Catalogs Easily',
      'description':
          'Add your categories and products, then quickly build beautiful PDF and Image catalogs for your customers.',
    },
    {
      'icon': Icons.share_rounded,
      'title': 'Share & Grow Your Business',
      'description':
          'Export catalogs to PDF or Images, share them directly via WhatsApp or Email, and track your subscriptions.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage == _slides.length - 1;

  void _finishOnboarding() {
    context.go('/login');
  }

  void _onPrimaryPressed() {
    if (_isLastPage) {
      _finishOnboarding();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: brand mark + Skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _lightGreenBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: _primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Catalogue Maker',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: _subText,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) => _buildSlide(_slides[index]),
              ),
            ),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(Map<String, dynamic> slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration tile
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _lightGreenBg,
              borderRadius: BorderRadius.circular(48),
            ),
            child: Center(
              child: Container(
                width: 116,
                height: 116,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  slide['icon'] as IconData,
                  size: 54,
                  color: _primaryGreen,
                ),
              ),
            ),
          ),

          const SizedBox(height: 36),

          Text(
            slide['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: _darkText,
              height: 1.25,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 14),

          // Gold star divider, matching the splash screen
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 40, height: 1.5, color: const Color(0xFFE2E8F0)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.star_rounded, color: _gold, size: 14),
              ),
              Container(width: 40, height: 1.5, color: const Color(0xFFE2E8F0)),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            slide['description'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: _subText,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          // Page indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isActive = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? _primaryGreen : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _onPrimaryPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLastPage ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isLastPage
                        ? Icons.arrow_forward_rounded
                        : Icons.chevron_right_rounded,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Reserve the row height so the button never shifts between pages
          SizedBox(
            height: 36,
            child: _currentPage > 0
                ? TextButton(
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                    ),
                    style: TextButton.styleFrom(foregroundColor: _mutedText),
                    child: const Text(
                      'Back',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
