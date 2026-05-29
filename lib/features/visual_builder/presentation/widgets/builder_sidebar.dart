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
      {'id': 'widgets', 'tooltip': 'UI Components', 'icon': Icons.widgets_outlined},
      {'id': 'tree', 'tooltip': 'Component Tree', 'icon': Icons.account_tree_outlined},
      {'id': 'pages', 'tooltip': 'Journey Steps', 'icon': Icons.layers_outlined},
      {'id': 'theme', 'tooltip': 'Theme Studio', 'icon': Icons.palette_outlined},
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
          ...menuItems.map((item) {
            final isSelected = activeTab == item['id'];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Tooltip(
                message: item['tooltip'] as String,
                child: IconButton(
                  icon: Icon(item['icon'] as IconData),
                  color: isSelected ? const Color(0xFF5B4FCF) : RevoTheme.textSecondary,
                  onPressed: () => onTabChanged(item['id'] as String),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
