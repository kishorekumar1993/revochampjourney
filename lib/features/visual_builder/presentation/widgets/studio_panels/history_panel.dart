import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';
import '../../../application/visual_builder_commands.dart';
import 'studio_panel_wrapper.dart';

class RevoCommandHistoryPanel extends ConsumerWidget {
  const RevoCommandHistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final past = ref.watch(visualBuilderProvider.select((s) => s.past));
    final future = ref.watch(visualBuilderProvider.select((s) => s.future));
    final controller = ref.read(visualBuilderProvider.notifier);

    final totalEdits = past.length + future.length;

    return RevoStudioPanelWrapper(
      title: "Command History",
      subtitle: "Review and jump between layout checkpoints",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Undo / Redo buttons
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: past.isNotEmpty ? () => controller.undo() : null,
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: Text("Undo (${past.length})", style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                        color: past.isNotEmpty ? RevoTheme.primaryLight.withValues(alpha: 0.5) : RevoTheme.cardBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: future.isNotEmpty ? () => controller.redo() : null,
                    icon: const Icon(Icons.redo_rounded, size: 14),
                    label: Text("Redo (${future.length})", style: const TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                        color: future.isNotEmpty ? RevoTheme.primaryLight.withValues(alpha: 0.5) : RevoTheme.cardBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Audit log header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "OPERATION TIMELINE",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: RevoTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  "$totalEdits edit${totalEdits == 1 ? '' : 's'}",
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: RevoTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Timeline list
          Expanded(
            child: totalEdits == 0 && past.isEmpty
                ? _buildEmptyState()
                : _buildTimelineList(context, controller, past, future),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 40,
            color: RevoTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            "No changes recorded yet\nModify canvas to log history.",
            style: GoogleFonts.inter(
              fontSize: 11,
              color: RevoTheme.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    VisualBuilderController controller,
    List<VisualBuilderCommand> past,
    List<VisualBuilderCommand> future,
  ) {
    // We assemble the items in reverse chronological order (newest future at the top, initial state at the bottom)
    final futureCount = future.length;
    final pastCount = past.length;

    // Total elements: future items + past items + initial state
    final totalCount = futureCount + pastCount + 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // index = 0 -> future.last (newest redoable)
        // index = futureCount - 1 -> future.first (next redoable)
        // index = futureCount -> past.last (current active state)
        // index = futureCount + pastCount - 1 -> past.first (oldest executed command)
        // index = futureCount + pastCount -> Initial State

        final bool isFuture = index < futureCount;
        final bool isCurrent = index == futureCount;
        final bool isPast = index > futureCount && index < totalCount - 1;
        final bool isInitial = index == totalCount - 1;

        // Obtain details of target command or initial state
        String title;
        String subtitle;
        IconData icon;

        if (isFuture) {
          final cmdIndex = (futureCount - 1) - index;
          final cmd = future[cmdIndex];
          title = cmd.description;
          subtitle = "Redoable action";
          icon = _getIconForCommand(cmd);
        } else if (isCurrent) {
          if (past.isEmpty) {
            title = "Initial Scaffold";
            subtitle = "Active layout container";
            icon = Icons.rocket_launch_rounded;
          } else {
            final cmd = past.last;
            title = cmd.description;
            subtitle = "Active checkpoint";
            icon = _getIconForCommand(cmd);
          }
        } else if (isPast) {
          final cmdIndex = (pastCount - 1) - (index - futureCount);
          final cmd = past[cmdIndex];
          title = cmd.description;
          subtitle = "Undone checkpoint available";
          icon = _getIconForCommand(cmd);
        } else {
          // Initial state
          title = "Initial Scaffold";
          subtitle = "Step canvas started";
          icon = Icons.rocket_launch_rounded;
        }

        // Setup tap callback to jump states
        VoidCallback? onTap;
        if (isFuture) {
          // If clicked a future item, we need to redo `(futureCount - 1 - index) + 1` times
          final redoSteps = (futureCount - 1) - index + 1;
          onTap = () {
            for (var i = 0; i < redoSteps; i++) {
              controller.redo();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Redone $redoSteps action(s)"),
                duration: const Duration(milliseconds: 500),
                backgroundColor: RevoTheme.success,
              ),
            );
          };
        } else if (isCurrent) {
          onTap = null; // Already at this state!
        } else if (isPast) {
          // If clicked a past item, we need to undo from past.last down to that index
          // past index of clicked item is: `pastCount - 1 - (index - futureCount)`
          final clickedPastIdx = (pastCount - 1) - (index - futureCount);
          final undoSteps = (pastCount - 1) - clickedPastIdx;
          onTap = () {
            for (var i = 0; i < undoSteps; i++) {
              controller.undo();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Undone $undoSteps action(s)"),
                duration: const Duration(milliseconds: 500),
                backgroundColor: RevoTheme.warning,
              ),
            );
          };
        } else if (isInitial) {
          // Jump to initial state by undoing all past commands
          onTap = past.isNotEmpty
              ? () {
                  final undoSteps = past.length;
                  for (var i = 0; i < undoSteps; i++) {
                    controller.undo();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Restored initial layout step"),
                      duration: const Duration(milliseconds: 500),
                      backgroundColor: RevoTheme.warning,
                    ),
                  );
                }
              : null;
        }

        // Timeline drawing parameters
        final isFirst = index == 0;
        final isLast = index == totalCount - 1;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Line and Dot Column
                SizedBox(
                  width: 32,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Vertical connector line
                      Positioned(
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1.5,
                          color: isFuture
                              ? Colors.grey.withValues(alpha: 0.2)
                              : (isCurrent ? RevoTheme.primary.withValues(alpha: 0.3) : RevoTheme.primaryLight.withValues(alpha: 0.3)),
                        ),
                      ),
                      // Top spacer to hide line for the first item
                      if (isFirst)
                        Positioned(
                          top: 0,
                          height: 12,
                          child: Container(width: 4, color: RevoTheme.sidebarBackground),
                        ),
                      // Bottom spacer to hide line for the last item
                      if (isLast)
                        Positioned(
                          top: 12,
                          bottom: 0,
                          child: Container(width: 4, color: RevoTheme.sidebarBackground),
                        ),
                      // Circular indicator badge
                      Positioned(
                        top: 2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFuture
                                ? Colors.grey.withValues(alpha: 0.1)
                                : (isCurrent
                                    ? RevoTheme.primary
                                    : RevoTheme.primaryLight.withValues(alpha: 0.15)),
                            border: Border.all(
                              color: isCurrent
                                  ? Colors.white
                                  : (isFuture ? Colors.grey : RevoTheme.primaryLight),
                              width: isCurrent ? 1.5 : 1,
                            ),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: RevoTheme.primary.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 11,
                              color: isCurrent
                                  ? Colors.white
                                  : (isFuture ? Colors.grey : RevoTheme.primaryLight),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Content Panel Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? RevoTheme.primary.withValues(alpha: 0.08)
                          : (isFuture ? Colors.transparent : RevoTheme.cardBg.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent
                            ? RevoTheme.primary.withValues(alpha: 0.5)
                            : (isFuture ? Colors.transparent : RevoTheme.cardBorder.withValues(alpha: 0.3)),
                        width: isCurrent ? 1.2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isFuture
                                ? RevoTheme.textSecondary.withValues(alpha: 0.5)
                                : RevoTheme.textPrimary,
                            decoration: isFuture ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: isFuture
                                    ? RevoTheme.textSecondary.withValues(alpha: 0.3)
                                    : RevoTheme.textSecondary,
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: RevoTheme.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "ACTIVE",
                                  style: GoogleFonts.inter(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForCommand(VisualBuilderCommand cmd) {
    if (cmd is AddWidgetCommand) {
      return Icons.add_circle_outline_rounded;
    } else if (cmd is DeleteWidgetCommand) {
      return Icons.delete_outline_rounded;
    } else if (cmd is MoveWidgetCommand) {
      return Icons.open_with_rounded;
    } else if (cmd is UpdatePropertyCommand) {
      return Icons.edit_note_rounded;
    } else if (cmd is UpdateActionsCommand) {
      return Icons.bolt_rounded;
    } else if (cmd is ImportLayoutCommand) {
      return Icons.file_download_outlined;
    }
    return Icons.history_rounded;
  }
}
