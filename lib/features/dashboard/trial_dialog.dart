import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class TrialDialog extends StatefulWidget {
  final int daysRemaining;
  final String? validityDateStr;

  const TrialDialog({
    super.key,
    required this.daysRemaining,
    this.validityDateStr,
  });

  static Future<void> showIfNeeded(BuildContext context, int daysRemaining) async {
    final prefs = await SharedPreferences.getInstance();

    // Only free-trial users see this popup. `flag` comes from the auth
    // response: 0 = free trial, anything else (1) = paid subscription.
    final subFlag = prefs.getInt(AppConstants.keySubFlag) ?? 0;
    if (subFlag != 0) return;

    final validityDateStr = prefs.getString(AppConstants.keyValidityDate) ?? '2026-08-19';

    if (!context.mounted) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return TrialDialog(
          daysRemaining: daysRemaining,
          validityDateStr: validityDateStr,
        );
      },
    );
  }

  @override
  State<TrialDialog> createState() => _TrialDialogState();
}

class _TrialDialogState extends State<TrialDialog> {
  String _formattedValidity = '19 August 2026';

  @override
  void initState() {
    super.initState();
    _formatDateStr();
  }

  void _formatDateStr() {
    if (widget.validityDateStr != null && widget.validityDateStr!.isNotEmpty) {
      try {
        final dt = DateTime.parse(widget.validityDateStr!);
        final months = [
          'January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December'
        ];
        setState(() {
          _formattedValidity = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
        });
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF045435);
    const goldColor = Color(0xFFEAB308);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),

                // Top Badge with Star Burst Confetti Accents
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 140,
                      height: 90,
                      child: Stack(
                        children: [
                          Positioned(top: 10, left: 10, child: Icon(Icons.star_rate_rounded, color: Color(0xFF86EFAC), size: 14)),
                          Positioned(top: 30, right: 12, child: Icon(Icons.star_rate_rounded, color: Color(0xFFFDE047), size: 16)),
                          Positioned(bottom: 12, left: 20, child: Icon(Icons.circle, color: Color(0xFFFACC15), size: 8)),
                          Positioned(bottom: 20, right: 24, child: Icon(Icons.star_rate_rounded, color: Color(0xFF86EFAC), size: 18)),
                        ],
                      ),
                    ),

                    // Scalloped Badge Circle
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33045435),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: goldColor,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  'Your Free Trial is Active!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(text: 'You have '),
                      TextSpan(
                        text: '${widget.daysRemaining} days',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const TextSpan(text: ' remaining in your\ntrial period.'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info Card Box
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Trial Ends On
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF059669),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trial Ends On',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formattedValidity,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Row 2: Days Remaining
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFECFDF5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF059669),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Days Remaining',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.daysRemaining} days',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
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

                // Primary Button: Explore Premium Features
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/subscription');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Explore Premium Features',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary Button: Maybe Later
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top Right Close X Button
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
