import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import 'trial_dialog.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _daysRemaining = 26;
  String _userName = 'Ashish Sharma';
  bool _dialogShown = false;
  @override
  void initState() {
    super.initState();
    _checkTrialAndUser();
  }

  Future<void> _checkTrialAndUser() async {
    final prefs = await SharedPreferences.getInstance();
    final validityStr = prefs.getString(AppConstants.keyValidityDate);
    final days = AppDateUtils.getDaysRemaining(validityStr);
    final storedName = prefs.getString(AppConstants.keyUserName);

    if (mounted) {
      setState(() {
        _daysRemaining = days > 0 ? days : 26;
        if (storedName != null && storedName.trim().isNotEmpty) {
          _userName = storedName.trim();
        }
      });

      if (!_dialogShown) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          TrialDialog.showIfNeeded(context, days);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Stack with Gradient & Premium Trial Card
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF02472B),
                          Color(0xFF045435),
                          Color(0xFF066842),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 20,
                      right: 20,
                      bottom: 60,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Hello, $_userName 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // IconButton(
                            //   icon: const Icon(
                            //     Icons.notifications_none_rounded,
                            //     color: Colors.white,
                            //     size: 26,
                            //   ),
                            //   onPressed: () => context.push('/settings'),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create, manage and share\nstunning catalogs',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Premium Trial Banner Card
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: -32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDF0),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.stars_rounded,
                              color: Color(0xFFD97706),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "You're on Premium Trial",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$_daysRemaining days left',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => context.push('/subscription'),
                            child: const Text(
                              'View Plan',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Main Feature Action Cards (Stacked vertically)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    // Card 1: Manage Products
                    _buildFeatureCard(
                      title: 'Manage Products',
                      subtitle: 'Add, edit and manage\nyour products',
                      titleColor: const Color(0xFF045435),
                      accentColor: const Color(0xFF045435),
                      bgColor: const Color(0xFFE8F5E9),
                      icon: const ShoppingBagTagIcon(color: Color(0xFF045435), size: 30),
                      onTap: () => context.push('/product-list'),
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Manage Categories
                    _buildFeatureCard(
                      title: 'Manage Categories',
                      subtitle: 'Organize and manage\nyour product categories',
                      titleColor: const Color(0xFF0C4A6E),
                      accentColor: const Color(0xFF0284C7),
                      bgColor: const Color(0xFFE0F2FE),
                      icon: const FolderTagIcon(color: Color(0xFF0284C7), size: 30),
                      onTap: () => context.push('/category-list'),
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Manage Catalogs
                    _buildFeatureCard(
                      title: 'Manage Catalogs',
                      subtitle: 'Create, edit and share\nbeautiful catalogs',
                      titleColor: const Color(0xFF581C87),
                      accentColor: const Color(0xFF7E22CE),
                      bgColor: const Color(0xFFF3E8FF),
                      icon: const CatalogBookIcon(color: Color(0xFF7E22CE), size: 30),
                      onTap: () => context.push('/catalog-list'),
                    ),
                  ],
                ),
              ),

              // const SizedBox(height: 30),
              //
              // // Box Illustration & Headline
              // Center(
              //   child: Column(
              //     children: [
              //       Image.asset(
              //         'assets/catalog_box_illustration.jpg',
              //         height: 190,
              //         fit: BoxFit.contain,
              //         errorBuilder: (context, error, stackTrace) => const SizedBox(height: 100),
              //       ),
              //       const SizedBox(height: 12),
              //       const Text(
              //         'Everything you need to\ncreate amazing catalogs',
              //         textAlign: TextAlign.center,
              //         style: TextStyle(
              //           fontSize: 16,
              //           fontWeight: FontWeight.bold,
              //           color: Color(0xFF1E293B),
              //           height: 1.3,
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       Container(
              //         width: 32,
              //         height: 3,
              //         decoration: BoxDecoration(
              //           color: primaryGreen,
              //           borderRadius: BorderRadius.circular(2),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color accentColor,
    required Color bgColor,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left Accent Colored Bar
              Container(
                width: 5,
                color: accentColor,
              ),
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        // Square Icon Container
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(16),
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
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 4),
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
                        // Right Chevron Circle
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: bgColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: accentColor,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter Icons to match exact vector design in screenshot

class ShoppingBagTagIcon extends StatelessWidget {
  final Color color;
  final double size;
  const ShoppingBagTagIcon({super.key, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ShoppingBagTagPainter(color: color),
      ),
    );
  }
}

