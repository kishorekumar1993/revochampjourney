import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';
import '../../../domain/entities/journey_models.dart';


class CanvasToolbox extends StatelessWidget {
  final List<Map<String, dynamic>> componentGroups;
  final ValueChanged<String> onAddField;

  const CanvasToolbox({
    Key? key,
    required this.componentGroups,
    required this.onAddField,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: componentGroups.expand<Widget>((group) {
          final items = group['items'] as List<Map<String, dynamic>>;
          return [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                group['title'] as String,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: RevoTheme.textSecondary,
                ),
              ),
            ),
            ...items.map((item) {
              final type = item['type'] as String;
              return Draggable<String>(
                data: type,
                feedback: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 112,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: RevoTheme.primary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: RevoTheme.primaryLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: RevoTheme.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RevoTheme.cardBorder),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => onAddField(type),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Row(
                        children: [
                          Icon(item['icon'] as IconData, size: 16, color: RevoTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: RevoTheme.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ];
        }).toList(),
      ),
    );
  }
}


class CanvasBottomStats extends StatelessWidget {
  final JourneyStep step;

  // ignore: use_super_parameters
  const CanvasBottomStats({Key? key, required this.step}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = [
      {'label': 'Validations', 'val': '${step.validations.length} Rules', 'icon': Icons.gpp_maybe_rounded, 'color': RevoTheme.warning},
      {'label': 'Conditions', 'val': '${step.conditions.length} Rules', 'icon': Icons.rule_rounded, 'color': RevoTheme.primaryLight},
      {'label': 'API Calls', 'val': '${step.apiCalls.length} Configured', 'icon': Icons.api_rounded, 'color': RevoTheme.accent},
      {'label': 'Actions', 'val': '${step.actions.length} Configured', 'icon': Icons.flash_on_rounded, 'color': RevoTheme.secondary},
    ];

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: RevoTheme.cardBorder, width: 1),
        ),
        color: RevoTheme.sidebarBackground,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats.map((stat) {
            final color = stat['color'] as Color;
            return Container(
              width: 140,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RevoTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: RevoTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(stat['icon'] as IconData, size: 24, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          stat['label'] as String,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: RevoTheme.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stat['val'] as String,
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: RevoTheme.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


