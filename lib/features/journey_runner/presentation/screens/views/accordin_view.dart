import 'package:flutter/material.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const border = Color(0xFFE4E6F0);
}

/// An accordion layout for journey steps.
/// Only the active step is expanded, showing its form content.
/// Tapping any step header switches the active step (closing previous, opening new).
class AccordionRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final void Function(int) onStepTap;

  const AccordionRunnerView({
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: List.generate(cfg.steps.length, (index) {
                    final step = cfg.steps[index];
                    final isActive = index == activeIdx;
                    final isCompleted = index < activeIdx;
                    return _buildAccordionItem(
                      step: step,
                      index: index,
                      isActive: isActive,
                      isCompleted: isCompleted,
                      context: context,
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  Widget _buildAccordionItem({
    required JourneyStep step,
    required int index,
    required bool isActive,
    required bool isCompleted,
    BuildContext? context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _IT.brand : _IT.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isActive)
            BoxShadow(
              color: _IT.border.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (always visible)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onStepTap(index),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? _IT.brand
                            : isCompleted
                                ? _IT.brand
                                : Colors.transparent,
                        border: Border.all(
                          color: isActive || isCompleted ? _IT.brand : _IT.border,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check_rounded, size: 18, color: _IT.white)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? _IT.white : _IT.textMid,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? _IT.brand : _IT.textDark,
                            ),
                          ),
                          Text(
                            step.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: _IT.textMid,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Expand/collapse icon
                    Icon(
                      isActive ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      color: isActive ? _IT.brand : _IT.textMid,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded content (only if active)
          if (isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1, color: _IT.border),
                  const SizedBox(height: 16),
                  // Form content
                  formContentBuilder(context!, isMobile: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}