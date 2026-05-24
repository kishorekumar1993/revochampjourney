// lib/bloc/generators/event/event_generator.dart
//
// Generates the feature-specific ComponentEvent file:
//   - ComponentKeys  (compile-time string constants)
//   - ComponentUpdatedEvent<T>  (single generic field-change event)
//   - BatchComponentUpdatedEvent
//   - Feature lifecycle events  (Load…, Submit…, Reset…)

import 'package:revojourneytryone/blocnew/field_schema.dart';


class EventGenerator {
  EventGenerator({
    required this.featureName,
    required this.fields,
    this.hasAsyncDropdown = false,
  });

  final String featureName;
  final List<FieldSchema> fields;
  final bool hasAsyncDropdown;

  String generate() {
    final buf = StringBuffer();
    buf.writeln("import 'package:equatable/equatable.dart';");
    buf.writeln();

    // ComponentKeys
    buf.writeln('/// Compile-time field-key registry for the $featureName feature.');
    buf.writeln('abstract final class ${featureName}ComponentKeys {');
    for (final f in fields) {
      buf.writeln("  static const ${f.fieldName} = '${f.fieldName}';");
    }
    buf.writeln('}');
    buf.writeln();

    // Sealed base
    buf.writeln('sealed class ${featureName}Event extends Equatable {');
    buf.writeln('  const ${featureName}Event();');
    buf.writeln('}');
    buf.writeln();

    // Generic field-change event
    buf.writeln('/// Fired by any field widget when its value changes.');
    buf.writeln('/// [T] is inferred from [value] at the call site.');
    buf.writeln('final class ComponentUpdatedEvent<T> extends ${featureName}Event {');
    buf.writeln('  const ComponentUpdatedEvent(this.componentKey, this.value,');
    buf.writeln('      {this.metadata = const {}});');
    buf.writeln('  final String componentKey;');
    buf.writeln('  final T value;');
    buf.writeln('  final Map<String, dynamic> metadata;');
    buf.writeln('  @override List<Object?> get props => [componentKey, value, metadata];');
    buf.writeln('}');
    buf.writeln();

    // Batch event
    buf.writeln('/// Fires multiple field updates in one state emission (API prefill, undo/redo).');
    buf.writeln('final class BatchComponentUpdatedEvent extends ${featureName}Event {');
    buf.writeln('  const BatchComponentUpdatedEvent(this.updates, {this.metadata = const {}});');
    buf.writeln('  final Map<String, dynamic> updates;');
    buf.writeln('  final Map<String, dynamic> metadata;');
    buf.writeln('  @override List<Object?> get props => [updates, metadata];');
    buf.writeln('}');
    buf.writeln();

    // Lifecycle: load dropdown data
    if (hasAsyncDropdown) {
      buf.writeln('/// Loads remote dropdown data for the $featureName screen.');
      buf.writeln('final class Load${featureName}DataEvent extends ${featureName}Event {');
      buf.writeln('  const Load${featureName}DataEvent();');
      buf.writeln('  @override List<Object?> get props => const [];');
      buf.writeln('}');
      buf.writeln();
    }

    // Submit
    buf.writeln('/// Submits the $featureName form.');
    buf.writeln('final class Submit${featureName}FormEvent extends ${featureName}Event {');
    buf.writeln('  const Submit${featureName}FormEvent();');
    buf.writeln('  @override List<Object?> get props => const [];');
    buf.writeln('}');
    buf.writeln();

    // Reset
    buf.writeln('/// Resets the $featureName form to its initial state.');
    buf.writeln('final class Reset${featureName}FormEvent extends ${featureName}Event {');
    buf.writeln('  const Reset${featureName}FormEvent();');
    buf.writeln('  @override List<Object?> get props => const [];');
    buf.writeln('}');

    return buf.toString();
  }
}
