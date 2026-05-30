import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/core/theme.dart';
import 'package:revojourneytryone/features/journey_builder/data/models.dart';
import 'package:revojourneytryone/features/journey_builder/presentation/providers/journey_provider.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_history_manager.dart';

class StepsHistoryTab extends ConsumerWidget {
  final JourneyConfig config;

  const StepsHistoryTab({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(historyProvider);
    final past = historyState.past;
    final future = historyState.future;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Change & State History",
            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            "Undo, redo, and review past builder sessions state trails.",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 16),

          // Undo/Redo Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: past.isEmpty
                      ? null
                      : () {
                          ref.read(historyProvider.notifier).undo();
                          // Reset active step to avoid dangling reference
                          final restoredConfig = ref.read(journeyConfigProvider);
                          final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                          ref.read(activeStepIdProvider.notifier).state = firstStepId;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Undone last change!"), duration: Duration(milliseconds: 600)),
                          );
                        },
                  icon: const Icon(Icons.undo_rounded, size: 14),
                  label: Text("Undo (${past.length})", style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: past.isEmpty ? RevoTheme.cardBorder : RevoTheme.primaryLight),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: future.isEmpty
                      ? null
                      : () {
                          ref.read(historyProvider.notifier).redo();
                          // Reset active step to avoid dangling reference
                          final restoredConfig = ref.read(journeyConfigProvider);
                          final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                          ref.read(activeStepIdProvider.notifier).state = firstStepId;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Redone change!"), duration: Duration(milliseconds: 600)),
                          );
                        },
                  icon: const Icon(Icons.redo_rounded, size: 14),
                  label: Text("Redo (${future.length})", style: const TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: future.isEmpty ? RevoTheme.cardBorder : RevoTheme.primaryLight),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Text(
            "Version Audit Timeline",
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textSecondary),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: past.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 36, color: RevoTheme.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          "No past edits recorded yet.\nMake changes to log history checkpoints.",
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: past.length + 1,
                    itemBuilder: (context, index) {
                      final isCurrent = index == past.length;
                      final snap = isCurrent ? historyState.present : past[index];
                      final stepsCount = snap.steps.length;
                      final fieldsCount = snap.steps.fold<int>(0, (sum, s) => sum + s.fields.length);
                      
                      return InkWell(
                        onTap: isCurrent
                            ? null
                            : () {
                                ref.read(historyProvider.notifier).rollbackTo(index);
                                // Reset active step to avoid dangling reference
                                final restoredConfig = ref.read(journeyConfigProvider);
                                final firstStepId = restoredConfig.steps.isNotEmpty ? restoredConfig.steps.first.id : '';
                                ref.read(activeStepIdProvider.notifier).state = firstStepId;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Restored state #${index + 1}!"), backgroundColor: RevoTheme.success),
                                );
                              },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent ? RevoTheme.primary.withValues(alpha: 0.1) : RevoTheme.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? RevoTheme.primary : RevoTheme.cardBorder,
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCurrent ? Icons.circle : Icons.history_rounded,
                                color: isCurrent ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isCurrent ? "Current Version (Active)" : "State Checkpoint #${index + 1}",
                                      style: TextStyle(fontFamily: 'Inter', 
                                        fontSize: 11,
                                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                        color: isCurrent ? RevoTheme.textPrimary : RevoTheme.textPrimary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "$stepsCount steps, $fieldsCount fields configured.",
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrent) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.restore_rounded, size: 14, color: RevoTheme.primaryLight),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
