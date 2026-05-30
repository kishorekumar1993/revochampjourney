import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

class RunnerTimelineWidget extends StatelessWidget {
  final JourneyField field;

  const RunnerTimelineWidget({
    super.key,
    required this.field,
  });

  Map<String, dynamic> _compConfig(JourneyField f) {
    return Map<String, dynamic>.from(f.componentConfig ?? {});
  }

  List<Map<String, dynamic>> _cfgList(
    JourneyField f,
    String key,
    List<Map<String, dynamic>> fallback,
  ) {
    final v = _compConfig(f)[key];
    if (v is List) {
      final p = v
          .map((i) => i is Map ? Map<String, dynamic>.from(i) : <String, dynamic>{})
          .where((i) => i.isNotEmpty)
          .toList();
      if (p.isNotEmpty) return p;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final items = _cfgList(field, 'items', const [
      {
        'title': 'Started',
        'description': 'Journey started',
        'status': 'completed',
      },
      {'title': 'Current', 'description': 'Current step', 'status': 'active'},
      {'title': 'Completed', 'description': 'Final state', 'status': 'pending'},
    ]);

    Color sc(String? s) => s == 'completed'
        ? RunnerTheme.success
        : s == 'active'
            ? RunnerTheme.brand
            : RunnerTheme.textLight;

    return Container(
      decoration: BoxDecoration(
        color: RunnerTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RunnerTheme.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: RunnerTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map(
                (e) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: sc(e.value['status']?.toString()),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (e.key < items.length - 1)
                          Container(width: 2, height: 34, color: RunnerTheme.border),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.value['title']?.toString() ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: RunnerTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.value['description']?.toString() ?? '',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: RunnerTheme.textMid,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
