import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/component_engine/models/component_node.dart';
import '../../../../core/component_engine/registry/component_registry.dart';
import '../../application/visual_builder_controller.dart';
import '../../application/studio_providers.dart';

class RevoComponentPalette extends ConsumerStatefulWidget {
  const RevoComponentPalette({super.key});

  @override
  ConsumerState<RevoComponentPalette> createState() => _RevoComponentPaletteState();
}

class _RevoComponentPaletteState extends ConsumerState<RevoComponentPalette> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final reusableComponents = ref.watch(builderReusableComponentsProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    // Group components by category
    final Map<ComponentCategory, List<ComponentMetadata>> grouped = {};
    for (final cat in ComponentCategory.values) {
      grouped[cat] = [];
    }

    for (final comp in ComponentRegistry.components) {
      if (_searchQuery.isNotEmpty &&
          !comp.label.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }
      grouped[comp.category]?.add(comp);
    }

    // Filter reusable components by search
    final filteredReusable = reusableComponents.where((comp) {
      if (_searchQuery.isEmpty) return true;
      final name = comp.displayName ?? comp.type;
      return name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        children: [
          // Palette Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "UI Palette",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RevoTheme.textPrimary,
                      ),
                    ),
                    const Icon(Icons.apps_rounded, color: Color(0xFF5B4FCF), size: 18),
                  ],
                ),
                const SizedBox(height: 12),
                // Search bar
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search components...",
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary),
                    prefixIcon: Icon(Icons.search_rounded, size: 16, color: RevoTheme.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: RevoTheme.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: RevoTheme.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: RevoTheme.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF5B4FCF)),
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 13, color: RevoTheme.textPrimary),
                ),
              ],
            ),
          ),

          // Palette Categories List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Reusable Components Category (Always shown at the top)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 8.0, left: 4),
                  child: Text(
                    "REUSABLE COMPONENTS 🌟",
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B4FCF),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                if (filteredReusable.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: filteredReusable.length,
                    itemBuilder: (context, index) {
                      final comp = filteredReusable[index];
                      return _buildReusablePaletteItem(comp, controller);
                    },
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: RevoTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RevoTheme.cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded, color: Color(0xFF5B4FCF), size: 20),
                        const SizedBox(height: 6),
                        Text(
                          "No custom components yet",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: RevoTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Select any component on the canvas and click the Star 🌟 button in the properties panel to save it.",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            color: RevoTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Core categories
                ...ComponentCategory.values.map((cat) {
                  final list = grouped[cat] ?? [];
                  if (list.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4),
                        child: Text(
                          cat.name.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF5B4FCF),
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final comp = list[index];
                          return _buildPaletteItem(comp);
                        },
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteItem(ComponentMetadata comp) {
    return Draggable<String>(
      data: comp.type,
      onDragStarted: () => ref.read(canvasIsDraggingProvider.notifier).state = true,
      onDragEnd: (_) => ref.read(canvasIsDraggingProvider.notifier).state = false,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 110,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF5B4FCF).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(comp.icon, color: Colors.white, size: 18),
              const SizedBox(height: 4),
              Text(
                comp.label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildItemCard(comp.label, comp.icon),
      ),
      child: _buildItemCard(comp.label, comp.icon),
    );
  }

  Widget _buildReusablePaletteItem(ComponentNode comp, VisualBuilderController controller) {
    final label = comp.displayName ?? comp.type;
    return Draggable<String>(
      data: 'reusable_${comp.id}',
      onDragStarted: () => ref.read(canvasIsDraggingProvider.notifier).state = true,
      onDragEnd: (_) => ref.read(canvasIsDraggingProvider.notifier).state = false,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 110,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF5B4FCF).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.widgets_rounded, color: Colors.white, size: 18),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildReusableItemCard(label, controller, comp.id),
      ),
      child: _buildReusableItemCard(label, controller, comp.id),
    );
  }

  Widget _buildItemCard(String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: RevoTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RevoTheme.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0x0C5B4FCF),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: RevoTheme.textSecondary,
                  size: 20,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RevoTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReusableItemCard(String label, VisualBuilderController controller, String compId) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x335B4FCF)),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.widgets_rounded,
                    color: Color(0xFF5B4FCF),
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF5B4FCF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () {
                controller.deleteReusableComponent(compId);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Removed custom component: $label")),
                );
              },
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.redAccent,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
