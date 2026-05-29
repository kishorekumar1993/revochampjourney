import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class RevoBuilderSidebar extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const RevoBuilderSidebar({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'id': 'widgets', 'tooltip': 'Components', 'icon': Icons.widgets_outlined},
      {'id': 'tree', 'tooltip': 'Widget Tree', 'icon': Icons.account_tree_outlined},
      {'id': 'pages', 'tooltip': 'Pages/Journey', 'icon': Icons.layers_outlined},
      {'id': 'theme', 'tooltip': 'Theme Studio', 'icon': Icons.palette_outlined},
      {'id': 'api', 'tooltip': 'API Studio', 'icon': Icons.api_outlined},
      {'id': 'db', 'tooltip': 'Database Studio', 'icon': Icons.storage_outlined},
      {'id': 'variables', 'tooltip': 'State Variables', 'icon': Icons.data_object_outlined},
      {'id': 'actions', 'tooltip': 'Action Flow Editor', 'icon': Icons.alt_route_outlined},
      {'id': 'assets', 'tooltip': 'Assets Studio', 'icon': Icons.image_outlined},
      {'id': 'responsive', 'tooltip': 'Responsive Breakpoints', 'icon': Icons.important_devices_outlined},
      {'id': 'code', 'tooltip': 'Generated Code', 'icon': Icons.code_outlined},
      {'id': 'settings', 'tooltip': 'Project Settings', 'icon': Icons.settings_outlined},
    ];

    return Container(
      width: 60,
      decoration: BoxDecoration(
        color: RevoTheme.sidebarBackground,
        border: Border(right: BorderSide(color: RevoTheme.cardBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Sidebar menu items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = activeTab == item['id'];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Tooltip(
                    message: item['tooltip'] as String,
                    child: IconButton(
                      icon: Icon(item['icon'] as IconData),
                      color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                      onPressed: () => onTabChanged(item['id'] as String),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
