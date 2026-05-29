import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const textLight = Color(0xFFB0B4C8);
  static const border = Color(0xFFE4E6F0);
  static const success = Color(0xFF22C55E);
  static const successSurface = Color(0xFFE8F9EE);
  static const cardBg = Color(0xFFFAFAFF);
}

class TimelineRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final void Function(int) onStepTap;

  const TimelineRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formValues,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: cfg.steps.length,
            itemBuilder: (context, index) {
              final step = cfg.steps[index];
              final isCompleted = index < activeIdx;
              final isActive = index == activeIdx;
              final isUpcoming = index > activeIdx;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vertical Line & Node
                      _buildTimelineIndicator(index, isCompleted, isActive, isUpcoming),
                      const SizedBox(width: 16),
                      // Content Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildStepCard(context, step, index, isCompleted, isActive, isUpcoming),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildTimelineIndicator(int index, bool isCompleted, bool isActive, bool isUpcoming) {
    return Column(
      children: [
        // Node
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive
                ? _IT.brand
                : isCompleted
                    ? _IT.success
                    : _IT.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive
                  ? _IT.brand
                  : isCompleted
                      ? _IT.success
                      : _IT.border,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _IT.brand.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : isActive
                    ? Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _IT.textLight,
                        ),
                      ),
          ),
        ),
        // Connector line
        if (index < cfg.steps.length - 1)
          Container(
            width: 2,
            height: 80,
            color: isCompleted ? _IT.success : _IT.border,
          ),
      ],
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    JourneyStep step,
    int index,
    bool isCompleted,
    bool isActive,
    bool isUpcoming,
  ) {
    if (isActive) {
      return Container(
        decoration: BoxDecoration(
          color: _IT.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _IT.brand, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _IT.brand.withValues(alpha: 0.08),
              blurRadius: 30,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: formContentBuilder(context, isMobile: false),
      );
    }

    if (isCompleted) {
      final summary = _getAnswersSummary(step);
      return GestureDetector(
        onTap: () => onStepTap(index),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: _IT.successSurface.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _IT.success.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            step.title,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _IT.textDark,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _IT.successSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Completed',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _IT.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: summary.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _IT.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _IT.border),
                              ),
                              child: Text(
                                '${e.key}: ${e.value}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _IT.textMid,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => onStepTap(index),
                  icon: const Icon(Icons.edit_outlined, size: 14, color: _IT.brand),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _IT.brand,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Upcoming / Locked
    return Container(
      decoration: BoxDecoration(
        color: _IT.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _IT.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, size: 18, color: _IT.textLight),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _IT.textLight,
                  ),
                ),
                Text(
                  'Locked until previous steps are completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _IT.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, String> _getAnswersSummary(JourneyStep step) {
    final Map<String, String> summary = {};
    for (final field in step.flattenedFields) {
      if (field.type == 'divider' || field.type == 'section' || field.type == 'card' || field.type == 'row' || field.type == 'column') {
        continue;
      }
      final val = formValues[field.id];
      if (val != null && val.toString().trim().isNotEmpty) {
        // limit summary length
        String valStr = val.toString();
        if (valStr.length > 20) {
          valStr = '${valStr.substring(0, 17)}...';
        }
        summary[field.label] = valStr;
      }
    }
    return summary;
  }
}
