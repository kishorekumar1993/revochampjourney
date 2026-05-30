import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_state.dart';

class RunnerHeader extends StatelessWidget {
  final JourneyConfig cfg;
  final RunnerLayoutStyle layoutStyle;
  final ValueChanged<RunnerLayoutStyle> onStyleChanged;
  final VoidCallback onBackPressed;
  final VoidCallback onClosePressed;

  const RunnerHeader({
    super.key,
    required this.cfg,
    required this.layoutStyle,
    required this.onStyleChanged,
    required this.onBackPressed,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: RunnerTheme.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _iconBtn(Icons.arrow_back_rounded, onBackPressed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cfg.journeyName,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: RunnerTheme.textDark,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _buildStyleSwitcher(),
          const SizedBox(width: 12),
          _iconBtn(
            Icons.close_rounded,
            onClosePressed,
            color: RunnerTheme.textMid,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSwitcher() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: RunnerTheme.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _styleIconBtn(RunnerLayoutStyle.split, Icons.splitscreen_rounded, 'Split View'),
            _styleIconBtn(RunnerLayoutStyle.focus, Icons.center_focus_strong_rounded, 'Focus View'),
            _styleIconBtn(RunnerLayoutStyle.timeline, Icons.route_rounded, 'Timeline View'),
            _styleIconBtn(RunnerLayoutStyle.tabbed, Icons.view_sidebar_rounded, 'Tabbed View'),
            _styleIconBtn(RunnerLayoutStyle.curasole, Icons.view_carousel_rounded, 'Carousel View'),
            _styleIconBtn(RunnerLayoutStyle.masterdetail, Icons.dashboard_customize_rounded, 'Master-Detail View'),
            _styleIconBtn(RunnerLayoutStyle.accordion, Icons.view_agenda_rounded, 'Accordion View'),
            _styleIconBtn(RunnerLayoutStyle.wizard, Icons.wb_auto_rounded, 'Wizard View'),
            _styleIconBtn(RunnerLayoutStyle.review, Icons.rate_review_rounded, 'Review View'),
            _styleIconBtn(RunnerLayoutStyle.dashboard, Icons.space_dashboard_rounded, 'Dashboard View'),
            _styleIconBtn(RunnerLayoutStyle.chat, Icons.chat_rounded, 'Chat View'),
            _styleIconBtn(RunnerLayoutStyle.kanban, Icons.view_week_rounded, 'Kanban View'),
            _styleIconBtn(RunnerLayoutStyle.stepper, Icons.linear_scale_rounded, 'Stepper View'),
            _styleIconBtn(RunnerLayoutStyle.form, Icons.mobile_friendly_rounded, 'Mobile Form View'),
          ],
        ),
      ),
    );
  }

  Widget _styleIconBtn(RunnerLayoutStyle style, IconData icon, String tooltip) {
    final active = layoutStyle == style;
    return Tooltip(
      message: tooltip,
      textStyle: GoogleFonts.poppins(fontSize: 11, color: Colors.white),
      decoration: BoxDecoration(
        color: RunnerTheme.textDark,
        borderRadius: BorderRadius.circular(6),
      ),
      child: GestureDetector(
        onTap: () => onStyleChanged(style),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? RunnerTheme.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: active ? Colors.white : RunnerTheme.textMid,
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(
    IconData icon,
    VoidCallback onTap, {
    Color color = RunnerTheme.textDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: RunnerTheme.bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
