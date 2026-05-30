import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../core/component_engine/models/component_node.dart';
import '../../../../../../core/component_engine/models/component_action.dart';
import '../../../../application/visual_builder_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RevoActionsTab — Action flow pipeline editor for a selected component node.
// ─────────────────────────────────────────────────────────────────────────────

class RevoActionsTab extends StatelessWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const RevoActionsTab({
    super.key,
    required this.node,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final actions = node.actions;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Action Flow Pipeline",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        if (actions.isEmpty)
          _NoActionsPlaceholder(node: node, controller: controller)
        else
          ...actions.map((act) => _ActionCard(node: node, action: act, controller: controller)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RevoActionsFlowView — Full-screen action flow view (top-level panel toggle).
// ─────────────────────────────────────────────────────────────────────────────

class RevoActionsFlowView extends StatelessWidget {
  final ComponentNode? selectedNode;
  final VisualBuilderController controller;

  const RevoActionsFlowView({
    super.key,
    required this.selectedNode,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedNode == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "Select a component on the canvas to configure its Action Flow.",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (selectedNode!.actions.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            final action = ComponentAction(event: 'onTap', steps: []);
            controller.updateNodeActions(selectedNode!.id, [action]);
          },
          icon: const Icon(Icons.add, color: Colors.white, size: 14),
          label: const Text("Create Action Trigger (onTap)", style: TextStyle(color: Colors.white, fontSize: 11)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5B4FCF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );
    }

    final action = selectedNode!.actions.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _TriggerNode(label: "ON ${action.event.toUpperCase()}")),
          const Center(child: Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF))),
          _StepFlowBuilder(
            steps: action.steps,
            nodeId: selectedNode!.id,
            action: action,
            controller: controller,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NoActionsPlaceholder extends StatelessWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const _NoActionsPlaceholder({required this.node, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        children: [
          Text("No actions configured", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              final defaultAction = ComponentAction(
                event: 'onTap',
                steps: [ActionStep(id: 'step_${DateTime.now().millisecondsSinceEpoch}', type: 'validate')],
              );
              controller.updateNodeActions(node.id, [defaultAction]);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5B4FCF),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text("Add onTap Trigger", style: GoogleFonts.inter(fontSize: 11, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ComponentNode node;
  final ComponentAction action;
  final VisualBuilderController controller;

  const _ActionCard({required this.node, required this.action, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: RevoTheme.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: RevoTheme.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Trigger: ${action.event}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary)),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                  onPressed: () => controller.updateNodeActions(node.id, []),
                  tooltip: "Remove trigger",
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            ...List.generate(action.steps.length, (i) {
              final step = action.steps[i];
              return _StepTile(
                step: step,
                index: i,
                nodeId: node.id,
                action: action,
                controller: controller,
              );
            }),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
              tooltip: "Add action step",
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF5B4FCF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 12, color: Color(0xFF5B4FCF)),
                    const SizedBox(width: 4),
                    Text("Add Step", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B4FCF))),
                  ],
                ),
              ),
              onSelected: (val) {
                final list = List<ActionStep>.from(action.steps)
                  ..add(ActionStep(id: 'step_${DateTime.now().millisecondsSinceEpoch}', type: val));
                controller.updateNodeActions(node.id, [action.copyWith(steps: list)]);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'validate', child: Text("Validate Fields")),
                PopupMenuItem(value: 'api', child: Text("Call API service")),
                PopupMenuItem(value: 'navigate', child: Text("Navigate Screen")),
                PopupMenuItem(value: 'saveToken', child: Text("Save Data Token")),
                PopupMenuItem(value: 'updateVariable', child: Text("State Variable")),
                PopupMenuItem(value: 'condition', child: Text("IF/ELSE Branch")),
                PopupMenuItem(value: 'snackbar', child: Text("Show Snackbar")),
                PopupMenuItem(value: 'alert', child: Text("Show Alert")),
                PopupMenuItem(value: 'delay', child: Text("Delay Timer")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final ActionStep step;
  final int index;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const _StepTile({
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

// ─────────────────────────────────────────────────────────────────────────────
// Step Flow Builder (for the full action flow panel view)
// ─────────────────────────────────────────────────────────────────────────────

class _StepFlowBuilder extends StatelessWidget {
  final List<ActionStep> steps;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const _StepFlowBuilder({
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
              _FlowStepNode(
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
        _AddStepButton(nodeId: nodeId, action: action, controller: controller, targetList: steps),
      ],
    );
  }
}

class _FlowStepNode extends StatelessWidget {
  final ActionStep step;
  final int index;
  final List<ActionStep> parentList;
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;

  const _FlowStepNode({
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
                    _StepFlowBuilder(steps: step.successSteps, nodeId: nodeId, action: action, controller: controller),
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
                    _StepFlowBuilder(steps: step.failureSteps, nodeId: nodeId, action: action, controller: controller),
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

class _TriggerNode extends StatelessWidget {
  final String label;

  const _TriggerNode({required this.label});

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

class _AddStepButton extends StatelessWidget {
  final String nodeId;
  final ComponentAction action;
  final VisualBuilderController controller;
  final List<ActionStep> targetList;

  const _AddStepButton({
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
