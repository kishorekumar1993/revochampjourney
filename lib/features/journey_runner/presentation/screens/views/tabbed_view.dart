import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/data/models.dart';

class _IT {
  static const brand = Color(0xFF5B4FCF);
  static const brandSurface = Color(0xFFEEECFD);
  static const white = Color(0xFFFFFFFF);
  static const textDark = Color(0xFF1A1A2E);
  static const textMid = Color(0xFF6B7280);
  static const textLight = Color(0xFFB0B4C8);
  static const border = Color(0xFFE4E6F0);
  static const success = Color(0xFF22C55E);
  static const successSurface = Color(0xFFE8F9EE);
  static const leftPanelBg = Color(0xFFF7F5FF);
}

class TabbedRunnerView extends StatefulWidget {
  final JourneyConfig cfg;
  final JourneyStep activeStep;
  final int activeIdx;
  final Map<String, dynamic> formValues;
  final Widget Function(BuildContext, {bool isMobile}) formContentBuilder;
  final Widget Function() bottomBarBuilder;
  final void Function(int) onStepTap;

  const TabbedRunnerView({
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
  State<TabbedRunnerView> createState() => _TabbedRunnerViewState();
}

class _TabbedRunnerViewState extends State<TabbedRunnerView> {
  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 800;

    if (isMobile) {
      return Column(
        children: [
          // Horizontal step tabs on mobile
          _buildMobileStepBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: widget.formContentBuilder(context, isMobile: true),
            ),
          ),
          _buildMobileSummaryToggle(),
          widget.bottomBarBuilder(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT SIDEBAR - STEP TABS
                Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: _IT.leftPanelBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _IT.border),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'JOURNEY STEPS',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _IT.textMid,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.cfg.steps.length,
                          itemBuilder: (context, index) {
                            final step = widget.cfg.steps[index];
                            final isCompleted = index < widget.activeIdx;
                            final isActive = index == widget.activeIdx;
                            final isUpcoming = index > widget.activeIdx;

                            return _buildSidebarTab(step, index, isCompleted, isActive, isUpcoming);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // CENTER FORM CONTAINER
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _IT.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _IT.border),
                      boxShadow: [
                        BoxShadow(
                          color: _IT.brand.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: widget.formContentBuilder(context, isMobile: false),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // RIGHT SIDEBAR - LIVE DATA SUMMARY
                Container(
                  width: 240,
                  decoration: BoxDecoration(
                    color: _IT.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _IT.border),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _buildLiveSummaryCard(),
                ),
              ],
            ),
          ),
        ),
        widget.bottomBarBuilder(),
      ],
    );
  }

  Widget _buildSidebarTab(JourneyStep step, int index, bool isCompleted, bool isActive, bool isUpcoming) {
    final canTap = isCompleted || isActive;
    return InkWell(
      onTap: canTap ? () => widget.onStepTap(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _IT.brand : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Status Icon
            _getSidebarTabIcon(isCompleted, isActive, isUpcoming),
            const SizedBox(width: 10),
            // Step title
            Expanded(
              child: Text(
                step.title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? _IT.white
                      : isUpcoming
                          ? _IT.textLight
                          : _IT.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getSidebarTabIcon(bool isCompleted, bool isActive, bool isUpcoming) {
    if (isActive) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(color: _IT.white, shape: BoxShape.circle),
        child: const Center(
          child: SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(_IT.brand),
            ),
          ),
        ),
      );
    }
    if (isCompleted) {
      return const Icon(Icons.check_circle_rounded, size: 16, color: _IT.success);
    }
    return const Icon(Icons.lock_outline_rounded, size: 16, color: _IT.textLight);
  }

  Widget _buildMobileStepBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: _IT.white,
        border: Border(bottom: BorderSide(color: _IT.border)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.cfg.steps.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final step = widget.cfg.steps[index];
          final isCompleted = index < widget.activeIdx;
          final isActive = index == widget.activeIdx;
          final canTap = isCompleted || isActive;

          return GestureDetector(
            onTap: canTap ? () => widget.onStepTap(index) : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? _IT.brandSurface
                    : isCompleted
                        ? _IT.successSurface
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? _IT.brand
                      : isCompleted
                          ? _IT.success.withValues(alpha: 0.3)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  if (isCompleted)
                    const Icon(Icons.check_rounded, size: 12, color: _IT.success)
                  else
                    Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive ? _IT.brand : _IT.textLight,
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    step.title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive
                          ? _IT.brand
                          : isCompleted
                              ? _IT.textDark
                              : _IT.textLight,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileSummaryToggle() {
    return Container(
      color: _IT.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: _IT.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            builder: (context) => Container(
              padding: const EdgeInsets.all(20),
              child: _buildLiveSummaryCard(),
            ),
          );
        },
        icon: const Icon(Icons.analytics_outlined, size: 16, color: _IT.brand),
        label: Text(
          'View Real-time Summary',
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _IT.brand),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _IT.brand),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size.fromHeight(40),
        ),
      ),
    );
  }

  Widget _buildLiveSummaryCard() {
    final summariesByStep = <String, Map<String, String>>{};

    for (final step in widget.cfg.steps) {
      final stepAnswers = <String, String>{};
      for (final field in step.flattenedFields) {
        if (field.type == 'divider' || field.type == 'section' || field.type == 'card' || field.type == 'row' || field.type == 'column') {
          continue;
        }
        final val = widget.formValues[field.id];
        if (val != null && val.toString().trim().isNotEmpty) {
          stepAnswers[field.label] = val.toString();
        }
      }
      if (stepAnswers.isNotEmpty) {
        summariesByStep[step.title] = stepAnswers;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.analytics_outlined, color: _IT.brand, size: 18),
            const SizedBox(width: 8),
            Text(
              'Real-time Summary',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _IT.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(color: _IT.border, height: 1),
        const SizedBox(height: 12),
        Expanded(
          child: summariesByStep.isEmpty
              ? Center(
                  child: Text(
                    'No data entered yet.\nSummary will update live!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _IT.textLight,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: summariesByStep.length,
                  itemBuilder: (context, index) {
                    final stepTitle = summariesByStep.keys.elementAt(index);
                    final answers = summariesByStep[stepTitle]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepTitle.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _IT.brand,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...answers.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '${e.key}:',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: _IT.textMid,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      e.value,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _IT.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 8),
                          const Divider(color: _IT.border, height: 1),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
