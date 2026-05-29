import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../widgets/component_palette.dart';
import '../widgets/builder_canvas.dart';
import '../widgets/component_tree.dart';
import '../widgets/property_panel.dart';
import '../widgets/builder_sidebar.dart';
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

          // Palette / Tree conditional panel based on Sidebar selection
          if (_activeSidebarTab == 'widgets')
            const RevoComponentPalette()
          else if (_activeSidebarTab == 'tree')
            const RevoComponentTree()
          else
            _buildThemeStudioPlaceholder(),

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
        return TextField(
          controller: TextEditingController(text: jsonStr),
          maxLines: null,
          readOnly: true,
          style: GoogleFonts.sourceCodePro(fontSize: 11, color: Colors.greenAccent),
          decoration: const InputDecoration(
            border: InputBorder.none,
            fillColor: Colors.black,
            filled: true,
            contentPadding: EdgeInsets.all(8),
          ),
        );

      case 'actions':
        final selectedNode = state.selectedNode;
        if (selectedNode == null || selectedNode.actions.isEmpty) {
          return Center(
            child: Text(
              "Select a component with actions to see its visual Action Flow chart.",
              style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
            ),
          );
        }

        final action = selectedNode.actions.first;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Event trigger start
                _buildActionNode("ON ${action.event.toUpperCase()}", isTrigger: true),

                // Map steps with arrows in between
                ...action.steps.expand((step) => [
                      const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF5B4FCF)),
                      _buildActionNode(step.type.toUpperCase(), details: _getActionStepDetails(step)),
                    ]),
              ],
            ),
          ],
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

  String _getActionStepDetails(dynamic step) {
    if (step.type == 'api') return "Call authentication / user API endpoint";
    if (step.type == 'navigate') return "Go to Dashboard Screen";
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

  Widget _buildThemeStudioPlaceholder() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.palette_outlined, size: 36, color: Color(0xFF5B4FCF)),
              const SizedBox(height: 12),
              Text(
                "Theme Studio",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Modify styling tokens compatible with Theme Studio (fonts, button styles, primary colors).",
                style: GoogleFonts.inter(fontSize: 11, color: RevoTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
