import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/theme.dart';
import '../../../application/visual_builder_controller.dart';

class CanvasToolbar extends ConsumerWidget {
  const CanvasToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canvasSize = ref.watch(builderCanvasSizeProvider);
    final history = ref.watch(builderHistoryProvider);
    final isDesignMode = ref.watch(builderDesignModeProvider);
    final controller = ref.read(visualBuilderProvider.notifier);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(bottom: BorderSide(color: RevoTheme.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Device Presets
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.phone_android_rounded,
                tooltip: 'Phone (Pixel 7 Pro)',
                isSelected: canvasSize.width == 412,
                onPressed: () => controller.setCanvasSize(412, 915),
              ),
              _ToolbarIconButton(
                icon: Icons.tablet_rounded,
                tooltip: 'Tablet (iPad Pro)',
                isSelected: canvasSize.width == 1024,
                onPressed: () => controller.setCanvasSize(1024, 1366),
              ),
              _ToolbarIconButton(
                icon: Icons.laptop_chromebook_rounded,
                tooltip: 'Desktop (Web App)',
                isSelected: canvasSize.width == 1440,
                onPressed: () => controller.setCanvasSize(1440, 900),
              ),
              const SizedBox(width: 8),
              _ToolbarIconButton(
                icon: Icons.screen_rotation_rounded,
                tooltip: 'Rotate Orientation',
                onPressed: () => controller.toggleOrientation(),
              ),
              const SizedBox(width: 12),
              Text(
                '${canvasSize.width.toInt()} x ${canvasSize.height.toInt()}',
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          // Zoom & Scale
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.zoom_out_rounded,
                tooltip: 'Zoom Out',
                onPressed: () => controller.setCanvasScale((canvasSize.scale - 0.1).clamp(0.3, 2.0)),
              ),
              Text(
                '${(canvasSize.scale * 100).toInt()}%',
                style: GoogleFonts.inter(fontSize: 12, color: RevoTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              _ToolbarIconButton(
                icon: Icons.zoom_in_rounded,
                tooltip: 'Zoom In',
                onPressed: () => controller.setCanvasScale((canvasSize.scale + 0.1).clamp(0.3, 2.0)),
              ),
              const SizedBox(width: 8),
              _ToolbarIconButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset Zoom',
                onPressed: () => controller.setCanvasScale(1.0),
              ),
            ],
          ),

          // Undo / Redo + Mode toggle
          Row(
            children: [
              _ToolbarIconButton(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                onPressed: history.canUndo ? () => controller.undo() : null,
              ),
              _ToolbarIconButton(
                icon: Icons.redo_rounded,
                tooltip: 'Redo',
                onPressed: history.canRedo ? () => controller.redo() : null,
              ),
              const SizedBox(width: 16),
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: RevoTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RevoTheme.cardBorder),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _ModeButton(
                      label: 'Design',
                      isSelected: isDesignMode,
                      onPressed: () { if (!isDesignMode) controller.toggleDesignMode(); },
                    ),
                    _ModeButton(
                      label: 'Preview',
                      isSelected: !isDesignMode,
                      onPressed: () { if (isDesignMode) controller.toggleDesignMode(); },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback? onPressed;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    this.isSelected = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: isSelected
            ? const Color(0xFF5B4FCF)
            : onPressed == null
                ? RevoTheme.textSecondary.withValues(alpha: 0.3)
                : RevoTheme.textSecondary,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        splashRadius: 16,
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ModeButton({required this.label, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF5B4FCF) : Colors.transparent,
          foregroundColor: isSelected ? Colors.white : RevoTheme.textSecondary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }
}
