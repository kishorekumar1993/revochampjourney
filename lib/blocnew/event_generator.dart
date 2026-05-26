// // lib/bloc/generators/event/event_generator.dart

// class EventGenerator {
//   /// [featureName] – PascalCase feature name (e.g., "UserjourneyForm")
//   /// [fieldNames] – list of human‑readable field keys (e.g., ['postTitle', 'firstName'])
//   /// [hasAsyncDropdown] – whether the form has async dropdowns (triggers LoadDataEvent)
//   /// [hasSubmit] – whether to generate SubmitEvent (default false)
//   EventGenerator({
//     required this.featureName,
//     required this.fieldNames,
//     this.hasAsyncDropdown = false,
//     this.hasSubmit = false,
//   });

//   final String featureName;
//   final List<String> fieldNames;
//   final bool hasAsyncDropdown;
//   final bool hasSubmit;

//   String generate() {
//     final buf = StringBuffer();
//     buf.writeln("import 'package:equatable/equatable.dart';");
//     buf.writeln();

//     // ─── ComponentKeys (string constants) ───────────────────────────────
//     buf.writeln('/// Compile-time field-key registry for the $featureName feature.');
//     buf.writeln('abstract final class ${featureName}ComponentKeys {');
//     for (final f in fieldNames) {
//       buf.writeln("  static const $f = '$f';");
//     }
//     buf.writeln('}');
//     buf.writeln();

//     // ─── Sealed base event class ───────────────────────────────────────
//     buf.writeln('sealed class ${featureName}Event extends Equatable {');
//     buf.writeln('  const ${featureName}Event();');
//     buf.writeln('}');
//     buf.writeln();

//     // ─── Field changed event (matches BLoC generator) ──────────────────
//     buf.writeln('/// Fired when a single form field changes.');
//     buf.writeln('class ${featureName}FieldChangedEvent extends ${featureName}Event {');
//     buf.writeln('  final String fieldName;');
//     buf.writeln('  final dynamic value;');
//     buf.writeln('  const ${featureName}FieldChangedEvent({');
//     buf.writeln('    required this.fieldName,');
//     buf.writeln('    required this.value,');
//     buf.writeln('  });');
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [fieldName, value];');
//     buf.writeln('}');
//     buf.writeln();

//     // ─── Batch update event ────────────────────────────────────────────
//     buf.writeln('/// Updates multiple fields at once (e.g., API prefill).');
//     buf.writeln('class ${featureName}BatchUpdateEvent extends ${featureName}Event {');
//     buf.writeln('  final Map<String, dynamic> updates;');
//     buf.writeln('  const ${featureName}BatchUpdateEvent({');
//     buf.writeln('    required this.updates,');
//     buf.writeln('  });');
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => [updates];');
//     buf.writeln('}');
//     buf.writeln();

//     // ─── Load data event (only if async dropdowns exist) ────────────────
//     if (hasAsyncDropdown) {
//       buf.writeln('/// Loads remote dropdown data for the $featureName screen.');
//       buf.writeln('class Load${featureName}DataEvent extends ${featureName}Event {');
//       buf.writeln('  const Load${featureName}DataEvent();');
//       buf.writeln('  @override');
//       buf.writeln('  List<Object?> get props => const [];');
//       buf.writeln('}');
//       buf.writeln();
//     }

//     // ─── Submit event (only if hasSubmit = true) ────────────────────────
//     if (hasSubmit) {
//       buf.writeln('/// Submits the $featureName form.');
//       buf.writeln('class Submit${featureName}Event extends ${featureName}Event {');
//       buf.writeln('  const Submit${featureName}Event();');
//       buf.writeln('  @override');
//       buf.writeln('  List<Object?> get props => const [];');
//       buf.writeln('}');
//       buf.writeln();
//     }

//     // ─── Reset event (always generated) ─────────────────────────────────
//     buf.writeln('/// Resets the $featureName form to its initial state.');
//     buf.writeln('class Reset${featureName}Event extends ${featureName}Event {');
//     buf.writeln('  const Reset${featureName}Event();');
//     buf.writeln('  @override');
//     buf.writeln('  List<Object?> get props => const [];');
//     buf.writeln('}');

//     return buf.toString();
//   }
// }