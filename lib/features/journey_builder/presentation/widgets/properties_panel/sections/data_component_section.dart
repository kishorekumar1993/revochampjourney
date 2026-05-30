import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:revojourneytryone/features/journey_builder/domain/entities/journey_models.dart';
import 'data_component_splits/table_grid_properties.dart';
import 'data_component_splits/repeater_properties.dart';
import 'data_component_splits/timeline_properties.dart';

class DataComponentSection extends ConsumerWidget {
  final JourneyField field;
  final String activeStepId;

  const DataComponentSection({
    super.key,
    required this.field,
    required this.activeStepId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (field.type) {
      case 'table_grid':
        return TableGridProperties(field: field, activeStepId: activeStepId);
      case 'repeater':
        return RepeaterProperties(field: field, activeStepId: activeStepId);
      case 'timeline':
        return TimelineProperties(field: field, activeStepId: activeStepId);
      default:
        return const SizedBox.shrink();
    }
  }
}
