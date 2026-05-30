import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../../journey_builder/application/controllers/journey_controller.dart';

import 'studio_panel_wrapper.dart';

// 1. Pages/Journey step switcher panel
class RevoPagesPanel extends ConsumerWidget {
  const RevoPagesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyConfig = ref.watch(journeyConfigProvider);
    final activeStepId = ref.watch(activeStepIdProvider);

    return RevoStudioPanelWrapper(
      title: "Pages & Journey",
      subtitle: "Configure journey screens and steps",
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: journeyConfig.steps.length,
        itemBuilder: (context, index) {
          final step = journeyConfig.steps[index];
          final isSelected = step.id == activeStepId;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Card(
              color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                ),
              ),
              child: ListTile(
                onTap: () {
                  ref.read(activeStepIdProvider.notifier).state = step.id;
                },
                leading: Icon(
                  Icons.phone_android_rounded,
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                  size: 20,
                ),
                title: Text(
                  step.title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: RevoTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  "Fields: ${step.fields.length}",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

