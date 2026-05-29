import 'package:flutter/material.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const brandSurface = Color(0xFFEEECFD);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const border = Color(0xFFE4E6F0);
}

class CarouselRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final void Function(int) onStepTap;

  const CarouselRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = cfg.steps.length;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Row(
                  children: [
                    // Left Chevron for navigation (desktop only)
                    if (MediaQuery.of(context).size.width > 640)
                      _buildNavigationChevron(
                        icon: Icons.chevron_left_rounded,
                        onTap: activeIdx > 0 ? () => onStepTap(activeIdx - 1) : null,
                      ),
                    
                    // Main Card Carousel Area
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _IT.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _IT.border.withValues(alpha: 0.8)),
                          boxShadow: [
                            BoxShadow(
                              color: _IT.brand.withValues(alpha: 0.08),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Carousel Header Step Dot Indicators
                            _buildCarouselIndicator(total),
                            const SizedBox(height: 20),
                            // Form content
                            Expanded(
                              child: SingleChildScrollView(
                                child: formContentBuilder(context, isMobile: false),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Right Chevron for navigation (desktop only)
                    if (MediaQuery.of(context).size.width > 640)
                      _buildNavigationChevron(
                        icon: Icons.chevron_right_rounded,
                        onTap: activeIdx < total - 1 ? () => onStepTap(activeIdx + 1) : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildNavigationChevron({required IconData icon, VoidCallback? onTap}) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade100 : _IT.brandSurface,
          shape: BoxShape.circle,
          border: Border.all(color: disabled ? Colors.transparent : _IT.brand.withValues(alpha: 0.2)),
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.grey.shade400 : _IT.brand,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCarouselIndicator(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == activeIdx;
        final isCompleted = index < activeIdx;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? _IT.brand
                : isCompleted
                    ? _IT.brand.withValues(alpha: 0.4)
                    : _IT.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
