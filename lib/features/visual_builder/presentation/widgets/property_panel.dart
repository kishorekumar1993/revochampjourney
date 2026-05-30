import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/component_engine/models/component_property.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/models/component_action.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../application/visual_builder_controller.dart';
import '../../application/studio_providers.dart';

class RevoPropertyPanel extends ConsumerStatefulWidget {
  const RevoPropertyPanel({super.key});

  @override
  ConsumerState<RevoPropertyPanel> createState() => _RevoPropertyPanelState();
}

class _RevoPropertyPanelState extends ConsumerState<RevoPropertyPanel> {
  String _activeRightMode = 'properties'; // 'properties', 'actions', 'validations', 'json'

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final selectedNode = builderState.selectedNode;
    final controller = ref.read(visualBuilderProvider.notifier);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Top Toggle Capsule Control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRightModeChip(
                    icon: Icons.tune_rounded,
                    label: "Prop",
                    isSelected: _activeRightMode == 'properties',
                    onPressed: () => setState(() => _activeRightMode = 'properties'),
                  ),
                  const SizedBox(width: 6),
                  _buildRightModeChip(
                    icon: Icons.flash_on_rounded,
                    label: "Actions",
                    isSelected: _activeRightMode == 'actions',
                    onPressed: () => setState(() => _activeRightMode = 'actions'),
                  ),
                  const SizedBox(width: 6),
                  _buildRightModeChip(
                    icon: Icons.gpp_maybe_rounded,
                    label: "Validations",
                    isSelected: _activeRightMode == 'validations',
                    onPressed: () => setState(() => _activeRightMode = 'validations'),
                  ),
                  const SizedBox(width: 6),
                  _buildRightModeChip(
                    icon: Icons.code_rounded,
                    label: "JSON",
                    isSelected: _activeRightMode == 'json',
                    onPressed: () => setState(() => _activeRightMode = 'json'),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _buildRightPanelContent(builderState, selectedNode, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildRightModeChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : RevoTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : RevoTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPanelContent(
    VisualBuilderState state,
    ComponentNode? selectedNode,
    VisualBuilderController controller,
  ) {
    switch (_activeRightMode) {
      case 'properties':
        return _buildPropertiesContent(selectedNode, controller);

      case 'actions':
        return _buildActionsTabContent(selectedNode, controller);

      case 'validations':
        return _buildValidationsTabContent(state);

      case 'json':
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: InteractiveJsonEditor(
            initialJson: controller.exportToJson(),
            onApply: (jsonVal) {
              return controller.importFromJson(jsonVal);
            },
          ),
        );

      default:
        return _buildPropertiesContent(selectedNode, controller);
    }
  }

  Widget _buildActionsTabContent(ComponentNode? selectedNode, VisualBuilderController controller) {
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

    if (selectedNode.actions.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () {
            final action = ComponentAction(event: 'onTap', steps: []);
            controller.updateNodeActions(selectedNode.id, [action]);
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

    final action = selectedNode.actions.first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _buildActionNode("ON ${action.event.toUpperCase()}", isTrigger: true),
          ),
          const Center(
            child: Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
          ),
          _buildStepFlow(action.steps, selectedNode.id, action, controller),
        ],
      ),
    );
  }

  Widget _buildValidationsTabContent(VisualBuilderState state) {
    final List<Map<String, dynamic>> validators = [];
    _gatherValidations(state.rootNode, validators);

    if (validators.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            "No field validation criteria set on this screen layout.",
            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: validators.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final val = validators[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: RevoTheme.cardBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RevoTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gpp_maybe_rounded, color: Color(0xFF5B4FCF), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      val['id'] ?? '',
                      style: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Required:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                  Text(
                    val['required'] == true ? "YES" : "NO",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: val['required'] == true ? Colors.green : RevoTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (val['regex'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Regex Rule:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                    Expanded(
                      child: Text(
                        val['regex'],
                        style: GoogleFonts.sourceCodePro(fontSize: 10, color: const Color(0xFF5B4FCF)),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (val['bounds'] != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Length Bounds:", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary)),
                    Text(val['bounds'], style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepFlow(List<ActionStep> steps, String nodeId, ComponentAction action, VisualBuilderController controller) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(steps.length, (i) {
          final step = steps[i];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionNodeWidget(step, i, steps, nodeId, action, controller),
              const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
            ],
          );
        }),
        _buildAddStepPlaceholder(nodeId, action, controller, targetList: steps),
      ],
    );
  }

  Widget _buildActionNodeWidget(
    ActionStep step,
    int index,
    List<ActionStep> parentList,
    String nodeId,
    ComponentAction action,
    VisualBuilderController controller,
  ) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      step.type.toUpperCase(),
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_getActionStepDetails(step).isNotEmpty)
                      Text(
                        _getActionStepDetails(step),
                        style: GoogleFonts.inter(fontSize: 8, color: RevoTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 13, color: Colors.blueAccent),
                onPressed: () => _showStepConfigDialog(context, step, index, parentList, nodeId, action, controller),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 13, color: Colors.redAccent),
                onPressed: () {
                  final list = List<ActionStep>.from(parentList)..removeAt(index);
                  if (parentList == action.steps) {
                    controller.updateNodeActions(nodeId, [action.copyWith(steps: list)]);
                  } else {
                    final updatedSteps = _updateNestedStepInList(action.steps, step.id, remove: true);
                    controller.updateNodeActions(nodeId, [action.copyWith(steps: updatedSteps)]);
                  }
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.green.withValues(alpha:0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("YES", style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    _buildStepFlow(step.successSteps, nodeId, action, controller),
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
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha:0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text("NO", style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    _buildStepFlow(step.failureSteps, nodeId, action, controller),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddStepPlaceholder(
    String nodeId,
    ComponentAction action,
    VisualBuilderController controller, {
    required List<ActionStep> targetList,
  }) {
    return InkWell(
      onTap: () => _showAddStepDialog(context, nodeId, action, controller, targetList),
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
            Text(
              "Add Step",
              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
            ),
          ],
        ),
      ),
    );
  }

  List<ActionStep> _updateNestedStepInList(List<ActionStep> list, String stepId, {ActionStep? replaceWith, bool remove = false}) {
    final updated = <ActionStep>[];
    for (final s in list) {
      if (s.id == stepId) {
        if (!remove && replaceWith != null) {
          updated.add(replaceWith);
        }
      } else {
        var newS = s;
        if (s.successSteps.isNotEmpty) {
          newS = newS.copyWith(successSteps: _updateNestedStepInList(s.successSteps, stepId, replaceWith: replaceWith, remove: remove));
        }
        if (s.failureSteps.isNotEmpty) {
          newS = newS.copyWith(failureSteps: _updateNestedStepInList(s.failureSteps, stepId, replaceWith: replaceWith, remove: remove));
        }
        updated.add(newS);
      }
    }
    return updated;
  }

  void _showAddStepDialog(
    BuildContext context,
    String nodeId,
    ComponentAction action,
    VisualBuilderController controller,
    List<ActionStep> targetList,
  ) {
    showDialog(
      context: context,
      builder: (context) {
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

        return AlertDialog(
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
                    Navigator.pop(context);
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
                          child: Text(
                            opt['label'] as String,
                            style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showStepConfigDialog(
    BuildContext context,
    ActionStep step,
    int index,
    List<ActionStep> parentList,
    String nodeId,
    ComponentAction action,
    VisualBuilderController controller,
  ) {
    final titleController = TextEditingController(text: step.properties['title'] ?? '');
    final msgController = TextEditingController(text: step.properties['message'] ?? '');
    final durationController = TextEditingController(text: step.properties['duration']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("Configure ${step.type.toUpperCase()}", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13)),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step.type == 'api') ...[
                  TextField(
                    controller: titleController..text = step.properties['url'] ?? '',
                    decoration: const InputDecoration(labelText: "API URL / Endpoint"),
                  ),
                ] else if (step.type == 'navigate') ...[
                  TextField(
                    controller: titleController..text = step.properties['pageId'] ?? '',
                    decoration: const InputDecoration(labelText: "Target Screen Step ID"),
                  ),
                ] else if (step.type == 'snackbar' || step.type == 'alert') ...[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Dialog Title"),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: msgController,
                    decoration: const InputDecoration(labelText: "Message Content"),
                  ),
                ] else if (step.type == 'delay') ...[
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(labelText: "Delay (ms)"),
                    keyboardType: TextInputType.number,
                  ),
                ] else ...[
                  Text("No extra configurations required for this step type.", style: TextStyle(color: RevoTheme.textSecondary, fontSize: 11)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final props = Map<String, dynamic>.from(step.properties);
                if (step.type == 'api') {
                  props['url'] = titleController.text;
                } else if (step.type == 'navigate') {
                  props['pageId'] = titleController.text;
                } else if (step.type == 'snackbar' || step.type == 'alert') {
                  props['title'] = titleController.text;
                  props['message'] = msgController.text;
                } else if (step.type == 'delay') {
                  props['duration'] = int.tryParse(durationController.text) ?? 1000;
                }

                final updatedStep = step.copyWith(properties: props);
                parentList[index] = updatedStep;
                controller.updateNodeActions(nodeId, [action]);
                Navigator.pop(context);
              },
              child: const Text("Save Details", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionNode(String title, {bool isTrigger = false, String details = ''}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isTrigger ? const Color(0xFF5B4FCF) : RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B4FCF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isTrigger ? Colors.white : const Color(0xFF5B4FCF),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              details,
              style: GoogleFonts.inter(
                fontSize: 8,
                color: RevoTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getActionStepDetails(ActionStep step) {
    if (step.type == 'api') return "Call: ${step.properties['url'] ?? '/api'}";
    if (step.type == 'navigate') return "Go to: ${step.properties['pageId'] ?? 'Dashboard'}";
    if (step.type == 'snackbar' || step.type == 'alert') return "Show: ${step.properties['message'] ?? 'Msg'}";
    if (step.type == 'delay') return "Wait ${step.properties['duration'] ?? 1000} ms";
    return "";
  }

  void _gatherValidations(ComponentNode node, List<Map<String, dynamic>> list) {
    final props = node.properties;
    if (node.type == 'TextField' || node.type == 'Dropdown') {
      final isReq = props['required'] == true;
      final regex = props['regexPattern']?.toString() ?? '';
      final min = props['minLength'];
      final max = props['maxLength'];

      if (isReq || regex.isNotEmpty || min != null || max != null) {
        String bounds = '';
        if (min != null && max != null) {
          bounds = '$min-$max chars';
        } else if (min != null) {
          bounds = 'min $min chars';
        } else if (max != null) {
          bounds = 'max $max chars';
        }

        list.add({
          'id': props['fieldName'] ?? node.id,
          'required': isReq,
          'regex': regex.isNotEmpty ? regex : null,
          'bounds': bounds.isNotEmpty ? bounds : null,
        });
      }
    }

    for (final child in node.children) {
      _gatherValidations(child, list);
    }
  }

  Widget _buildPropertiesContent(ComponentNode? selectedNode, VisualBuilderController controller) {
    if (selectedNode == null) {
      return _buildNoSelectionPlaceholder();
    }

    final meta = ComponentRegistry.getByType(selectedNode.type);
    final isForm = meta?.category == ComponentCategory.form;

    // Define active tabs based on category
    final tabs = [
      const Tab(text: "General"),
      const Tab(text: "Style"),
      const Tab(text: "Layout"),
      const Tab(text: "Responsive"),
      const Tab(text: "Data Binding"),
      if (isForm) const Tab(text: "Validation"),
      const Tab(text: "Actions"),
      const Tab(text: "Animation"),
      const Tab(text: "Permissions"),
    ];

    return DefaultTabController(
      key: ValueKey('${selectedNode.id}_${tabs.length}'),
      length: tabs.length,
      child: Column(
        children: [
          // Selection Header
          Container(
            padding: const EdgeInsets.all(16.0),
            color: RevoTheme.sidebarBackground,
            child: Row(
              children: [
                Icon(meta?.icon ?? Icons.settings_rounded, color: const Color(0xFF5B4FCF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedNode.type,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: RevoTheme.textPrimary,
                        ),
                      ),
                      Text(
                        "ID: ${selectedNode.id}",
                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Action Buttons: Duplicate & Delete
                IconButton(
                  tooltip: "Duplicate Component",
                  icon: const Icon(Icons.copy_all_rounded, size: 16, color: Color(0xFF5B4FCF)),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    controller.duplicateNode(selectedNode.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Component duplicated!"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
                if (selectedNode.id != ref.read(visualBuilderProvider).rootNode.id) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: "Delete Component",
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      controller.deleteNode(selectedNode.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Component deleted"),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),

          // TabBar
          TabBar(
            isScrollable: true,
            labelColor: const Color(0xFF5B4FCF),
            unselectedLabelColor: RevoTheme.textSecondary,
            indicatorColor: const Color(0xFF5B4FCF),
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
            tabs: tabs,
          ),
          const Divider(height: 1),

          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildGeneralTab(selectedNode, controller),
                _buildStyleTab(selectedNode, controller),
                _buildLayoutTab(selectedNode, controller),
                _buildResponsiveTab(selectedNode, controller),
                _buildDataBindingTab(selectedNode, controller),
                if (isForm) _buildValidationTab(selectedNode, controller),
                _buildActionsTab(selectedNode, controller),
                _buildAnimationTab(selectedNode, controller),
                _buildPermissionsTab(selectedNode, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0x0C5B4FCF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Color(0xFF5B4FCF),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Component",
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Click on any item on the canvas to configure its layout, style, actions, and validation settings.",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: RevoTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Tab 1: General Properties ---
  Widget _buildGeneralTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;
    final meta = ComponentRegistry.getByType(node.type);
    final isForm = meta?.category == ComponentCategory.form;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isForm) ...[
          _buildPropertyTextField(
            label: "Field ID / Name",
            value: props['fieldName'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fieldName': val}),
          ),
          _buildPropertyTextField(
            label: "Label Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
          _buildPropertyTextField(
            label: "Hint / Placeholder",
            value: props['hint'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'hint': val}),
          ),
          _buildPropertySwitch(
            label: "Is Editable (Enabled)",
            value: props['enabled'] != false,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'enabled': val}),
          ),
          _buildPropertySwitch(
            label: "Is Read Only",
            value: props['readOnly'] == true,
            onChanged: (val) => controller.updateNodeProperties(node.id, {'readOnly': val}),
          ),
          if (node.type == 'TextField') ...[
            _buildPropertySwitch(
              label: "Password Obscure",
              value: props['obscureText'] == true,
              onChanged: (val) => controller.updateNodeProperties(node.id, {'obscureText': val}),
            ),
            _buildPropertyDropdown(
              label: "Keyboard Input Type",
              value: props['keyboardType'] ?? 'text',
              options: ['text', 'number', 'email', 'phone', 'url'],
              onChanged: (val) => controller.updateNodeProperties(node.id, {'keyboardType': val}),
            ),
          ],
          if (node.type == 'Slider') ...[
            _buildPropertyTextField(
              label: "Minimum Value",
              value: props['min']?.toString() ?? '0.0',
              onChanged: (val) => controller.updateNodeProperties(node.id, {'min': double.tryParse(val) ?? 0.0}),
            ),
            _buildPropertyTextField(
              label: "Maximum Value",
              value: props['max']?.toString() ?? '100.0',
              onChanged: (val) => controller.updateNodeProperties(node.id, {'max': double.tryParse(val) ?? 100.0}),
            ),
          ],
          if (node.type == 'Dropdown' || node.type == 'Radio') ...[
            const SizedBox(height: 12),
            Text(
              "Configure Option Items",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._buildOptionsListEditor(node, controller),
          ],
        ] else if (node.type == 'Text' || node.type == 'Button') ...[
          _buildPropertyTextField(
            label: "Content Text",
            value: props['label'] ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'label': val}),
          ),
        ] else if (node.type == 'Image') ...[
          _buildPropertyTextField(
            label: "Image Source URL",
            value: _getStyleValue('src', node, meta)?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'src': val}),
          ),
        ] else if (node.type == 'Icon' || node.type == 'IconButton' || node.type == 'FloatingButton') ...[
          _buildIconSelector(node, controller),
        ],
      ],
    );
  }

  // --- Style & Layout Helpers ---
  bool _shouldShowStyleProperty(String key, ComponentNode node, ComponentMetadata? meta) {
    if (node.properties.containsKey(key) || node.styles.containsKey(key)) {
      return true;
    }
    if (meta != null && meta.defaultProperties.containsKey(key)) {
      return true;
    }
    final type = node.type;
    switch (key) {
      case 'width':
      case 'height':
        return type == 'Container' || type == 'SizedBox' || type == 'Image' || type == 'Card';
      case 'backgroundColor':
        return type == 'Container' || type == 'Card' || type == 'Button' || type == 'FloatingButton' || type == 'Chip' || type == 'Badge';
      case 'gradientStart':
      case 'gradientEnd':
        return type == 'Container' || type == 'Card';
      case 'padding':
      case 'margin':
        return type == 'Container' || type == 'Card' || type == 'Row' || type == 'Column' || type == 'ListView' || type == 'GridView' || type == 'Wrap';
      case 'borderRadius':
        return type == 'Container' || type == 'Card' || type == 'Button' || type == 'Image';
      case 'borderColor':
      case 'borderWidth':
        return type == 'Container' || type == 'Card';
      case 'color':
        return type == 'Icon' || type == 'IconButton' || type == 'Progress';
      case 'textColor':
        return type == 'Text' || type == 'Button' || type == 'Chip' || type == 'Badge';
      case 'fontSize':
        return type == 'Text' || type == 'Icon' || type == 'IconButton';
      case 'fontWeight':
        return type == 'Text';
      case 'elevation':
        return type == 'Card' || type == 'Container' || type == 'Button';
    }
    return false;
  }

  bool _shouldShowLayoutProperty(String key, ComponentNode node, ComponentMetadata? meta) {
    if (node.properties.containsKey(key) || node.styles.containsKey(key)) {
      return true;
    }
    if (meta != null && meta.defaultProperties.containsKey(key)) {
      return true;
    }
    final type = node.type;
    switch (key) {
      case 'mainAxisAlignment':
      case 'crossAxisAlignment':
        return type == 'Row' || type == 'Column';
      case 'spacing':
        return type == 'Row' || type == 'Column' || type == 'Wrap' || type == 'GridView' || type == 'ListView';
    }
    return false;
  }

  dynamic _getStyleValue(String key, ComponentNode node, ComponentMetadata? meta, {dynamic fallback = ''}) {
    if (node.styles.containsKey(key)) {
      return node.styles[key] ?? fallback;
    }
    if (node.properties.containsKey(key)) {
      return node.properties[key] ?? fallback;
    }
    if (meta != null && meta.defaultProperties.containsKey(key)) {
      return meta.defaultProperties[key] ?? fallback;
    }
    return fallback;
  }

  // --- Tab 2: Styles Properties ---
  Widget _buildStyleTab(ComponentNode node, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(node.type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_shouldShowStyleProperty('backgroundColor', node, meta))
          _buildColorFieldWithPresets(
            label: "Background Color (Hex)",
            value: _getStyleValue('backgroundColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'backgroundColor': val}),
          ),
        if (_shouldShowStyleProperty('gradientStart', node, meta))
          _buildColorFieldWithPresets(
            label: "Gradient Start Color (Hex)",
            value: _getStyleValue('gradientStart', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientStart': val}),
          ),
        if (_shouldShowStyleProperty('gradientEnd', node, meta))
          _buildColorFieldWithPresets(
            label: "Gradient End Color (Hex)",
            value: _getStyleValue('gradientEnd', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'gradientEnd': val}),
          ),
        if (_shouldShowStyleProperty('borderColor', node, meta))
          _buildColorFieldWithPresets(
            label: "Border Color (Hex)",
            value: _getStyleValue('borderColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderColor': val}),
          ),
        if (_shouldShowStyleProperty('borderWidth', node, meta))
          _buildPropertyTextField(
            label: "Border Width (px)",
            value: _getStyleValue('borderWidth', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderWidth': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('color', node, meta))
          _buildColorFieldWithPresets(
            label: "Theme Color (Hex)",
            value: _getStyleValue('color', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'color': val}),
          ),
        if (_shouldShowStyleProperty('textColor', node, meta))
          _buildColorFieldWithPresets(
            label: "Text Color (Hex)",
            value: _getStyleValue('textColor', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'textColor': val}),
          ),
        if (_shouldShowStyleProperty('fontSize', node, meta))
          _buildPropertyTextField(
            label: "Font Size (pt)",
            value: _getStyleValue('fontSize', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontSize': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('fontWeight', node, meta))
          _buildPropertyDropdown(
            label: "Font Weight",
            value: _getStyleValue('fontWeight', node, meta, fallback: 'normal')?.toString() ?? 'normal',
            options: const ['normal', 'bold', 'w100', 'w300', 'w500', 'w700'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'fontWeight': val}),
          ),
        if (_shouldShowStyleProperty('padding', node, meta))
          _buildPropertyTextField(
            label: "Padding (All)",
            value: _getStyleValue('padding', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'padding': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('margin', node, meta))
          _buildPropertyTextField(
            label: "Margin (All)",
            value: _getStyleValue('margin', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'margin': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('borderRadius', node, meta))
          _buildPropertyTextField(
            label: "Border Radius (px)",
            value: _getStyleValue('borderRadius', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'borderRadius': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('width', node, meta))
          _buildPropertyTextField(
            label: "Width (px)",
            value: _getStyleValue('width', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'width': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('height', node, meta))
          _buildPropertyTextField(
            label: "Height (px)",
            value: _getStyleValue('height', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'height': double.tryParse(val)}),
          ),
        if (_shouldShowStyleProperty('elevation', node, meta))
          _buildPropertyTextField(
            label: "Elevation (Shadow)",
            value: _getStyleValue('elevation', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'elevation': double.tryParse(val)}),
          ),
      ],
    );
  }

  // --- Tab 3: Layout Properties (Layout Containers only) ---
  Widget _buildLayoutTab(ComponentNode node, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(node.type);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_shouldShowLayoutProperty('mainAxisAlignment', node, meta))
          _buildPropertyDropdown(
            label: "Main Axis Alignment",
            value: _getStyleValue('mainAxisAlignment', node, meta, fallback: 'start')?.toString() ?? 'start',
            options: const ['start', 'center', 'end', 'space_between', 'space_around', 'space_evenly'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'mainAxisAlignment': val}),
          ),
        if (_shouldShowLayoutProperty('crossAxisAlignment', node, meta))
          _buildPropertyDropdown(
            label: "Cross Axis Alignment",
            value: _getStyleValue('crossAxisAlignment', node, meta, fallback: 'center')?.toString() ?? 'center',
            options: const ['start', 'center', 'end', 'stretch'],
            onChanged: (val) => controller.updateNodeProperties(node.id, {'crossAxisAlignment': val}),
          ),
        if (_shouldShowLayoutProperty('spacing', node, meta))
          _buildPropertyTextField(
            label: "Spacing (Gap)",
            value: _getStyleValue('spacing', node, meta, fallback: '')?.toString() ?? '',
            onChanged: (val) => controller.updateNodeProperties(node.id, {'spacing': double.tryParse(val)}),
          ),
      ],
    );
  }

  // --- Tab 4: Validation (Forms only) ---
  Widget _buildValidationTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPropertySwitch(
          label: "Field is Required",
          value: props['required'] == true,
          onChanged: (val) => controller.updateNodeProperties(node.id, {'required': val}),
        ),
        _buildPropertyTextField(
          label: "Regex Validation Pattern",
          value: props['regexPattern'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'regexPattern': val}),
        ),
        _buildPropertyTextField(
          label: "Min Characters Limit",
          value: props['minLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'minLength': int.tryParse(val)}),
        ),
        _buildPropertyTextField(
          label: "Max Characters Limit",
          value: props['maxLength']?.toString() ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'maxLength': int.tryParse(val)}),
        ),
        _buildPropertyTextField(
          label: "Error message details",
          value: props['errorMessage'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'errorMessage': val}),
        ),
      ],
    );
  }

  // --- Tab 5: Actions Editor ---
  Widget _buildActionsTab(ComponentNode node, VisualBuilderController controller) {
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
          Container(
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
          )
        else
          ...actions.map((act) {
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
                        Text("Trigger: ${act.event}", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 14),
                          onPressed: () => controller.updateNodeActions(node.id, []),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    ...List.generate(act.steps.length, (i) {
                      final step = act.steps[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0x0C5B4FCF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${i + 1}. ${step.type.toUpperCase()}",
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF5B4FCF)),
                            ),
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 12, color: RevoTheme.textSecondary),
                              onPressed: () {
                                final list = List<ActionStep>.from(act.steps)..removeAt(i);
                                controller.updateNodeActions(node.id, [act.copyWith(steps: list)]);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Add Action Step Dropdown menu
                    PopupMenuButton<String>(
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
                        final list = List<ActionStep>.from(act.steps)..add(ActionStep(id: 'step_${DateTime.now().millisecondsSinceEpoch}', type: val));
                        controller.updateNodeActions(node.id, [act.copyWith(steps: list)]);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'validate', child: Text("Validate Fields")),
                        const PopupMenuItem(value: 'api', child: Text("Call API service")),
                        const PopupMenuItem(value: 'navigate', child: Text("Navigate Screen")),
                        const PopupMenuItem(value: 'saveToken', child: Text("Save Data Token")),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // --- Tab 6: API Integration ---
  Widget _buildApiTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Remote API Data Connector",
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        _buildPropertyTextField(
          label: "Endpoint URL",
          value: props['apiUrl'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'apiUrl': val}),
        ),
        _buildPropertyDropdown(
          label: "HTTP Method",
          value: props['apiMethod'] ?? 'GET',
          options: ['GET', 'POST'],
          onChanged: (val) => controller.updateNodeProperties(node.id, {'apiMethod': val}),
        ),
        _buildPropertyTextField(
          label: "Response List Array Key (e.g. data.users)",
          value: props['responseListKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'responseListKey': val}),
        ),
        _buildPropertyTextField(
          label: "Item Label key",
          value: props['labelKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'labelKey': val}),
        ),
        _buildPropertyTextField(
          label: "Item Value key",
          value: props['valueKey'] ?? '',
          onChanged: (val) => controller.updateNodeProperties(node.id, {'valueKey': val}),
        ),
      ],
    );
  }

  // --- Forms Inputs Elements Builders ---

  Widget _buildPropertyTextField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: TextField(
              controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
              onChanged: onChanged,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: RevoTheme.cardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
              ),
              style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.contains(value) ? value : options.first,
                dropdownColor: RevoTheme.cardBg,
                isExpanded: true,
                style: GoogleFonts.inter(color: RevoTheme.textPrimary, fontSize: 12),
                items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary, fontWeight: FontWeight.w500)),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF5B4FCF),
            activeTrackColor: const Color(0xFF5B4FCF).withOpacity(0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- Premium Extra Builders ---

  List<Widget> _buildOptionsListEditor(ComponentNode node, VisualBuilderController controller) {
    final List<dynamic> rawOptions = node.properties['options'] ?? [];
    final List<String> options = List<String>.from(rawOptions.map((e) => e.toString()));

    return [
      ...List.generate(options.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: TextEditingController(text: options[index])
                      ..selection = TextSelection.fromPosition(TextPosition(offset: options[index].length)),
                    onChanged: (val) {
                      final updated = List<String>.from(options);
                      updated[index] = val;
                      controller.updateNodeProperties(node.id, {'options': updated});
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      filled: true,
                      fillColor: RevoTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                onPressed: () {
                  final updated = List<String>.from(options)..removeAt(index);
                  controller.updateNodeProperties(node.id, {'options': updated});
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () {
            final updated = List<String>.from(options)..add('Option ${options.length + 1}');
            controller.updateNodeProperties(node.id, {'options': updated});
          },
          icon: const Icon(Icons.add, size: 14, color: Color(0xFF5B4FCF)),
          label: Text("Add Option Item", style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5B4FCF), fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
        ),
      ),
    ];
  }

  Widget _buildColorFieldWithPresets({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final List<String> presets = [
      '#5B4FCF', // Indigo
      '#10B981', // Emerald
      '#EF4444', // Red
      '#F59E0B', // Amber
      '#3B82F6', // Blue
      '#1E1E2F', // Dark slate
      '#FFFFFF', // White
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
                    onChanged: onChanged,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      filled: true,
                      fillColor: RevoTheme.cardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: RevoTheme.cardBorder)),
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: PropertyParser.parseColor(value) ?? Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: RevoTheme.cardBorder, width: 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: presets.map((colorHex) {
                final color = PropertyParser.parseColor(colorHex)!;
                final isSelected = value.toLowerCase().replaceAll('#', '') == colorHex.toLowerCase().replaceAll('#', '');
                return GestureDetector(
                  onTap: () => onChanged(colorHex),
                  child: Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5B4FCF) : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconSelector(ComponentNode node, VisualBuilderController controller) {
    final currentIcon = node.properties['icon'] ?? 'info';
    final List<String> iconNames = [
      'add', 'star', 'info', 'home', 'settings',
      'person', 'email', 'phone', 'lock', 'check',
      'close', 'arrow_forward', 'arrow_back'
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Icon Asset", style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: iconNames.map((name) {
              final isSelected = currentIcon == name;
              return Tooltip(
                message: name,
                child: InkWell(
                  onTap: () => controller.updateNodeProperties(node.id, {'icon': name}),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0x1F5B4FCF) : RevoTheme.cardBg,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.cardBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getIconByName(name),
                      size: 18,
                      color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIconByName(String name) {
    switch (name.toLowerCase()) {
      case 'add':
        return Icons.add;
      case 'star':
        return Icons.star;
      case 'info':
        return Icons.info_outline;
      case 'home':
        return Icons.home_outlined;
      case 'settings':
        return Icons.settings;
      case 'person':
        return Icons.person_outline;
      case 'email':
        return Icons.mail_outline;
      case 'phone':
        return Icons.phone_android;
      case 'lock':
        return Icons.lock_outline;
      case 'check':
        return Icons.check;
      case 'close':
        return Icons.close;
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'arrow_back':
        return Icons.arrow_back;
      default:
        return Icons.category_outlined;
    }
  }

  Widget _buildResponsiveTab(ComponentNode node, VisualBuilderController controller) {
    final responsive = node.responsive;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Responsive View Breakpoints", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertySwitch(
          label: "Visible on Mobile",
          value: responsive['mobile'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..[ 'mobile' ] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        _buildPropertySwitch(
          label: "Visible on Tablet",
          value: responsive['tablet'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..[ 'tablet' ] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
        _buildPropertySwitch(
          label: "Visible on Desktop",
          value: responsive['desktop'] != false,
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(responsive)..[ 'desktop' ] = val;
            controller.updateNodeProperties(node.id, {'responsive': upd});
          },
        ),
      ],
    );
  }

  Widget _buildDataBindingTab(ComponentNode node, VisualBuilderController controller) {
    final bindings = node.bindings;
    final variables = ref.watch(appVariablesProvider);
    final varNames = variables.map((v) => v.name).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Variable & API Bindings", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertyDropdown(
          label: "Bind to State Variable",
          value: bindings['variable'] ?? 'None',
          options: ['None', ...varNames],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(bindings)..[ 'variable' ] = val;
            controller.updateNodeProperties(node.id, {'bindings': upd});
          },
        ),
        _buildPropertyTextField(
          label: "Bind Response API Path",
          value: bindings['apiPath'] ?? '',
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(bindings)..[ 'apiPath' ] = val;
            controller.updateNodeProperties(node.id, {'bindings': upd});
          },
        ),
      ],
    );
  }

  Widget _buildAnimationTab(ComponentNode node, VisualBuilderController controller) {
    final animations = node.animations;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Micro-Animations Setup", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertyDropdown(
          label: "Animation Type",
          value: animations['type'] ?? 'none',
          options: ['none', 'fade', 'slide', 'scale'],
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..[ 'type' ] = val;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
        _buildPropertyTextField(
          label: "Animation Duration (ms)",
          value: animations['duration']?.toString() ?? '300',
          onChanged: (val) {
            final upd = Map<String, dynamic>.from(animations)..[ 'duration' ] = int.tryParse(val) ?? 300;
            controller.updateNodeProperties(node.id, {'animations': upd});
          },
        ),
      ],
    );
  }

  Widget _buildPermissionsTab(ComponentNode node, VisualBuilderController controller) {
    final props = node.properties;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Permissions & Roles", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 12),
        _buildPropertyDropdown(
          label: "Minimum Access Role",
          value: props['role'] ?? 'guest',
          options: ['guest', 'user', 'admin'],
          onChanged: (val) => controller.updateNodeProperties(node.id, {'role': val}),
        ),
      ],
    );
  }
}

class InteractiveJsonEditor extends ConsumerStatefulWidget {
  final String initialJson;
  final bool Function(String) onApply;

  const InteractiveJsonEditor({
    super.key,
    required this.initialJson,
    required this.onApply,
  });

  @override
  ConsumerState<InteractiveJsonEditor> createState() => _InteractiveJsonEditorState();
}

class _InteractiveJsonEditorState extends ConsumerState<InteractiveJsonEditor> {
  late TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialJson);
  }

  @override
  void didUpdateWidget(covariant InteractiveJsonEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialJson != widget.initialJson) {
      _controller.text = widget.initialJson;
      _error = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _importJsonFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Crucial for Web to get file bytes
      );
      if (result != null && result.files.isNotEmpty) {
        String? jsonStr;
        final file = result.files.first;
        if (file.bytes != null) {
          jsonStr = utf8.decode(file.bytes!);
        } else if (file.path != null) {
          final ioFile = io.File(file.path!);
          jsonStr = await ioFile.readAsString();
        }

        if (jsonStr != null) {
          final success = widget.onApply(jsonStr);
          if (success) {
            _controller.text = jsonStr;
            setState(() {
              _error = null;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("JSON file imported successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            setState(() {
              _error = "Failed to parse JSON file content. Verify standard keys.";
            });
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking file: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "JSON Screen Schema Layout Editor",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Apply JSON Schema",
                    icon: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF5B4FCF)),
                    onPressed: () {
                      final success = widget.onApply(_controller.text);
                      setState(() {
                        if (success) {
                          _error = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Visual Canvas applied successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          _error = "Invalid JSON Layout Schema";
                        }
                      });
                    },
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Paste & Import",
                    icon: const Icon(Icons.paste_rounded, size: 16, color: Color(0xFF5B4FCF)),
                    onPressed: () => _showImportPasteDialog(context),
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                    tooltip: "Import JSON File",
                    icon: const Icon(Icons.upload_file_rounded, size: 16, color: Color(0xFF5B4FCF)),
                    onPressed: () => _importJsonFile(context),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _error!,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TextField(
              controller: _controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                fillColor: Colors.black,
                filled: true,
                contentPadding: EdgeInsets.all(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showImportPasteDialog(BuildContext context) {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: RevoTheme.sidebarBackground,
          title: Text("Paste & Import Screen Layout JSON", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14)),
          content: SizedBox(
            width: 500,
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Paste your custom ComponentNode JSON structure below to import it into the canvas workspace:",
                  style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TextField(
                      controller: pasteController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        fillColor: Colors.black,
                        filled: true,
                        hintText: "{\n  \"id\": \"root-scaffold\",\n  \"type\": \"Column\",\n  ...\n}",
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final success = widget.onApply(pasteController.text);
                if (success) {
                  _controller.text = pasteController.text;
                  setState(() {
                    _error = null;
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("JSON Screen Layout imported successfully!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed to parse JSON schema. Verify standard keys."),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: const Text("Import Layout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
