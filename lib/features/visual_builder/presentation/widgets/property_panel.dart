import 'dart:ui';
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

/// The overhauled right property panel structured entirely around:
/// Component Definition
///  ├─ Properties
///  ├─ Events
///  ├─ Validations
///  ├─ Slots
///  └─ Actions
class RevoPropertyPanel extends ConsumerStatefulWidget {
  const RevoPropertyPanel({super.key});

  @override
  ConsumerState<RevoPropertyPanel> createState() => _RevoPropertyPanelState();
}

class _RevoPropertyPanelState extends ConsumerState<RevoPropertyPanel> {
  String _activeMode = 'properties';
  String? _activeEventTrigger;

  @override
  Widget build(BuildContext context) {
    final selectedNode = ref.watch(builderSelectedNodeProvider);
    final rootNode = ref.watch(builderRootNodeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(left: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // ── Top Mode Selector (5-Tab Component Definition Registry) ─────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeChip(icon: Icons.tune_rounded, label: "Properties", mode: 'properties'),
                  const SizedBox(width: 5),
                  _modeChip(icon: Icons.flash_on_rounded, label: "Events", mode: 'events'),
                  const SizedBox(width: 5),
                  _modeChip(icon: Icons.gpp_maybe_rounded, label: "Validations", mode: 'validations'),
                  const SizedBox(width: 5),
                  _modeChip(icon: Icons.splitscreen_rounded, label: "Slots", mode: 'slots'),
                  const SizedBox(width: 5),
                  _modeChip(icon: Icons.schema_rounded, label: "Actions", mode: 'actions'),
                  const SizedBox(width: 5),
                  _modeChip(icon: Icons.code_rounded, label: "JSON", mode: 'json'),
                ],
              ),
            ),
          ),

          // ── Main Content Area ──────────────────────────────────────────────
          Expanded(
            child: _buildContent(rootNode, selectedNode, controller),
          ),
        ],
      ),
    );
  }

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
            Icon(icon, size: 12, color: isSelected ? Colors.white : RevoTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : RevoTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ComponentNode rootNode,
    ComponentNode? selectedNode,
    VisualBuilderController controller,
  ) {
    if (selectedNode == null) return _noSelectionPlaceholder();

    switch (_activeMode) {
      case 'properties':
        return _buildPropertiesTab(selectedNode, controller);
      case 'events':
        return _buildEventsTab(selectedNode, controller);
      case 'validations':
        return _buildValidationsTab(selectedNode, controller);
      case 'slots':
        return _buildSlotsTab(selectedNode, controller);
      case 'actions':
        return _buildActionsTab(selectedNode, controller);
      case 'json':
        return RevoJsonTab(controller: controller);
      default:
        return _buildPropertiesTab(selectedNode, controller);
    }
  }

  // ── PROPERTIES TAB (Collapsible Accordion Sections) ───────────────────────

  Widget _buildPropertiesTab(ComponentNode selectedNode, VisualBuilderController controller) {
    return Column(
      children: [
        _componentHeader(selectedNode, controller),
        _breadcrumbsHeader(selectedNode, controller),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12.0),
            children: [
              CollapsibleCard(
                icon: Icons.settings_rounded,
                title: "General Configuration",
                initiallyExpanded: true,
                child: RevoGeneralTab(node: selectedNode, controller: controller),
              ),
              CollapsibleCard(
                icon: Icons.palette_rounded,
                title: "Visual Styling & Colors",
                initiallyExpanded: true,
                child: RevoStyleTab(node: selectedNode, controller: controller),
              ),
              CollapsibleCard(
                icon: Icons.devices_rounded,
                title: "Responsive Sizing",
                initiallyExpanded: false,
                child: RevoResponsiveTab(node: selectedNode, controller: controller),
              ),
              CollapsibleCard(
                icon: Icons.link_rounded,
                title: "State & Variable Bindings",
                initiallyExpanded: false,
                child: RevoDataBindingTab(node: selectedNode, controller: controller),
              ),
              CollapsibleCard(
                icon: Icons.motion_photos_on_rounded,
                title: "Micro-Animations Setup",
                initiallyExpanded: false,
                child: RevoAnimationTab(node: selectedNode, controller: controller),
              ),
              CollapsibleCard(
                icon: Icons.lock_outline_rounded,
                title: "Viewing Permissions",
                initiallyExpanded: false,
                child: RevoPermissionsTab(node: selectedNode, controller: controller),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── EVENTS TAB (Supported Interaction Triggers list) ──────────────────────

  Widget _buildEventsTab(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);
    final events = meta?.eventsList ?? [];

    return Column(
      children: [
        _componentHeader(selectedNode, controller),
        _breadcrumbsHeader(selectedNode, controller),
        Expanded(
          child: events.isEmpty
              ? _buildNotApplicableState(
                  icon: Icons.flash_off_rounded,
                  title: "No Events Available",
                  description: "This component is purely presentational and does not capture any user events or interactions.",
                )
              : ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                      child: Text(
                        "Supported Trigger Events",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                      ),
                    ),
                    ...events.map((event) {
                      final bool hasPipeline = selectedNode.actions.any((a) => a.event == event);
                      return Card(
                        color: RevoTheme.cardBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: RevoTheme.cardBorder),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeEventTrigger = event;
                              _activeMode = 'actions';
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: hasPipeline ? const Color(0x1110B981) : const Color(0x0C5B4FCF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.flash_on_rounded,
                                    size: 16,
                                    color: hasPipeline ? const Color(0xFF10B981) : const Color(0xFF5B4FCF),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event,
                                        style: GoogleFonts.sourceCodePro(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: RevoTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasPipeline ? "Action pipeline is configured" : "No pipeline mapped yet",
                                        style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hasPipeline ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    hasPipeline ? "Active" : "Empty",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: hasPipeline ? const Color(0xFF10B981) : RevoTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, size: 16, color: RevoTheme.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  // ── VALIDATIONS TAB (Form Field Constraints schema) ───────────────────────

  Widget _buildValidationsTab(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);
    final validations = meta?.validationsList ?? [];

    return Column(
      children: [
        _componentHeader(selectedNode, controller),
        _breadcrumbsHeader(selectedNode, controller),
        Expanded(
          child: validations.isEmpty
              ? _buildNotApplicableState(
                  icon: Icons.gpp_bad_rounded,
                  title: "Validation Not Applicable",
                  description: "This component is not a form input field and does not accept user text. Mapped validations are not required.",
                )
              : RevoValidationTab(node: selectedNode, controller: controller),
        ),
      ],
    );
  }

  // ── SLOTS TAB (Visual structural layout positions dashboard) ──────────────

  Widget _buildSlotsTab(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);
    final slots = meta?.slotNames ?? [];

    return Column(
      children: [
        _componentHeader(selectedNode, controller),
        _breadcrumbsHeader(selectedNode, controller),
        Expanded(
          child: slots.isEmpty
              ? _buildNotApplicableState(
                  icon: Icons.layers_clear_rounded,
                  title: "No Named Slots",
                  description: "This component aligns child items in a flat linear list (e.g. Column, Row, Stack) rather than designated structural positions.",
                )
              : ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 12.0),
                      child: Text(
                        "Structural Layout Slots",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                      ),
                    ),
                    ...slots.map((slotName) {
                      final ComponentNode? slotChild = selectedNode.getSlotChild(slotName);
                      final bool isFilled = slotChild != null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: RevoTheme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: RevoTheme.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Slot Label Header
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: RevoTheme.sidebarBackground,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                                border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.dashboard_customize_rounded, size: 12, color: Color(0xFF5B4FCF)),
                                  const SizedBox(width: 6),
                                  Text(
                                    slotName,
                                    style: GoogleFonts.sourceCodePro(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5B4FCF)),
                                  ),
                                  const Spacer(),
                                  Text(
                                    isFilled ? "FILLED" : "EMPTY",
                                    style: GoogleFonts.inter(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isFilled ? const Color(0xFF10B981) : Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Slot Child Display
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: isFilled
                                  ? Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Color(0x0C5B4FCF), shape: BoxShape.circle),
                                          child: Icon(
                                            ComponentRegistry.getByType(slotChild.type)?.icon ?? Icons.settings_rounded,
                                            size: 14,
                                            color: const Color(0xFF5B4FCF),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                slotChild.type,
                                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                                              ),
                                              Text(
                                                slotChild.id,
                                                style: GoogleFonts.sourceCodePro(fontSize: 9, color: RevoTheme.textSecondary),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Edit Child Button
                                        IconButton(
                                          tooltip: "Select and Configure Child",
                                          icon: const Icon(Icons.arrow_circle_right_outlined, size: 16, color: Color(0xFF5B4FCF)),
                                          onPressed: () => controller.selectNode(slotChild),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        const SizedBox(width: 4),
                                        // Delete Child Button
                                        IconButton(
                                          tooltip: "Delete Component",
                                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                          onPressed: () => controller.deleteNode(slotChild.id),
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ],
                                    )
                                  : Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: RevoTheme.cardBorder.withValues(alpha: 0.5), style: BorderStyle.none),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: CustomPaint(
                                          painter: DashRectPainter(color: RevoTheme.textSecondary.withValues(alpha: 0.3)),
                                          child: Center(
                                            child: Text(
                                              "Drag & Drop component here",
                                              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  // ── ACTIONS TAB (Dynamic Trigger Action Flow step editor) ─────────────────

  Widget _buildActionsTab(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);
    final events = meta?.eventsList ?? [];

    final String activeTrig = _activeEventTrigger ?? (events.isNotEmpty ? events.first : 'onTap');

    return Column(
      children: [
        _componentHeader(selectedNode, controller),
        _breadcrumbsHeader(selectedNode, controller),
        if (events.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: RevoTheme.sidebarBackground,
            child: Row(
              children: [
                Text(
                  "Event Trigger: ",
                  style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: events.contains(activeTrig) ? activeTrig : events.first,
                        dropdownColor: RevoTheme.sidebarBackground,
                        style: GoogleFonts.sourceCodePro(color: const Color(0xFF5B4FCF), fontSize: 10, fontWeight: FontWeight.bold),
                        items: events.map((ev) => DropdownMenuItem(value: ev, child: Text("ON ${ev.toUpperCase()}"))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _activeEventTrigger = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RevoActionsFlowView(
            selectedNode: selectedNode,
            controller: controller,
            activeTrigger: activeTrig,
          ),
        ),
      ],
    );
  }

  // ── INNER UI HEADERS ───────────────────────────────────────────────────────

  Widget _breadcrumbsHeader(ComponentNode selectedNode, VisualBuilderController controller) {
    final rootNode = ref.read(builderRootNodeProvider);
    final breadcrumbs = _getBreadcrumbs(rootNode, selectedNode, controller);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: breadcrumbs.map((node) {
            final isLast = node.id == selectedNode.id;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isLast ? null : () => controller.selectNode(node),
                  child: Text(
                    node.type,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                      color: isLast ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                    ),
                  ),
                ),
                if (!isLast)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 12,
                    color: RevoTheme.textSecondary.withValues(alpha: 0.5),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  List<ComponentNode> _getBreadcrumbs(ComponentNode root, ComponentNode target, VisualBuilderController controller) {
    final List<ComponentNode> path = [];
    ComponentNode? current = target;
    while (current != null) {
      path.insert(0, current);
      if (current.id == root.id) break;
      current = controller.findParentNode(current.id);
    }
    return path;
  }

  Widget _componentHeader(ComponentNode selectedNode, VisualBuilderController controller) {
    final meta = ComponentRegistry.getByType(selectedNode.type);

    return Container(
      padding: const EdgeInsets.all(12.0),
      color: RevoTheme.sidebarBackground,
      child: Row(
        children: [
          Icon(meta?.icon ?? Icons.settings_rounded, color: const Color(0xFF5B4FCF), size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedNode.type,
                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                ),
                Text(
                  "ID: ${selectedNode.id}",
                  style: GoogleFonts.inter(fontSize: 9, color: RevoTheme.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Save as Reusable Component",
            icon: const Icon(Icons.star_border_rounded, size: 16, color: Color(0xFF5B4FCF)),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () => _showSaveReusableDialog(context, selectedNode, controller),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: "Duplicate Component",
            icon: const Icon(Icons.copy_all_rounded, size: 14, color: Color(0xFF5B4FCF)),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            onPressed: () {
              controller.duplicateNode(selectedNode.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Component duplicated!"), duration: Duration(seconds: 1)),
              );
            },
          ),
          if (selectedNode.id != ref.read(builderRootNodeProvider).id) ...[
            const SizedBox(width: 4),
            IconButton(
              tooltip: "Delete Component",
              icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
              padding: const EdgeInsets.all(4),
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

  void _showSaveReusableDialog(BuildContext context, ComponentNode selectedNode, VisualBuilderController controller) {
    final nameCtrl = TextEditingController(text: "Custom ${selectedNode.type}");
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RevoTheme.sidebarBackground,
        title: Text("Save as Reusable Component", style: GoogleFonts.outfit(color: RevoTheme.textPrimary, fontSize: 13)),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: "Component Label / Name",
            hintText: "e.g. Customer Card",
          ),
          style: TextStyle(color: RevoTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5B4FCF)),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                controller.saveAsReusableComponent(selectedNode.id, nameCtrl.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Saved custom component: ${nameCtrl.text}")),
                );
              }
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── DECORATIVE NOT-APPLICABLE EMPTY STATE GRAPHICS ────────────────────────

  Widget _buildNotApplicableState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0x085B4FCF), shape: BoxShape.circle),
              child: Icon(icon, color: const Color(0xFF5B4FCF).withValues(alpha: 0.5), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(fontSize: 10, color: RevoTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _noSelectionPlaceholder() {
    return Center(
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
    );
  }
}

// ── CUSTOM COLLAPSIBLE ACCORDION CARD WIDGET ────────────────────────────────

class CollapsibleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const CollapsibleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Row(
                children: [
                  Icon(widget.icon, size: 14, color: const Color(0xFF5B4FCF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: RevoTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
              child: widget.child,
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM DASHED RECTANGLE PAINTER ──────────────────────────────────────────

class DashRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashRectPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    ));

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2.0;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
