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
  static const bg = Color(0xFFF7F8FC);
}

class StepperRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const StepperRunnerView({
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
    final isMobile = screenW < 720;

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _IT.brand,
          secondary: _IT.brand,
          background: Colors.white,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _IT.border, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: _IT.brand.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stepper(
                      type: isMobile ? StepperType.vertical : StepperType.horizontal,
                      currentStep: activeIdx,
                      onStepTapped: (idx) {
                        if (idx <= activeIdx && onStepTap != null) {
                          onStepTap!(idx);
                        }
                      },
                      controlsBuilder: (context, details) {
                        // Suppress stepper's default continue/cancel buttons, as we use bottomBarBuilder
                        return const SizedBox.shrink();
                      },
                      steps: List.generate(cfg.steps.length, (idx) {
                        final step = cfg.steps[idx];
                        final isCompleted = idx < activeIdx;
                        final isActive = idx == activeIdx;
                        
                        StepState state;
                        if (isCompleted) {
                          state = StepState.complete;
                        } else if (isActive) {
                          state = StepState.editing;
                        } else {
                          state = StepState.disabled;
                        }

                        return Step(
                          title: Text(
                            step.title,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? _IT.textDark : _IT.textMid,
                            ),
                          ),
                          subtitle: isMobile ? null : Text(
                            isActive ? 'Active' : (isCompleted ? 'Done' : 'Locked'),
                            style: GoogleFonts.poppins(fontSize: 10),
                          ),
                          state: state,
                          isActive: isActive || isCompleted,
                          content: isActive
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                                  child: formContentBuilder(context, isMobile: isMobile),
                                )
                              : Container(),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          bottomBarBuilder(),
        ],
      ),
    );
  }
}
