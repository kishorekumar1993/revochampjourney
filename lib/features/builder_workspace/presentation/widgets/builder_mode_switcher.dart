import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../journey_builder/presentation/providers/journey_provider.dart';
import '../../domain/builder_mode.dart';
import '../provider/builder_mode_provider.dart';

class RevoBuilderModeSwitcher extends ConsumerWidget {
  const RevoBuilderModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyConfig = ref.watch(journeyConfigProvider);
    final activeMode = ref.watch(builderModeProvider);
    final activeModeNotifier = ref.read(builderModeProvider.notifier);

    final String journeyName = journeyConfig.journeyName.isNotEmpty
        ? journeyConfig.journeyName
        : "Untitled Journey";

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(
          bottom: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Journey Name
          Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: Color(0xFF5B4FCF), size: 18),
              const SizedBox(width: 8),
              Text(
                journeyName,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textPrimary,
                ),
              ),
            ],
          ),

          // Tabs (FlutterFlow / VS Code style segments)
          Container(
            decoration: BoxDecoration(
              color: RevoTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RevoTheme.cardBorder),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(
                  label: "Journey",
                  icon: Icons.account_tree_outlined,
                  isSelected: activeMode == BuilderMode.journey,
                  onPressed: () => activeModeNotifier.state = BuilderMode.journey,
                ),
                _buildTabButton(
                  label: "Visual Design",
                  icon: Icons.auto_awesome_mosaic_outlined,
                  isSelected: activeMode == BuilderMode.visual,
                  onPressed: () => activeModeNotifier.state = BuilderMode.visual,
                ),
                _buildTabButton(
                  label: "Preview",
                  icon: Icons.play_circle_outline_rounded,
                  isSelected: activeMode == BuilderMode.preview,
                  onPressed: () => activeModeNotifier.state = BuilderMode.preview,
                ),
                _buildTabButton(
                  label: "Code",
                  icon: Icons.code_rounded,
                  isSelected: activeMode == BuilderMode.code,
                  onPressed: () => activeModeNotifier.state = BuilderMode.code,
                ),
              ],
            ),
          ),

          // Right Spacer to balance the layout
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 32,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 14,
          color: isSelected ? Colors.white : RevoTheme.textSecondary,
        ),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : RevoTheme.textPrimary,
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}
