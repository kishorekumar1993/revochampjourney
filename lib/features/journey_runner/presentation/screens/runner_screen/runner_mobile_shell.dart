import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/domain/entities/journey_models.dart';
import '../../../domain/journey_execution_models.dart';
import 'runner_theme.dart';
import 'widgets/runner_form_content.dart';

class RunnerMobileShell extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final bool showSubmit;
  final Map<String, String> errors;
  final bool isExecuting;
  final List<String> stepHistory;
  final GlobalKey<FormState> formKey;
  final Future<void> Function(JourneyAction, JourneyStep, JourneyConfig) runAction;
  final void Function(String, {bool isError}) showSnack;

  const RunnerMobileShell({
    super.key,
    required this.cfg,
    required this.activeStep,
    required this.activeIdx,
    required this.formValues,
    required this.showSubmit,
    required this.errors,
    required this.isExecuting,
    required this.stepHistory,
    required this.formKey,
    required this.runAction,
    required this.showSnack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMobileStepBadge(cfg, activeIdx),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: RunnerFormContent(
              cfg: cfg,
              activeStep: activeStep,
              activeIdx: activeIdx,
              formValues: formValues,
              errors: errors,
              showSubmit: showSubmit,
              isMobile: true,
              isExecuting: isExecuting,
              stepHistory: stepHistory,
              formKey: formKey,
              runAction: runAction,
              showSnack: showSnack,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStepBadge(JourneyConfig cfg, int activeIdx) {
    final step = cfg.steps[activeIdx];
    return Container(
      color: RunnerTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(color: RunnerTheme.brand, shape: BoxShape.circle),
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
                    color: RunnerTheme.textDark,
                  ),
                ),
                Text(
                  'Step ${activeIdx + 1} of ${cfg.steps.length}',
                  style: GoogleFonts.poppins(fontSize: 11, color: RunnerTheme.textMid),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: const BoxDecoration(
              color: RunnerTheme.brandSurface,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Text(
              '${activeIdx + 1}/${cfg.steps.length}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: RunnerTheme.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
