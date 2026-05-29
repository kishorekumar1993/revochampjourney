import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const brandSurface = Color(0xFFEEECFD);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const border = Color(0xFFE4E6F0);
  static const leftPanelBg = Color(0xFFF7F5FF);
}

class SplitRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;

  const SplitRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 640;

    if (isMobile) {
      return Column(
        children: [
          _buildMobileStepBadge(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: formContentBuilder(context, isMobile: true),
            ),
          ),
          bottomBarBuilder(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Container(
                  decoration: BoxDecoration(
                    color: _IT.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _IT.brand.withValues(alpha: 0.07),
                        blurRadius: 40,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // LEFT PANEL — fixed width, does NOT scroll
                      SizedBox(
                        width: 270,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            bottomLeft: Radius.circular(24),
                          ),
                          child: _buildLeftPanel(),
                        ),
                      ),
                      // vertical divider
                      Container(width: 1, color: _IT.border),
                      // RIGHT PANEL — scrollable independently
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: formContentBuilder(context, isMobile: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      color: _IT.leftPanelBg,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _IT.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _stepIconForTitle(activeStep.title),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            activeStep.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _IT.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            activeStep.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _IT.textMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // illustration
          Expanded(child: Center(child: _buildIllustration(activeStep.title))),
          const SizedBox(height: 20),
          // step mini-list (only show nearby steps)
          _buildMiniStepList(),
          const SizedBox(height: 16),
          // security badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _IT.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _IT.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: _IT.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: _IT.brand,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your info is safe with us',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _IT.textDark,
                        ),
                      ),
                      Text(
                        'Bank-level encryption used.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: _IT.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStepList() {
    final total = cfg.steps.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total > 7 ? 7 : total, (i) {
        final idx = total > 7 ? (activeIdx - 3 + i).clamp(0, total - 1) : i;
        final isActive = idx == activeIdx;
        final isDone = idx < activeIdx;
        return Container(
          width: isActive ? 22 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? _IT.brand
                : isDone
                    ? _IT.brand.withValues(alpha: 0.3)
                    : _IT.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildIllustration(String title) {
    final icon = _stepIconForTitle(title);
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: _IT.brand.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _IT.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: _IT.brandSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x215B4FCF),
                  blurRadius: 18,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: _IT.brand, size: 32),
          ),
        ],
      ),
    );
  }

  IconData _stepIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('personal')) return Icons.person_outline_rounded;
    if (t.contains('vehicle')) return Icons.directions_car_outlined;
    if (t.contains('nominee')) return Icons.supervisor_account_outlined;
    if (t.contains('document')) return Icons.upload_file_outlined;
    if (t.contains('review') || t.contains('confirm')) {
      return Icons.fact_check_outlined;
    }
    if (t.contains('payment')) return Icons.credit_card_outlined;
    if (t.contains('success')) return Icons.verified_outlined;
    return Icons.article_outlined;
  }

  Widget _buildMobileStepBadge() {
    final step = cfg.steps[activeIdx];
    return Container(
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: _IT.brand, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${activeIdx + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _IT.textDark,
                  ),
                ),
                Text(
                  'Step ${activeIdx + 1} of ${cfg.steps.length}',
                  style: GoogleFonts.poppins(fontSize: 11, color: _IT.textMid),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: const BoxDecoration(
              color: _IT.brandSurface,
              // borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${activeIdx + 1}/${cfg.steps.length}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _IT.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
