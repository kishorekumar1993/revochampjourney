import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../widgets/component_palette.dart';
import '../widgets/builder_canvas.dart';
import '../widgets/component_tree.dart';
import '../widgets/property_panel.dart';
import '../widgets/builder_sidebar.dart';
import '../widgets/studio_panels.dart';

class VisualBuilderScreen extends ConsumerStatefulWidget {
  const VisualBuilderScreen({super.key});

  @override
  ConsumerState<VisualBuilderScreen> createState() => _VisualBuilderScreenState();
}

class _VisualBuilderScreenState extends ConsumerState<VisualBuilderScreen> {
  String _activeSidebarTab = 'widgets';

  @override
  Widget build(BuildContext context) {
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

          // Center Workspace (Canvas)
          const Expanded(
            child: RevoBuilderCanvas(),
          ),

          // Right Properties Editor Panel
          const RevoPropertyPanel(),
        ],
      ),
    );
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
