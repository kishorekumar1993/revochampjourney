import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../core/theme.dart';
import '../../../../../../../core/component_engine/models/component_action.dart';
import '../../../../../application/visual_builder_controller.dart';

class StepTile extends StatelessWidget {
  final ActionStep step;
  final int index;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const StepTile({
    super.key,
    required this.step,
    required this.index,
    required this.nodeId,
    required this.action,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x0C5B4FCF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0x335B4FCF)),
      ),
      child: Row(
        children: [
          Icon(
            step.enabled ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
            size: 14,
            color: step.enabled ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${index + 1}. ${step.type.toUpperCase()}",
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_getStepDetails(step).isNotEmpty)
                  Text(
                    _getStepDetails(step),
                    style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 13, color: Colors.blueAccent),
            tooltip: "Configure step",
            onPressed: () => _showStepConfigDialog(context),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 13, color: Colors.redAccent),
            tooltip: "Remove step",
            onPressed: () {
              final list = List<ActionStep>.from(action.steps)..removeAt(index);
              controller.updateNodeActions(nodeId, [action.copyWith(steps: list)]);
            },
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  String _getStepDetails(ActionStep s) {
    if (s.type == 'api') return "Call: ${s.properties['url'] ?? '/api'}";
    if (s.type == 'navigate') return "Go to: ${s.properties['pageId'] ?? 'Screen'}";
    if (s.type == 'snackbar' || s.type == 'alert') return "Show: ${s.properties['message'] ?? 'Msg'}";
    if (s.type == 'delay') return "Wait ${s.properties['duration'] ?? 1000} ms";
    return "";
  }

  void _showStepConfigDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: step.properties['title'] ?? step.properties['url'] ?? step.properties['pageId'] ?? '');
    final msgCtrl = TextEditingController(text: step.properties['message'] ?? '');
    final durationCtrl = TextEditingController(text: step.properties['duration']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Text("Configure ${step.type.toUpperCase()}", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (step.type == 'api')
                _dialogField(titleCtrl, "API URL / Endpoint")
              else if (step.type == 'navigate')
                _dialogField(titleCtrl, "Target Screen Step ID")
              else if (step.type == 'snackbar' || step.type == 'alert') ...[
                _dialogField(titleCtrl, "Dialog Title"),
                const SizedBox(height: 8),
                _dialogField(msgCtrl, "Message Content"),
              ] else if (step.type == 'delay')
                _dialogField(durationCtrl, "Delay (ms)", isNumber: true)
              else
                Text("No extra config for this step type.",
                    style: TextStyle(color: RevoTheme.textSecondary, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
            onPressed: () {
              final props = Map<String, dynamic>.from(step.properties);
              if (step.type == 'api') {
                props['url'] = titleCtrl.text;
              } else if (step.type == 'navigate') {
                props['pageId'] = titleCtrl.text;
              } else if (step.type == 'snackbar' || step.type == 'alert') {
                props['title'] = titleCtrl.text;
                props['message'] = msgCtrl.text;
              } else if (step.type == 'delay') {
                props['duration'] = int.tryParse(durationCtrl.text) ?? 1000;
              }
              final updated = step.copyWith(properties: props);
              final newSteps = List<ActionStep>.from(action.steps);
              newSteps[index] = updated;
              controller.updateNodeActions(nodeId, [action.copyWith(steps: newSteps)]);
              Navigator.pop(ctx);
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
    );
  }
}
