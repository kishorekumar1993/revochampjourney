import 'journey_field.dart';

List<String>? parseStringList(dynamic value) {
  if (value is! List) return null;
  return value.map((e) => e.toString()).toList();
}

List<Map<String, dynamic>>? parseMapList(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<Map<String, String>>? parseStringMapList(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => {'key': e['key']?.toString() ?? '', 'value': e['value']?.toString() ?? ''}).toList();
}

List<JourneyField>? parseNestedFields(dynamic value) {
  if (value is! List) return null;
  return value.whereType<Map>().map((e) => JourneyField.fromJson(Map<String, dynamic>.from(e))).toList();
}

int? parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
