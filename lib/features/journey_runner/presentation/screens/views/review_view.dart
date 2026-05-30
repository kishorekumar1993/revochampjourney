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
  static const error = Color(0xFFEF4444);
  static const textLight = Color(0xFFB0B4C8);
}

class ReviewRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const ReviewRunnerView({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formValues,
    required this.formContentBuilder,
    required this.bottomBarBuilder,
    this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    
    // Calculate progress
    int completedStepsCount = 0;
    for (int i = 0; i < cfg.steps.length; i++) {
      if (i < activeIdx) completedStepsCount++;
    }
    final totalSteps = cfg.steps.length;
    final progressVal = totalSteps > 0 ? (completedStepsCount / totalSteps) : 0.0;

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
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview header card
                    _buildOverviewCard(completedStepsCount, totalSteps, progressVal, isMobile),
                    const SizedBox(height: 24),
                    
                    Text(
                      'Journey Review summary',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _IT.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // List of steps and values
                    ...List.generate(cfg.steps.length, (idx) {
                      final step = cfg.steps[idx];
                      final isCompleted = idx < activeIdx;
                      final isActive = idx == activeIdx;
                      final isUpcoming = idx > activeIdx;

                      return _buildStepReviewCard(context, step, idx, isCompleted, isActive, isUpcoming, isMobile);
                    }),
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

  Widget _buildOverviewCard(int completed, int total, double progress, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_IT.brand, Color(0xFF7C72E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _IT.brand.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journey Completion',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed of $total steps completed',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepReviewCard(
    BuildContext context,
    JourneyStep step,
    int idx,
    bool isCompleted,
    bool isActive,
    bool isUpcoming,
    bool isMobile,
  ) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = _IT.success;
      statusText = 'Completed';
      statusIcon = Icons.check_circle_rounded;
    } else if (isActive) {
      statusColor = _IT.brand;
      statusText = 'Active (In Progress)';
      statusIcon = Icons.pending_rounded;
    } else {
      statusColor = _IT.textMid;
      statusText = 'Pending';
      statusIcon = Icons.lock_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? _IT.brand : _IT.border.withValues(alpha: 0.8),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _IT.brand.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: ExpansionTile(
        key: PageStorageKey('review_step_${step.id}'),
        initiallyExpanded: isActive || isCompleted,
        leading: Icon(statusIcon, color: statusColor, size: 24),
        title: Text(
          step.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: _IT.textDark,
          ),
        ),
        subtitle: Text(
          statusText,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: (isCompleted || isActive)
            ? TextButton.icon(
                icon: const Icon(Icons.edit_rounded, size: 14),
                label: Text(
                  'Edit',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  if (onStepTap != null) onStepTap!(idx);
                },
              )
            : const Icon(Icons.chevron_right_rounded),
        childrenPadding: const EdgeInsets.all(20),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isUpcoming)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Complete previous steps to unlock this section.',
                style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid, fontStyle: FontStyle.italic),
              ),
            )
          else if (isActive)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: _IT.brandSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: _IT.brand, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are currently filling out this step. Complete the inputs below:',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _IT.brand,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                formContentBuilder(context, isMobile: isMobile),
              ],
            )
          else
            _buildAnswersList(step),
        ],
      ),
    );
  }

  Widget _buildAnswersList(JourneyStep step) {
    final fields = _flattenFields(step.fields);
    if (fields.isEmpty) {
      return Text(
        'No fields in this step.',
        style: GoogleFonts.poppins(fontSize: 12, color: _IT.textMid),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fields.length,
      separatorBuilder: (_, _) => const Divider(color: _IT.border, height: 24),
      itemBuilder: (context, fIdx) {
        final field = fields[fIdx];
        if (field.type.toLowerCase() == 'divider' || field.type.toLowerCase() == 'label') {
          return const SizedBox.shrink();
        }
        
        final val = formValues[field.id];
        final valStr = val?.toString() ?? '';
        final isRequired = field.required == true;
        final hasVal = valStr.trim().isNotEmpty;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Text(
                field.label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _IT.textMid,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: hasVal
                  ? Text(
                      valStr,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _IT.textDark,
                      ),
                    )
                  : Text(
                      isRequired ? 'Missing required input *' : 'Not filled',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isRequired ? _IT.error : _IT.textLight,
                        fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  List<JourneyField> _flattenFields(List<JourneyField> src) {
    final res = <JourneyField>[];
    for (final f in src) {
      res.add(f);
      if (f.nestedFields != null) {
        res.addAll(_flattenFields(f.nestedFields!));
      }
    }
    return res;
  }
}
