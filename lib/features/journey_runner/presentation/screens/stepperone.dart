
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
}// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import '../../../../core/theme.dart';
// import '../../../journey_builder/domain/entities/journey_models.dart';

// /// Modern, interactive timeline stepper for journey runner.
// /// Features:
// /// - Smooth enter/exit animations
// /// - Status icons (pending, active, completed)
// /// - Tooltips with step details
// /// - Click navigation to completed steps
// /// - Dynamic step labels with optional icons
// /// - Floating progress indicator
// /// - Responsive (collapses labels on narrow screens)
// /// Clean, professional timeline stepper for journey runner.
// /// No glassmorphism, no intense glows – just proper colors and smooth animations.
// class JourneyTimeline extends StatefulWidget {
//   final List<JourneyStep> steps;
//   final int activeIndex;
//   final Function(int index)? onStepTap;

//   const JourneyTimeline({
//     super.key,
//     required this.steps,
//     required this.activeIndex,
//     this.onStepTap,
//   });

//   @override
//   State<JourneyTimeline> createState() => _JourneyTimelineState();
// }

// class _JourneyTimelineState extends State<JourneyTimeline>
//     with SingleTickerProviderStateMixin {
//   final ScrollController _scrollController = ScrollController();
//   final Map<int, GlobalKey> _stepKeys = {};

