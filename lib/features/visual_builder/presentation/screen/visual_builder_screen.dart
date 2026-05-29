import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/models/component_action.dart';
import '../widgets/component_palette.dart';
import '../widgets/builder_canvas.dart';
import '../widgets/component_tree.dart';
import '../widgets/property_panel.dart';
import '../widgets/builder_sidebar.dart';
import '../widgets/studio_panels.dart';
import '../../application/visual_builder_controller.dart';

class VisualBuilderScreen extends ConsumerStatefulWidget {
  const VisualBuilderScreen({super.key});

  @override
  ConsumerState<VisualBuilderScreen> createState() => _VisualBuilderScreenState();
}

class _VisualBuilderScreenState extends ConsumerState<VisualBuilderScreen> {
  String _activeSidebarTab = 'widgets';
  bool _showBottomPanel = true;
  String _activeBottomTab = 'json';

  @override
  Widget build(BuildContext context) {
    final builderState = ref.watch(visualBuilderProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    return Scaffold(
      backgroundColor: RevoTheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar Icons
          RevoBuilderSidebar(
            activeTab: _activeSidebarTab,
            onTabChanged: (tab) {
              setState(() {
                _activeSidebarTab = tab;
              });
            },
          ),

          // Active studio panels switcher
          _buildActiveSidebarPanel(),

          // Center Workspace (Canvas + Bottom Panels)
          Expanded(
            child: Column(
              children: [
                // Visual Canvas
                const RevoBuilderCanvas(),

                // Bottom Panel drawer toggle
                _buildBottomPanelToggler(),

                // Bottom Panel (JSON Editor / Action Flow)
                if (_showBottomPanel)
                  _buildBottomPanel(builderState, controller),
              ],
            ),
          ),

          // Right Properties Editor Panel
          const RevoPropertyPanel(),
        ],
      ),
    );
  }

  Widget _buildBottomPanelToggler() {
    return Container(
      height: 28,
      color: RevoTheme.sidebarBackground,
      child: Center(
        child: InkWell(
          onTap: () {
            setState(() {
              _showBottomPanel = !_showBottomPanel;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _showBottomPanel ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                size: 14,
                color: const Color(0xFF5B4FCF),
              ),
              const SizedBox(width: 4),
              Text(
                _showBottomPanel ? "Collapse Code & Action Flow" : "Expand Code & Action Flow",
                style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(VisualBuilderState state, VisualBuilderController controller) {
    return DefaultTabController(
      length: 3,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: RevoTheme.sidebarBackground,
          border: Border(top: BorderSide(color: RevoTheme.cardBorder)),
        ),
        child: Column(
          children: [
            // Header tabs
            TabBar(
              isScrollable: true,
              labelColor: const Color(0xFF5B4FCF),
              unselectedLabelColor: RevoTheme.textSecondary,
              indicatorColor: const Color(0xFF5B4FCF),
              labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              onTap: (index) {
                final tabIds = ['json', 'actions', 'validations'];
                setState(() {
                  _activeBottomTab = tabIds[index];
                });
              },
              tabs: const [
                Tab(text: "JSON Editor"),
                Tab(text: "Action Flow"),
                Tab(text: "Validation Matrix"),
              ],
            ),
            const Divider(height: 1),
  
            // Tab content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildBottomTabContent(state, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomTabContent(VisualBuilderState state, VisualBuilderController controller) {
    switch (_activeBottomTab) {
      case 'json':
        final jsonStr = controller.exportToJson();
        return InteractiveJsonEditor(
          initialJson: jsonStr,
          onApply: (jsonVal) {
            return controller.importFromJson(jsonVal);
          },
        );

      case 'actions':
        final selectedNode = state.selectedNode;
        if (selectedNode == null) {
          return Center(
            child: Text(
              "Select a component on the canvas to configure its visual Action Flow.",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
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
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Create Action Trigger (onTap)", style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final action = selectedNode.actions.first;
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Event trigger start
                      _buildActionNode("ON ${action.event.toUpperCase()}", isTrigger: true),
                      const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
                      // The steps flow
                      _buildStepFlow(action.steps, selectedNode.id, action, controller),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

      case 'validations':
        // Validation matrix
        final List<Map<String, dynamic>> validators = [];
        _gatherValidations(state.rootNode, validators);

        if (validators.isEmpty) {
          return Center(
            child: Text(
              "No field validation criteria set on this screen layout.",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            ),
          );
        }

        return SingleChildScrollView(
          child: Table(
            border: TableBorder.all(color: RevoTheme.cardBorder),
            children: [
              TableRow(
                decoration: BoxDecoration(color: RevoTheme.cardBg),
                children: [
                  _buildTableCell("Field ID", isHeader: true),
                  _buildTableCell("Required", isHeader: true),
                  _buildTableCell("Regex Rules", isHeader: true),
                  _buildTableCell("Length Bounds", isHeader: true),
                ],
              ),
              ...validators.map((val) {
                return TableRow(
                  children: [
                    _buildTableCell(val['id'] ?? ''),
                    _buildTableCell(val['required'] == true ? 'YES' : 'NO'),
                    _buildTableCell(val['regex'] ?? 'None'),
                    _buildTableCell(val['bounds'] ?? 'None'),
                  ],
                );
              }),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.type.toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                  ),
                  if (_getActionStepDetails(step).isNotEmpty)
                    Text(
                      _getActionStepDetails(step),
                      style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.settings_rounded, size: 14, color: Colors.blueAccent),
                onPressed: () => _showStepConfigDialog(context, step, index, parentList, nodeId, action, controller),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.redAccent),
                onPressed: () {
                  final list = List<ActionStep>.from(parentList)..removeAt(index);
                  // Find and replace in tree recursively, or just update root action steps
                  if (parentList == action.steps) {
                    controller.updateNodeActions(nodeId, [action.copyWith(steps: list)]);
                  } else {
                    // Update actions recursively
                    final updatedSteps = _updateNestedStepInList(action.steps, step.id, remove: true);
                    controller.updateNodeActions(nodeId, [action.copyWith(steps: updatedSteps)]);
                  }
                },
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha:0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text("YES", style: TextStyle(color: Colors.green, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  _buildStepFlow(step.successSteps, nodeId, action, controller),
                ],
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha:0.2), borderRadius: BorderRadius.circular(4)),
                    child: const Text("NO", style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  _buildStepFlow(step.failureSteps, nodeId, action, controller),
                ],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x0C5B4FCF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0x335B4FCF), style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 12, color: Color(0xFF5B4FCF)),
            const SizedBox(width: 4),
            Text(
              "Add Step",
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
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
          title: Text("Select Action Step Type", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14)),
          content: SizedBox(
            width: 400,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
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
                    final updatedList = [...targetList, newStep];
                    if (targetList == action.steps) {
                      controller.updateNodeActions(nodeId, [action.copyWith(steps: updatedList)]);
                    } else {
                      // Nested step insertion requires updating parent recursively
                      // Find one step in targetList and use it to locate nesting branch
                      if (targetList.isNotEmpty) {
                        targetList.add(newStep);
                        controller.updateNodeActions(nodeId, [action]);
                      } else {
                        // Empty list nesting is handled by appending inside the parent step branches
                        // Since we passed targetList by reference in Dart, targetList.add() will directly mutate
                        // successSteps or failureSteps. We just notify controller with action to sync!
                        targetList.add(newStep);
                        controller.updateNodeActions(nodeId, [action]);
                      }
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: RevoTheme.cardBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Icon(opt['icon'] as IconData, size: 16, color: const Color(0xFF5B4FCF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            opt['label'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textPrimary),
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
          title: Text("Configure ${step.type.toUpperCase()}", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 14)),
          content: SizedBox(
            width: 320,
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
                  Text("No extra configurations required for this step type.", style: TextStyle(color: RevoTheme.textSecondary)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isTrigger ? const Color(0xFF5B4FCF) : RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF5B4FCF)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isTrigger ? Colors.white : const Color(0xFF5B4FCF),
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              details,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: RevoTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getActionStepDetails(ActionStep step) {
    if (step.type == 'api') return "Call endpoint: ${step.properties['url'] ?? '/api/v1'}";
    if (step.type == 'navigate') return "Jump screen: ${step.properties['pageId'] ?? 'Dashboard'}";
    if (step.type == 'snackbar' || step.type == 'alert') return "Show: ${step.properties['message'] ?? 'Message text'}";
    if (step.type == 'delay') return "Wait ${step.properties['duration'] ?? 1000} ms";
    return "";
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? RevoTheme.textPrimary : RevoTheme.textSecondary,
        ),
      ),
    );
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
          bounds = '$min - $max chars';
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

  Widget _buildActiveSidebarPanel() {
    switch (_activeSidebarTab) {
      case 'widgets':
        return const RevoComponentPalette();
      case 'tree':
        return const RevoComponentTree();
      case 'pages':
        return const RevoPagesPanel();
      case 'theme':
        return const RevoThemeStudioPanel();
      case 'api':
        return const RevoApiStudioPanel();
      case 'db':
        return const RevoDatabaseStudioPanel();
      case 'variables':
        return const RevoVariablesPanel();
      case 'actions':
        return const RevoActionFlowPanel();
      case 'assets':
        return const RevoAssetsPanel();
      case 'responsive':
        return const RevoResponsivePanel();
      case 'code':
        return const RevoGeneratedCodePanel();
      case 'settings':
        return const RevoSettingsPanel();
      default:
        return const RevoComponentPalette();
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "JSON Screen Schema Layout Editor",
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        _error!,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ElevatedButton.icon(
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
                    icon: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    label: const Text("Apply JSON", style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5B4FCF),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showImportPasteDialog(context),
                    icon: const Icon(Icons.paste_rounded, size: 12, color: Color(0xFF5B4FCF)),
                    label: const Text("Paste & Import", style: TextStyle(fontSize: 11, color: Color(0xFF5B4FCF))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF5B4FCF)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],
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
