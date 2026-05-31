import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../journey_builder/domain/entities/journey_models.dart';
import '../../../domain/journey_execution_models.dart';
import 'runner_theme.dart';

Future<bool?> showOfferResumeDialog(
  BuildContext context,
  JourneyConfig cfg,
  JourneyDraft draft,
) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: RunnerTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Resume Journey?',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: RunnerTheme.textDark,
        ),
      ),
      content: Text(
        'A saved draft was found for "${cfg.journeyName}" (step: ${draft.currentStepId}).',
        style: GoogleFonts.poppins(fontSize: 13, color: RunnerTheme.textMid),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            'Start Fresh',
            style: GoogleFonts.poppins(color: RunnerTheme.textMid),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RunnerTheme.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Resume', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}

Future<void> showCompletionDialog(
  BuildContext context, {
  required VoidCallback onBackToDashboard,
}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: RunnerTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RunnerTheme.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: RunnerTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Journey Completed!',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: RunnerTheme.textDark,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: Text(
        'All steps have been completed and validated successfully.',
        style: GoogleFonts.poppins(fontSize: 13, color: RunnerTheme.textMid),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: RunnerTheme.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            onBackToDashboard();
          },
          child: Text(
            'Back to Dashboard',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
