import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/builder_mode.dart';
import '../provider/builder_mode_provider.dart';
import '../widgets/builder_mode_switcher.dart';
import '../widgets/preview_panel.dart';
import '../widgets/code_preview_panel.dart';
import '../../../journey_builder/presentation/widgets/canvas_panel/canvas_panel_main.dart';
import '../../../journey_builder/presentation/widgets/properties_panel/properties_panel_main.dart';
import '../../../journey_builder/presentation/widgets/steps_panel.dart';
import '../../../visual_builder/presentation/screen/visual_builder_screen.dart';

class BuilderWorkspaceScreen extends ConsumerWidget {
  const BuilderWorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(builderModeProvider);
    final showSteps = ref.watch(showStepsPanelProvider);
    final showProps = ref.watch(showPropertiesPanelProvider);

    return Column(
      children: [
        const RevoBuilderModeSwitcher(),
        Expanded(
          child: _buildWorkspaceContent(activeMode, showSteps, showProps),
        ),
      ],
    );
  }

  Widget _buildWorkspaceContent(BuilderMode mode, bool showSteps, bool showProps) {
    switch (mode) {
      case BuilderMode.journey:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showSteps) const RevoStepsPanel(),
            const Expanded(child: RevoCanvasPanel()),
            if (showProps) const RevoPropertiesPanel(),
          ],
        );
      case BuilderMode.visual:
        return const VisualBuilderScreen();
      case BuilderMode.preview:
        return const RevoPreviewPanel();
      case BuilderMode.code:
        return const RevoCodePreviewPanel();
    }
  }
}
