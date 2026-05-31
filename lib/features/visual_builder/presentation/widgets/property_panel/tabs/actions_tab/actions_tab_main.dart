import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../core/theme.dart';
import '../../../../../../../core/component_engine/models/component_node.dart';
import '../../../../../../../core/component_engine/models/component_action.dart';
import '../../../../../application/visual_builder_controller.dart';
import 'step_tile.dart';
import 'step_flow_builder.dart';

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
          NoActionsPlaceholder(node: node, controller: controller)
        else
          ...actions.map((act) => ActionCard(node: node, action: act, controller: controller)),
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
          Center(child: TriggerNode(label: "ON ${action.event.toUpperCase()}")),
          const Center(child: Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF))),
          StepFlowBuilder(
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

class NoActionsPlaceholder extends StatelessWidget {
  final ComponentNode node;
  final VisualBuilderController controller;

  const NoActionsPlaceholder({super.key, required this.node, required this.controller});

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

class ActionCard extends StatelessWidget {
  final ComponentNode node;
  final ComponentAction action;
  final VisualBuilderController controller;

  const ActionCard({super.key, required this.node, required this.action, required this.controller});

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
              return StepTile(
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