class _ShoppingBagTagPainter extends CustomPainter {
  final Color color;
  _ShoppingBagTagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Bag handles (Top curve)
    final handlePath = Path();
    handlePath.moveTo(w * 0.35, h * 0.28);
    handlePath.cubicTo(w * 0.35, h * 0.1, w * 0.65, h * 0.1, w * 0.65, h * 0.28);
    canvas.drawPath(handlePath, strokePaint);

    // Bag body
    final r = RRect.fromLTRBR(
      w * 0.15, h * 0.28, w * 0.85, h * 0.9,
      const Radius.circular(5),
    );
    canvas.drawRRect(r, strokePaint);

    // Price tag inside bag
    final tagPath = Path();
    tagPath.moveTo(w * 0.45, h * 0.42);
    tagPath.lineTo(w * 0.62, h * 0.42);
    tagPath.lineTo(w * 0.70, h * 0.55);
    tagPath.lineTo(w * 0.53, h * 0.75);
    tagPath.lineTo(w * 0.45, h * 0.65);
    tagPath.close();
    canvas.drawPath(tagPath, strokePaint);

    // Tag hole
    canvas.drawCircle(Offset(w * 0.52, h * 0.48), 1.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FolderTagIcon extends StatelessWidget {
  final Color color;
  final double size;
  const FolderTagIcon({super.key, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FolderTagPainter(color: color),
      ),
    );
  }
}

class _FolderTagPainter extends CustomPainter {
  final Color color;
  _FolderTagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Folder outline
    final folderPath = Path();
    folderPath.moveTo(w * 0.12, h * 0.28);
    folderPath.lineTo(w * 0.4, h * 0.28);
    folderPath.lineTo(w * 0.48, h * 0.38);
    folderPath.lineTo(w * 0.88, h * 0.38);
    folderPath.lineTo(w * 0.88, h * 0.82);
    folderPath.lineTo(w * 0.12, h * 0.82);
    folderPath.close();
    canvas.drawPath(folderPath, strokePaint);

    // Tag inside folder
    final tagPath = Path();
    tagPath.moveTo(w * 0.4, h * 0.5);
    tagPath.lineTo(w * 0.58, h * 0.5);
    tagPath.lineTo(w * 0.68, h * 0.62);
    tagPath.lineTo(w * 0.50, h * 0.74);
    tagPath.lineTo(w * 0.4, h * 0.64);
    tagPath.close();
    canvas.drawPath(tagPath, strokePaint);

    // Tag hole
    canvas.drawCircle(Offset(w * 0.47, h * 0.56), 1.5, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CatalogBookIcon extends StatelessWidget {
  final Color color;
  final double size;
  const CatalogBookIcon({super.key, required this.color, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CatalogBookPainter(color: color),
      ),
    );
  }
}

class _CatalogBookPainter extends CustomPainter {
  final Color color;
  _CatalogBookPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Book outer frame (Open book)
    final leftPage = Path();
    leftPage.moveTo(w * 0.15, h * 0.25);
    leftPage.lineTo(w * 0.46, h * 0.25);
    leftPage.lineTo(w * 0.46, h * 0.78);
    leftPage.lineTo(w * 0.15, h * 0.78);
    leftPage.close();

    final rightPage = Path();
    rightPage.moveTo(w * 0.54, h * 0.25);
    rightPage.lineTo(w * 0.85, h * 0.25);
    rightPage.lineTo(w * 0.85, h * 0.78);
    rightPage.lineTo(w * 0.54, h * 0.78);
    rightPage.close();

    canvas.drawPath(leftPage, strokePaint);
    canvas.drawPath(rightPage, strokePaint);

    // Spine connector
    final spine = Path();
    spine.moveTo(w * 0.46, h * 0.78);
    spine.quadraticBezierTo(w * 0.50, h * 0.84, w * 0.54, h * 0.78);
    canvas.drawPath(spine, strokePaint);

    // Page text lines inside left page
    canvas.drawLine(Offset(w * 0.22, h * 0.38), Offset(w * 0.38, h * 0.38), strokePaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.52), Offset(w * 0.38, h * 0.52), strokePaint);
    canvas.drawLine(Offset(w * 0.22, h * 0.66), Offset(w * 0.38, h * 0.66), strokePaint);

    // Page text lines inside right page
    canvas.drawLine(Offset(w * 0.62, h * 0.38), Offset(w * 0.78, h * 0.38), strokePaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.52), Offset(w * 0.78, h * 0.52), strokePaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.66), Offset(w * 0.78, h * 0.66), strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
