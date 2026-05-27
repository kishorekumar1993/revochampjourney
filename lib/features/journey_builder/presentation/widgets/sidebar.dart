import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class RevoSidebar extends StatelessWidget {
  final String activeMenu;
  final ValueChanged<String> onMenuChanged;
  final bool isCollapsed;

  const RevoSidebar({
    super.key,
    required this.activeMenu,
    required this.onMenuChanged,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'id': 'dashboard', 'label': 'Dashboard', 'icon': Icons.space_dashboard_outlined},
      {'id': 'journeys', 'label': 'Journeys', 'icon': Icons.alt_route_rounded},
      {'id': 'templates', 'label': 'Templates', 'icon': Icons.layers_outlined},
      {'id': 'runs', 'label': 'Runs', 'icon': Icons.play_circle_outline_rounded},
      {'id': 'analytics', 'label': 'Analytics', 'icon': Icons.analytics_outlined},
      {'id': 'approvals', 'label': 'Approvals', 'icon': Icons.rule_folder_outlined},
      {'id': 'users', 'label': 'Users', 'icon': Icons.people_outline_rounded},
      {'id': 'settings', 'label': 'Settings', 'icon': Icons.settings_outlined},
      {'id': 'api_hub', 'label': 'API Hub', 'icon': Icons.api_outlined},
      {'id': 'audit_logs', 'label': 'Audit Logs', 'icon': Icons.history_edu_outlined},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCollapsed ? 76 : 250,
      color: RevoTheme.sidebarBackground,
      child: Column(
        children: [
          // Logo & Brand
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 24,
              vertical: 32,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RevoTheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 22),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "RevoJourney",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                final isSelected = activeMenu == item['id'];
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 8 : 16,
                    vertical: 4,
                  ),
                  child: Tooltip(
                    message: isCollapsed ? item['label'] as String : "",
                    child: InkWell(
                      onTap: () => onMenuChanged(item['id'] as String),
                      borderRadius: BorderRadius.circular(10),
                      child: Ink(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 12 : 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? RevoTheme.primary.withValues(alpha:0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected 
                              ? Border.all(color: RevoTheme.primary.withValues(alpha:0.3)) 
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            Icon(
                              item['icon'] as IconData,
                              color: isSelected ? RevoTheme.primaryLight : RevoTheme.textSecondary,
                              size: 20,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item['label'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'Inter', 
                                    color: isSelected ? RevoTheme.textPrimary : RevoTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // User Profile Card
          Container(
            margin: EdgeInsets.all(isCollapsed ? 8 : 16),
            padding: EdgeInsets.all(isCollapsed ? 8 : 12),
            decoration: BoxDecoration(
              color: const Color(0x0CFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x11FFFFFF)),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: RevoTheme.primary,
                  radius: 18,
                  child: Text(
                    "AU",
                    style: TextStyle(fontFamily: 'Inter', 
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Admin User",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: RevoTheme.textPrimary,
                          ),
                        ),
                        Text(
                          "Super Admin",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 11,
                            color: RevoTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: RevoTheme.textSecondary, size: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
