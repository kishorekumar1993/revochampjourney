import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

class RunnerLeftPanel extends StatelessWidget {
  final JourneyStep step;
  final int activeIdx;
  final int total;

  const RunnerLeftPanel({
    super.key,
    required this.step,
    required this.activeIdx,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: RunnerTheme.leftPanelBg,
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RunnerTheme.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: RunnerTheme.brand.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _stepIconForTitle(step.title),
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            step.title,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: RunnerTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            step.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: RunnerTheme.textMid,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          // illustration
          Expanded(child: Center(child: _buildIllustration(step.title))),
          const SizedBox(height: 20),
          // step mini-list (only show nearby steps)
          _buildMiniStepList(activeIdx, total),
          const SizedBox(height: 16),
          // security badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RunnerTheme.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RunnerTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: RunnerTheme.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: RunnerTheme.brand,
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
                          color: RunnerTheme.textDark,
                        ),
                      ),
                      Text(
                        'Bank-level encryption used.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: RunnerTheme.textMid,
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

  Widget _buildMiniStepList(int activeIdx, int total) {
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
                ? RunnerTheme.brand
                : isDone
                    ? RunnerTheme.brand.withValues(alpha: 0.3)
                    : RunnerTheme.border,
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
              color: RunnerTheme.brand.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: RunnerTheme.brand.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: RunnerTheme.brandSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: RunnerTheme.brand.withValues(alpha: 0.13),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: RunnerTheme.brand, size: 32),
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
}
