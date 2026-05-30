import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../application/visual_builder_controller.dart';
import 'property_panel/tabs/properties_tab.dart';
import 'property_panel/tabs/actions_tab.dart';
import 'property_panel/tabs/validations_tab.dart';
import 'property_panel/tabs/json_tab.dart';

// Re-export InteractiveJsonEditor so existing imports remain compatible.
export 'property_panel/tabs/json_tab.dart' show InteractiveJsonEditor;

/// The main property panel shown on the right side of the Visual Builder.
///
/// Architecture:
///   - Top row of toggle chips: Properties | Actions | Validations | JSON
///   - Properties mode: renders a DefaultTabController with sub-tabs pulled
///     from the modular files in property_panel/tabs/
///   - Other modes: render flat views from the same tab files
class RevoPropertyPanel extends ConsumerStatefulWidget {
  const RevoPropertyPanel({super.key});

  @override
  ConsumerState<RevoPropertyPanel> createState() => _RevoPropertyPanelState();
}

class _RevoPropertyPanelState extends ConsumerState<RevoPropertyPanel> {
  String _activeMode = 'properties';

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
          // ── Top Mode Selector ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeChip(icon: Icons.tune_rounded,       label: "Prop",        mode: 'properties'),
                  const SizedBox(width: 6),
                  _modeChip(icon: Icons.flash_on_rounded,   label: "Actions",     mode: 'actions'),
                  const SizedBox(width: 6),
                  _modeChip(icon: Icons.gpp_maybe_rounded,  label: "Validations", mode: 'validations'),
                  const SizedBox(width: 6),
                  _modeChip(icon: Icons.code_rounded,       label: "JSON",        mode: 'json'),
                ],
              ),
            ),
          ),

          // ── Main Content ───────────────────────────────────────────────────
          Expanded(
            child: _buildContent(builderState, selectedNode, controller),
          ),
        ],
      ),
    );
  }

  // ── Mode Selector Chip ─────────────────────────────────────────────────────

  Widget _modeChip({
    required IconData icon,
    required String label,
    required String mode,
  }) {
    final bool isSelected = _activeMode == mode;
    return InkWell(
      onTap: () => setState(() => _activeMode = mode),
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
            Icon(icon, size: 13, color: isSelected ? Colors.white : RevoTheme.textSecondary),
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

  // ── Content Router ─────────────────────────────────────────────────────────

  Widget _buildContent(
    VisualBuilderState state,
    ComponentNode? selectedNode,
    VisualBuilderController controller,
  ) {
    switch (_activeMode) {
      case 'properties':
        return _buildPropertiesShell(selectedNode, controller);
      case 'actions':
        return RevoActionsFlowView(selectedNode: selectedNode, controller: controller);
      case 'validations':
        return RevoValidationsSummaryView(rootNode: state.rootNode);
      case 'json':
        return RevoJsonTab(controller: controller);
      default:
        return _buildPropertiesShell(selectedNode, controller);
    }
  }

  // ── Properties Shell (multi-tab) ───────────────────────────────────────────

  Widget _buildPropertiesShell(ComponentNode? selectedNode, VisualBuilderController controller) {
    if (selectedNode == null) return _noSelectionPlaceholder();

    final meta = ComponentRegistry.getByType(selectedNode.type);
    final isForm = meta?.category == ComponentCategory.form;

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

    final tabViews = [
      RevoGeneralTab(node: selectedNode, controller: controller),
      RevoStyleTab(node: selectedNode, controller: controller),
      RevoLayoutTab(node: selectedNode, controller: controller),
      RevoResponsiveTab(node: selectedNode, controller: controller),
      RevoDataBindingTab(node: selectedNode, controller: controller),
      if (isForm) RevoValidationTab(node: selectedNode, controller: controller),
      RevoActionsTab(node: selectedNode, controller: controller),
      RevoAnimationTab(node: selectedNode, controller: controller),
      RevoPermissionsTab(node: selectedNode, controller: controller),
    ];

    return DefaultTabController(
      key: ValueKey('${selectedNode.id}_${tabs.length}'),
      length: tabs.length,
      child: Column(
        children: [
          // Component header
          _componentHeader(selectedNode, controller),

          // Tab bar
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF5B4FCF),
            unselectedLabelColor: RevoTheme.textSecondary,
            indicatorColor: const Color(0xFF5B4FCF),
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
            tabs: tabs,
          ),
          const Divider(height: 1),

          // Tab content
          Expanded(
            child: TabBarView(children: tabViews),
          ),
        ],
      ),
    );
  }

  // ── Component Header ───────────────────────────────────────────────────────

  Widget _componentHeader(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);

    return Container(
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
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                ),
                Text(
                  "ID: ${selectedNode.id}",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Duplicate button
          IconButton(
            tooltip: "Duplicate Component",
            icon: const Icon(Icons.copy_all_rounded, size: 16, color: Color(0xFF5B4FCF)),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            onPressed: () {
              controller.duplicateNode(selectedNode.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Component duplicated!"), duration: Duration(seconds: 1)),
              );
            },
          ),
          // Delete button (not for root)
          if (selectedNode.id != ref.read(visualBuilderProvider).rootNode.id) ...[
            const SizedBox(width: 4),
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
    );
  }

  // ── No-selection Placeholder ───────────────────────────────────────────────

  Widget _noSelectionPlaceholder() {
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
                decoration: const BoxDecoration(color: Color(0x0C5B4FCF), shape: BoxShape.circle),
                child: const Icon(Icons.touch_app_rounded, color: Color(0xFF5B4FCF), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                "Select Component",
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                "Click on any item on the canvas to configure its layout, style, actions, and validation settings.",
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
