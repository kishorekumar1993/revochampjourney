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
  static const textLight = Color(0xFFB0B4C8);
}

class WizardRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final Function(int)? onStepTap;

  const WizardRunnerView({
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
    final isMobile = MediaQuery.of(context).size.width < 640;
    
    return Column(
      children: [
        // Custom Wizard Progress Bar
        _buildWizardSteps(context, isMobile),
        
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 32,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 18 : 32),
                  decoration: BoxDecoration(
                    color: _IT.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _IT.brand.withValues(alpha: 0.06),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(color: _IT.border.withValues(alpha: 0.5)),
                  ),
                  child: formContentBuilder(context, isMobile: isMobile),
                ),
              ),
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildWizardSteps(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _IT.white,
        border: Border(bottom: BorderSide(color: _IT.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: List.generate(cfg.steps.length, (idx) {
              final step = cfg.steps[idx];
              final isCompleted = idx < activeIdx;
              final isActive = idx == activeIdx;

              Color stepColor;
              if (isCompleted) {
                stepColor = _IT.success;
              } else if (isActive) {
                stepColor = _IT.brand;
              } else {
                stepColor = _IT.textLight;
              }

              return Expanded(
                child: Row(
                  children: [
                    // Step indicator node
                    GestureDetector(
                      onTap: () {
                        if (idx <= activeIdx && onStepTap != null) {
                          onStepTap!(idx);
                        }
                      },
                      child: Tooltip(
                        message: step.title,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive ? _IT.brandSurface : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: stepColor,
                              width: isActive ? 2.5 : 1.5,
                            ),
                          ),
                          child: Center(
                            child: isCompleted
                                ? const Icon(Icons.check_rounded, color: _IT.success, size: 16)
                                : Text(
                                    '${idx + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                      color: isActive ? _IT.brand : _IT.textMid,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      // Text Title
                      Flexible(
                        child: Text(
                          step.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive ? _IT.textDark : _IT.textMid,
                          ),
                        ),
                      ),
                    ],
                    // Connector line to the next step
                    if (idx < cfg.steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: isCompleted ? _IT.success : _IT.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
