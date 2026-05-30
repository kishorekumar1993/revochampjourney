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
  static const success = Color(0xFF22C55E);
  static const bg = Color(0xFFF0F0FF);
  static const textLight = Color(0xFFB0B4C8);
}

class DashboardRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const DashboardRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 640;
    final crossAxisCount = screenW > 960 ? 3 : (screenW > 640 ? 2 : 1);
    
    // Stats calculation
    int completedCount = 0;
    for (int i = 0; i < cfg.steps.length; i++) {
      if (i < activeIdx) completedCount++;
    }
    final totalSteps = cfg.steps.length;
    final progress = totalSteps > 0 ? (completedCount / totalSteps) : 0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top header summary info
                    _buildHeaderSummary(completedCount, totalSteps, progress, isMobile),
                    const SizedBox(height: 28),
                    
                    Text(
                      'Journey Sections',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _IT.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Grid list of step cards
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cfg.steps.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 180,
                      ),
                      itemBuilder: (context, idx) {
                        final step = cfg.steps[idx];
                        final isCompleted = idx < activeIdx;
                        final isActive = idx == activeIdx;
                        final isUpcoming = idx > activeIdx;

                        return _buildStepCard(context, step, idx, isCompleted, isActive, isUpcoming);
                      },
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

  Widget _buildHeaderSummary(int completed, int total, double progress, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _IT.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _IT.brand.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryStats(completed, total),
                const SizedBox(height: 16),
                _buildProgressBar(progress),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildSummaryStats(completed, total)),
                const SizedBox(width: 40),
                Expanded(child: _buildProgressBar(progress)),
              ],
            ),
    );
  }

  Widget _buildSummaryStats(int completed, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Completion Progress',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _IT.textMid,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$completed of $total Tasks Finished',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _IT.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(progress * 100).toStringAsFixed(0)}% Done',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _IT.brand,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _IT.bg,
            valueColor: const AlwaysStoppedAnimation<Color>(_IT.brand),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    JourneyStep step,
    int idx,
    bool isCompleted,
    bool isActive,
    bool isUpcoming,
  ) {
    Color cardBorder = _IT.border;
    Color iconBg = _IT.bg;
    Color iconColor = _IT.textMid;
    Widget statusBadge;
    Widget cardAction;

    if (isCompleted) {
      cardBorder = _IT.success.withValues(alpha: 0.5);
      iconBg = _IT.success.withValues(alpha: 0.1);
      iconColor = _IT.success;
      statusBadge = _badge(Icons.check_circle_rounded, 'Completed', _IT.success);
      cardAction = _textBtn('View Details', () {
        if (onStepTap != null) onStepTap!(idx);
      }, _IT.success);
    } else if (isActive) {
      cardBorder = _IT.brand;
      iconBg = _IT.brandSurface;
      iconColor = _IT.brand;
      statusBadge = _badge(Icons.pending_rounded, 'In Progress', _IT.brand);
      cardAction = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _IT.brand,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        onPressed: () {
          if (onStepTap != null) onStepTap!(idx);
        },
        child: Text(
          'Continue',
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      statusBadge = _badge(Icons.lock_rounded, 'Locked', _IT.textLight);
      cardAction = Text(
        'Locked',
        style: GoogleFonts.poppins(fontSize: 11, color: _IT.textLight, fontWeight: FontWeight.w600),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: isActive ? 1.5 : 1),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIconForTitle(step.title), color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _IT.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    statusBadge,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              step.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 11, color: _IT.textMid, height: 1.3),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [cardAction],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _textBtn(String text, VoidCallback onPressed, Color color) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains('personal')) return Icons.person_outline_rounded;
    if (t.contains('vehicle')) return Icons.directions_car_outlined;
    if (t.contains('nominee')) return Icons.supervisor_account_outlined;
    if (t.contains('document')) return Icons.upload_file_outlined;
    if (t.contains('review')) return Icons.rate_review_outlined;
    if (t.contains('payment')) return Icons.credit_card_outlined;
    return Icons.assignment_outlined;
  }
}
