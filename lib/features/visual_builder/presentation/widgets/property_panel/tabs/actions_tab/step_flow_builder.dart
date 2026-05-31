import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../core/theme.dart';
import '../../../../../../../core/component_engine/models/component_action.dart';
import '../../../../../application/visual_builder_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Step Flow Builder (for the full action flow panel view)
// ─────────────────────────────────────────────────────────────────────────────

class StepFlowBuilder extends StatelessWidget {
  final List<ActionStep> steps;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const StepFlowBuilder({
    super.key,
    required this.steps,
    required this.nodeId,
    required this.action,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(steps.length, (i) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlowStepNode(
                step: steps[i],
                index: i,
                parentList: steps,
                nodeId: nodeId,
                action: action,
                controller: controller,
              ),
              const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
            ],
          );
        }),
        AddStepButton(nodeId: nodeId, action: action, controller: controller, targetList: steps),
      ],
    );
  }
}

class FlowStepNode extends StatelessWidget {
  final ActionStep step;
  final int index;
  final List<ActionStep> parentList;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const FlowStepNode({
    super.key,
    required this.step,
    required this.index,
    required this.parentList,
    required this.nodeId,
    required this.action,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCondition = step.type == 'condition';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF5B4FCF), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                step.enabled ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                size: 14,
                color: step.enabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.type.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 13, color: Colors.redAccent),
                onPressed: () {
                  final list = List<ActionStep>.from(parentList)..removeAt(index);
                  controller.updateNodeActions(nodeId, [action.copyWith(steps: list)]);
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        if (isCondition) ...[
          const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("YES", style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    StepFlowBuilder(steps: step.successSteps, nodeId: nodeId, action: action, controller: controller),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("NO", style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    StepFlowBuilder(steps: step.failureSteps, nodeId: nodeId, action: action, controller: controller),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class TriggerNode extends StatelessWidget {
  final String label;

  const TriggerNode({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF5B4FCF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B4FCF)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}

class AddStepButton extends StatelessWidget {
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;
  final List<ActionStep> targetList;

  const AddStepButton({
    super.key,
    required this.nodeId,
    required this.action,
    required this.controller,
    required this.targetList,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x0C5B4FCF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x335B4FCF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 10, color: Color(0xFF5B4FCF)),
            const SizedBox(width: 4),
            Text("Add Step", style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF))),
          ],
        ),
      ),
    );
  }

  void _showDialog(BuildContext context) {
    final options = [
      {'type': 'validate', 'label': 'Validate Form', 'icon': Icons.check_circle_outline},
      {'type': 'api', 'label': 'Execute API', 'icon': Icons.api},
      {'type': 'navigate', 'label': 'Navigate Page', 'icon': Icons.navigation},
      {'type': 'saveToken', 'label': 'Save Local Data', 'icon': Icons.save},
      {'type': 'updateVariable', 'label': 'State Variable', 'icon': Icons.data_object},
      {'type': 'condition', 'label': 'IF/ELSE Branch', 'icon': Icons.alt_route},
      {'type': 'loop', 'label': 'Loop Action', 'icon': Icons.loop},
      {'type': 'delay', 'label': 'Delay Timer', 'icon': Icons.timer},
      {'type': 'snackbar', 'label': 'Show Snackbar', 'icon': Icons.info},
      {'type': 'alert', 'label': 'Show Alert', 'icon': Icons.warning},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Text("Select Action Step Type", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13)),
        content: SizedBox(
          width: 320,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.2,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final opt = options[index];
              return InkWell(
                onTap: () {
                  final newStep = ActionStep(
                    id: 'step_${DateTime.now().millisecondsSinceEpoch}_$index',
                    type: opt['type'] as String,
                  );
                  targetList.add(newStep);
                  controller.updateNodeActions(nodeId, [action]);
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: RevoTheme.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(opt['icon'] as IconData, size: 14, color: const Color(0xFF5B4FCF)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(opt['label'] as String, style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