//   @override
//   void initState() {
//     super.initState();
//     for (int i = 0; i < widget.steps.length; i++) {
//       _stepKeys[i] = GlobalKey();
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   void didUpdateWidget(covariant JourneyTimeline oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (oldWidget.activeIndex != widget.activeIndex) {
//       _scrollToActiveStep();
//     }
//   }

//   void _scrollToActiveStep() {
//     final key = _stepKeys[widget.activeIndex];
//     if (key?.currentContext != null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         Scrollable.ensureVisible(
//           key!.currentContext!,
//           duration: const Duration(milliseconds: 400),
//           curve: Curves.easeOutCubic,
//           alignment: 0.5,
//         );
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final screenWidth = MediaQuery.of(context).size.width;
//     final bool showLabels = screenWidth > 640;
//     final double progress = (widget.activeIndex + 1) / widget.steps.length;

//     return Container(
//       color: RevoTheme.sidebarBackground,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Progress bar with counter
//           Padding(
//             padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(4),
//                     child: LinearProgressIndicator(
//                       value: progress,
//                       backgroundColor: RevoTheme.cardBorder.withValues(alpha: 0.5),
//                       color: RevoTheme.secondary,
//                       minHeight: 4,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: RevoTheme.primary.withValues(alpha: 0.1),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: Text(
//                     '${widget.activeIndex + 1}/${widget.steps.length}',
//                     style: GoogleFonts.inter(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w500,
//                       color: RevoTheme.primary,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Scrollable steps
//           SingleChildScrollView(
//             controller: _scrollController,
//             scrollDirection: Axis.horizontal,
//             physics: const BouncingScrollPhysics(),
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             child: Row(
//               children: List.generate(widget.steps.length, (index) {
//                 final step = widget.steps[index];
//                 final isCompleted = index < widget.activeIndex;
//                 final isActive = index == widget.activeIndex;
//                 final status = isCompleted
//                     ? _StepStatus.completed
//                     : isActive
//                         ? _StepStatus.active
//                         : _StepStatus.pending;

//                 return Row(
//                   key: _stepKeys[index],
//                   children: [
//                     _StepTile(
//                       step: step,
//                       index: index,
//                       status: status,
//                       showLabel: showLabels,
//                       isClickable: isCompleted || isActive,
//                       onTap: widget.onStepTap != null && (isCompleted || isActive)
//                           ? () => widget.onStepTap!(index)
//                           : null,
//                     ),
//                     if (index < widget.steps.length - 1)
//                       _ConnectorLine(
//                         isCompleted: isCompleted,
//                       ),
//                   ],
//                 );
//               }),
//             ),
//           ),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }
// }

// enum _StepStatus { pending, active, completed }

// class _StepTile extends StatelessWidget {
//   final JourneyStep step;
//   final int index;
//   final _StepStatus status;
//   final bool showLabel;
//   final bool isClickable;
//   final VoidCallback? onTap;

//   const _StepTile({
//     required this.step,
//     required this.index,
//     required this.status,
//     required this.showLabel,
//     required this.isClickable,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final colors = _getColors();
//     final icon = _getIcon();

//     return MouseRegion(
//       cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
//       child: GestureDetector(
//         onTap: isClickable ? onTap : null,
//         child: Tooltip(
//           message: step.description,
//           preferBelow: false,
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             curve: Curves.easeInOut,
//             height: 44,
//             decoration: BoxDecoration(
//               color: _getBackgroundColor(),
//               borderRadius: BorderRadius.circular(40),
//               border: Border.all(
//                 color: colors.$3,
//                 width: status == _StepStatus.active ? 2 : 1,
//               ),
//               boxShadow: status == _StepStatus.active
//                   ? [
//                       BoxShadow(
//                         color: RevoTheme.primary.withValues(alpha: 0.15),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Status indicator
//                   Container(
//                     width: 26,
//                     height: 26,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: status == _StepStatus.completed
//                           ? RevoTheme.secondary
//                           : status == _StepStatus.active
//                               ? RevoTheme.primary
//                               : Colors.transparent,
//                       border: status == _StepStatus.pending
//                           ? Border.all(color: RevoTheme.textSecondary, width: 1.5)
//                           : null,
//                     ),
//                     child: Center(
//                       child: status == _StepStatus.completed
//                           ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
//                           : status == _StepStatus.active
//                               ? Text(
//                                   '${index + 1}',
//                                   style: GoogleFonts.inter(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.white,
//                                   ),
//                                 )
//                               : Text(
//                                   '${index + 1}',
//                                   style: GoogleFonts.inter(
//                                     fontSize: 12,
//                                     fontWeight: FontWeight.w500,
//                                     color: RevoTheme.textSecondary,
//                                   ),
//                                 ),
//                     ),
//                   ),
//                   if (showLabel) ...[
//                     const SizedBox(width: 10),
//                     Flexible(
//                       child: Text(
//                         step.title,
//                         style: GoogleFonts.inter(
//                           fontSize: 13,
//                           fontWeight: status == _StepStatus.active
//                               ? FontWeight.w600
//                               : FontWeight.w500,
//                           color: colors.$1,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getBackgroundColor() {
//     switch (status) {
//       case _StepStatus.active:
//         return RevoTheme.primary.withValues(alpha: 0.08);
//       case _StepStatus.completed:
//         return RevoTheme.secondary.withValues(alpha: 0.08);
//       case _StepStatus.pending:
//         return RevoTheme.cardBg;
//     }
//   }

//   (Color primary, Color border, Color text) _getColors() {
//     switch (status) {
//       case _StepStatus.completed:
//         return (RevoTheme.secondary, RevoTheme.secondary, RevoTheme.textPrimary);
//       case _StepStatus.active:
//         return (RevoTheme.primary, RevoTheme.primary, RevoTheme.textPrimary);
//       case _StepStatus.pending:
//         return (RevoTheme.textSecondary, RevoTheme.cardBorder, RevoTheme.textSecondary);
//     }
//   }

//   IconData _getIcon() {
//     switch (status) {
//       case _StepStatus.completed:
//         return Icons.check_circle_rounded;
//       case _StepStatus.active:
//         return Icons.play_circle_filled_rounded;
//       case _StepStatus.pending:
//         return Icons.circle_outlined;
//     }
//   }
// }

// class _ConnectorLine extends StatelessWidget {
//   final bool isCompleted;

//   const _ConnectorLine({required this.isCompleted});

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       width: 32,
//       height: 2,
//       margin: const EdgeInsets.symmetric(horizontal: 4),
//       decoration: BoxDecoration(
//         color: isCompleted ? RevoTheme.secondary : RevoTheme.cardBorder,
//         borderRadius: BorderRadius.circular(2),
//       ),
//     );
//   }
// }
