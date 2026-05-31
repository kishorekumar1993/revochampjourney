import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../journey_builder/data/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS  (matches the reference image)
// ─────────────────────────────────────────────────────────────────────────────
class _T {
  static const brand      = Color(0xFF5B4FCF);
  static const success    = Color(0xFF4CAF50);
  static const white      = Color(0xFFFFFFFF);
  static const textDark   = Color(0xFF1A1A2E);
  static const textLight  = Color(0xFFB0B4C8);
  static const border     = Color(0xFFE4E6F0);
  static const activeBg   = Color(0xFFEEECFD);
  static const chip       = Color(0xFFF5F5FF);
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP ICON MAP  – give every well-known step a contextual icon
// ─────────────────────────────────────────────────────────────────────────────
IconData _stepIcon(String title) {
  final t = title.toLowerCase();
  if (t.contains('personal'))  return Icons.person_outline_rounded;
  if (t.contains('vehicle'))   return Icons.directions_car_outlined;
  if (t.contains('nominee'))   return Icons.supervisor_account_outlined;
  if (t.contains('document'))  return Icons.upload_file_outlined;
  if (t.contains('review') || t.contains('confirm')) return Icons.fact_check_outlined;
  if (t.contains('payment'))   return Icons.credit_card_outlined;
  if (t.contains('success') || t.contains('done')) return Icons.verified_outlined;
  if (t.contains('address'))   return Icons.location_on_outlined;
  if (t.contains('policy'))    return Icons.policy_outlined;
  if (t.contains('quote'))     return Icons.request_quote_outlined;
  return Icons.radio_button_unchecked_rounded;
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class JourneyTimeline extends StatefulWidget {
  final List<JourneyStep> steps;
  final int activeIndex;
  final Function(int index)? onStepTap;

  const JourneyTimeline({
    super.key,
    required this.steps,
    required this.activeIndex,
    this.onStepTap,
  });

  @override
  State<JourneyTimeline> createState() => _JourneyTimelineState();
}

class _JourneyTimelineState extends State<JourneyTimeline> {
  final _scrollController = ScrollController();
  final Map<int, GlobalKey> _keys = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.steps.length; i++) {
      _keys[i] = GlobalKey();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant JourneyTimeline old) {
    super.didUpdateWidget(old);
    if (old.activeIndex != widget.activeIndex) _scrollToActive();
  }

  void _scrollToActive() {
    final key = _keys[widget.activeIndex];
    if (key?.currentContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final total    = widget.steps.length;
    final active   = widget.activeIndex;
    final progress = (active + 1) / total;

    return Container(
      color: _T.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── thin top progress bar ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            height: 3,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _T.border,
              valueColor: const AlwaysStoppedAnimation<Color>(_T.brand),
              minHeight: 3,
            ),
          ),

          // ── step counter badge (top-right) ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _T.activeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${active + 1}/$total',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _T.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── scrollable step row ──────────────────────────────────────────
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(total, (i) {
                final isCompleted = i < active;
                final isActive    = i == active;
                return Row(
                  key: _keys[i],
                  children: [
                    _StepChip(
                      step:        widget.steps[i],
                      index:       i,
                      isActive:    isActive,
                      isCompleted: isCompleted,
                      onTap:       (isCompleted || isActive) && widget.onStepTap != null
                                     ? () => widget.onStepTap!(i)
                                     : null,
                    ),
                    if (i < total - 1)
                      _DottedConnector(filled: isCompleted),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP CHIP  (matches the pill style in the image)
// ─────────────────────────────────────────────────────────────────────────────
class _StepChip extends StatelessWidget {
  final JourneyStep step;
  final int         index;
  final bool        isActive;
  final bool        isCompleted;
  final VoidCallback? onTap;

  const _StepChip({
    required this.step,
    required this.index,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconBgColor;
    Color iconColor;

    if (isActive) {
      bgColor     = _T.activeBg;
      borderColor = _T.brand;
      textColor   = _T.brand;
      iconBgColor = _T.brand;
      iconColor   = _T.white;
    } else if (isCompleted) {
      bgColor     = _T.white;
      borderColor = _T.border;
      textColor   = _T.textDark;
      iconBgColor = _T.success.withValues(alpha: 0.12);
      iconColor   = _T.success;
    } else {
      bgColor     = _T.white;
      borderColor = _T.border;
      textColor   = _T.textLight;
      iconBgColor = _T.chip;
      iconColor   = _T.textLight;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: borderColor, width: isActive ? 1.5 : 1.0),
          boxShadow: isActive
              ? [BoxShadow(color: _T.brand.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // circle with number or check or icon
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check_rounded, size: 14, color: iconColor)
                    : isActive
                        ? Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          )
                        : Icon(_stepIcon(step.title), size: 14, color: iconColor),
              ),
            ),
            const SizedBox(width: 8),
            // Label
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                step.title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DOTTED CONNECTOR (matches the "· · · · ·" style in the image)
// ─────────────────────────────────────────────────────────────────────────────
class _DottedConnector extends StatelessWidget {
  final bool filled;
  const _DottedConnector({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) => _dot(i)),
      ),
    );
  }

  Widget _dot(int i) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? _T.brand.withValues(alpha: 0.4)
            : _T.border,
      ),
    );
  }
}
