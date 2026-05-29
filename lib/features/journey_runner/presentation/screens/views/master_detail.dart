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

/// A master-detail layout for journey steps.
/// On wide screens (>= 800px): left sidebar with step list, right panel with active form.
/// On narrow screens: falls back to a full-width carousel (similar to original).
class MasterDetailRunnerView extends StatelessWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final void Function(int) onStepTap;

  const MasterDetailRunnerView({
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
    final isWide = MediaQuery.of(context).size.width >= 800;

    if (!isWide) {
      // On narrow screens, use the original carousel layout
      return _buildMobileCarousel(context);
    }

    // Desktop master-detail layout
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MASTER: Step list sidebar
                _buildMasterSidebar(),
                const SizedBox(width: 24),
                // DETAIL: Active step form
                Expanded(
                  flex: 2,
                  child: _buildDetailPanel(context),
                ),
              ],
            ),
          ),
        ),
        bottomBarBuilder(),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // Mobile fallback (similar to original carousel but without chevrons)
  // ----------------------------------------------------------------------
  Widget _buildMobileCarousel(BuildContext context) {
    final total = cfg.steps.length;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  children: [
                    // Horizontal stepper (compact)
                    _buildCompactStepper(total),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _IT.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: _IT.border),
                          boxShadow: [
                            BoxShadow(
                              color: _IT.brand.withValues(alpha: 0.08),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: formContentBuilder(context, isMobile: true),
                        ),
                      ),
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

  Widget _buildCompactStepper(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == activeIdx;
        final isCompleted = index < activeIdx;
        return GestureDetector(
          onTap: () => onStepTap(index),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive || isCompleted ? _IT.brand : Colors.transparent,
                    border: Border.all(
                      color: isActive || isCompleted ? _IT.brand : _IT.border,
                      width: 2,
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
                            ),
                          ),
                  ),
                ),
                if (index < total - 1)
                  Container(
                    width: 24,
                    height: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isCompleted ? _IT.brand : _IT.border,
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ----------------------------------------------------------------------
  // Desktop master sidebar
  // ----------------------------------------------------------------------
  Widget _buildMasterSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _IT.border),
        boxShadow: [
          BoxShadow(
            color: _IT.brand.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Journey steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _IT.textDark,
              ),
            ),
          ),
          const Divider(height: 0, thickness: 1, color: _IT.border),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cfg.steps.length,
              separatorBuilder: (_, __) => const Divider(height: 0, indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final step = cfg.steps[index];
                final isActive = index == activeIdx;
                final isCompleted = index < activeIdx;
                return _buildStepTile(step, index, isActive, isCompleted);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(JourneyStep step, int index, bool isActive, bool isCompleted) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onStepTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? _IT.brandSurface : Colors.transparent,
            border: isActive ? Border(left: BorderSide(color: _IT.brand, width: 3)) : null,
          ),
          child: Row(
            children: [
              // Status icon / number
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
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // Step title and optional description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? _IT.brand : _IT.textDark,
                      ),
                    ),
                    if (step.description != null)
                      Text(
                        step.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _IT.textMid,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Optional: chevron for active step
              if (isActive)
                Icon(Icons.chevron_right_rounded, size: 20, color: _IT.brand),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // Detail panel (active step form)
  // ----------------------------------------------------------------------
  Widget _buildDetailPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _IT.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _IT.border),
        boxShadow: [
          BoxShadow(
            color: _IT.brand.withValues(alpha: 0.08),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with step title & description
          if (activeStep.title != null)
            Text(
              activeStep.title!,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
              ),
            ),
          if (activeStep.description != null) ...[
            const SizedBox(height: 8),
            Text(
              activeStep.description!,
              style: TextStyle(fontSize: 14, color: _IT.textMid),
            ),
          ],
          const SizedBox(height: 24),
          // Form content (scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: formContentBuilder(context, isMobile: false),
            ),
          ),
        ],
      ),
    );
  }
}