import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'package:revojourneytryone/features/journey_builder/application/controllers/journey_validation_manager.dart';
import 'package:revojourneytryone/features/journey_runner/presentation/screens/runner_screen/runner_theme.dart';

class RunnerNestedWidget extends StatelessWidget {
  final JourneyField field;
  final Map<String, dynamic> values;
  final IconData icon;
  final List<Widget> Function(List<JourneyField>, Map<String, dynamic>) buildFields;

  const RunnerNestedWidget({
    super.key,
    required this.field,
    required this.values,
    required this.icon,
    required this.buildFields,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: RunnerTheme.brandSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: RunnerTheme.brand),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RunnerTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          if ((field.nestedFields ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            ...buildFields(field.nestedFields!, values),
          ],
        ],
      ),
    );
  }
}

class RunnerNestedRowWidget extends StatelessWidget {
  final JourneyField field;
  final Map<String, dynamic> values;
  final Widget Function(JourneyField, Map<String, dynamic>) buildField;

  const RunnerNestedRowWidget({
    super.key,
    required this.field,
    required this.values,
    required this.buildField,
  });

  @override
  Widget build(BuildContext context) {
    final ch = (field.nestedFields ?? <JourneyField>[])
        .where((c) => EngineHelper.isFieldVisible(c, values))
        .toList();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: ch.map((c) {
        final span = int.tryParse(c.componentConfig?['colSpan']?.toString() ?? '') ?? 12;
        final w = MediaQuery.of(context).size.width;
        return SizedBox(
          width: w > 760 ? ((w - 220) * (span.clamp(1, 12) / 12)) : double.infinity,
          child: buildField(c, values),
        );
      }).toList(),
    );
  }
}

class RunnerTabsWidget extends StatelessWidget {
  final JourneyField field;
  final Map<String, dynamic> values;
  final List<Widget> Function(List<JourneyField>, Map<String, dynamic>) buildFields;

  const RunnerTabsWidget({
    super.key,
    required this.field,
    required this.values,
    required this.buildFields,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = field.nestedFields ?? <JourneyField>[];
    if (tabs.isEmpty) {
      return RunnerNestedWidget(
        field: field,
        values: values,
        icon: Icons.tab_rounded,
        buildFields: buildFields,
      );
    }
    return DefaultTabController(
      length: tabs.length,
      child: Container(
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
            const SizedBox(height: 10),
            TabBar(
              isScrollable: true,
              labelColor: RunnerTheme.brand,
              unselectedLabelColor: RunnerTheme.textMid,
              indicatorColor: RunnerTheme.brand,
              labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: tabs.map((t) => Tab(text: t.label)).toList(),
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: tabs
                    .map(
                      (t) => SingleChildScrollView(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: buildFields(t.nestedFields ?? [], values),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
