/// Standalone CLI runner — simulates BLoC generation for the Motor Insurance
/// journey JSON and prints every generated file path + first 5 lines.
///
/// Run with:  dart run tool/test_bloc_gen.dart
library;

import 'dart:convert';
import '../lib/generators/bloc/generators/bloc_generator.dart';
import '../lib/generators/bloc/generators/screen_generator.dart';
import '../lib/filegegnerator/bloc_files_generator.dart';
import '../lib/filegegnerator/journey_step_codegen.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Motor Insurance Journey JSON (minimal — no dropdowndata / API dropdowns so
// the test stays self-contained and won't import entity files).
// ──────────────────────────────────────────────────────────────────────────────
const String _motorInsuranceJson = r'''
{
  "journeyName": "Motor Insurance Journey",
  "version": "1.0.0",
  "steps": [
    {
      "id": "personal",
      "title": "Personal Details",
      "description": "Please provide your basic information",
      "nextStep": "vehicle",
      "fields": [
        {"id": "fullName",      "label": "Full Name",       "type": "text",     "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter full name"},
        {"id": "dob",           "label": "Date of Birth",   "type": "date",     "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "DD/MM/YYYY"},
        {"id": "mobile",        "label": "Mobile Number",   "type": "phone",    "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter mobile number"},
        {"id": "email",         "label": "Email Address",   "type": "text",     "required": false, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter email address"},
        {"id": "gender",        "label": "Gender",          "type": "radio",    "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "defaultValue": "Male", "options": ["Male","Female","Other"]},
        {"id": "maritalStatus", "label": "Marital Status",  "type": "dropdown", "required": false, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Select marital status", "options": ["Single","Married","Divorced","Widowed"], "useStaticOptions": false},
        {"id": "address",       "label": "Address",         "type": "textarea", "required": false, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter your current address"}
      ],
      "validations": [
        {"type": "required", "field": "fullName", "message": "Full Name is required"},
        {"type": "required", "field": "mobile",   "message": "Mobile number is required"},
        {"type": "required", "field": "dob",      "message": "Date of Birth is required"}
      ],
      "conditions": [
        {"type": "visibleIf", "field": "gender",  "operator": "equals",   "value": "Female"},
        {"type": "enableIf",  "field": "email",   "operator": "contains", "value": "@"}
      ],
      "apiCalls": [
        {"method": "POST", "url": "/api/v1/personal-info", "description": "Save personal details info"}
      ],
      "actions": [
        {"trigger": "onSubmit", "actionType": "apiCall", "details": "Submit personal details"}
      ]
    },
    {
      "id": "vehicle",
      "title": "Vehicle Details",
      "description": "Please provide vehicle information",
      "nextStep": "nominee",
      "fields": [
        {"id": "vehicleNum",   "label": "Vehicle Number",      "type": "text",     "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "e.g. MH-12-AB-1234"},
        {"id": "vehicleMake",  "label": "Make",                "type": "dropdown", "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Select manufacturer", "options": ["Toyota","Honda","Hyundai","Suzuki","Tata"], "useStaticOptions": false},
        {"id": "vehicleModel", "label": "Model",               "type": "text",     "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter vehicle model"},
        {"id": "regYear",      "label": "Registration Year",   "type": "dropdown", "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Select registration year", "options": ["2026","2025","2024","2023","2022","2021","2020"], "useStaticOptions": false}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    },
    {
      "id": "nominee",
      "title": "Nominee Details",
      "description": "Provide nominee description for coverage",
      "nextStep": "documents",
      "fields": [
        {"id": "nomineeName",     "label": "Nominee Full Name", "type": "text",     "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter nominee name"},
        {"id": "nomineeRelation", "label": "Relationship",      "type": "dropdown", "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Select relationship", "options": ["Spouse","Father","Mother","Son","Daughter"], "useStaticOptions": false}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    },
    {
      "id": "documents",
      "title": "Upload Documents",
      "description": "Upload necessary documents",
      "nextStep": "review",
      "fields": [
        {"id": "panDoc",        "label": "PAN Card",        "type": "file", "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false},
        {"id": "drivingLicense","label": "Driving License", "type": "file", "required": true,  "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    },
    {
      "id": "review",
      "title": "Review & Confirm",
      "description": "Review your submitted data",
      "nextStep": "payment",
      "fields": [
        {"id": "termsAccepted", "label": "I accept the policy terms and declarations", "type": "switch", "required": true, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "defaultValue": "false"}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    },
    {
      "id": "payment",
      "title": "Payment",
      "description": "Enter premium payment details",
      "nextStep": "success",
      "fields": [
        {"id": "paymentMethod", "label": "Select Payment Mode", "type": "radio", "required": true, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "defaultValue": "Credit Card", "options": ["Credit Card","Debit Card","UPI","Net Banking"]},
        {"id": "otpVerify",     "label": "Verification Code",   "type": "otp",   "required": true, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false, "placeholder": "Enter 6-digit OTP"}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    },
    {
      "id": "success",
      "title": "Success",
      "description": "Your policy generated successfully!",
      "fields": [
        {"id": "successDiv", "label": "Congratulations! Policy PDF has been sent to your email.", "type": "divider", "required": false, "visible": true, "hidden": false, "disable": false, "readOnly": false, "obscureText": false}
      ],
      "validations": [], "conditions": [], "apiCalls": [], "actions": []
    }
  ]
}
''';

// Also test the "auto-id" pattern from testjson.json
const String _autoIdJson = r'''
{
  "journeyName": "Auto ID Journey",
  "version": "1.0.0",
  "steps": [
    {
      "id": "user_journey",
      "title": "User Journey",
      "description": "Auto-id fields test",
      "fields": [
        {
          "id": "field_1779698673548",
          "label": "Post Title",
          "type": "text",
          "required": true,
          "visible": true,
          "hidden": false,
          "disable": false,
          "readOnly": false,
          "obscureText": false,
          "placeholder": "Enter post title"
        },
        {
          "id": "field_1779698717897",
          "label": "Marital Status",
          "type": "dropdown",
          "required": false,
          "visible": true,
          "hidden": false,
          "disable": false,
          "readOnly": false,
          "obscureText": false,
          "options": ["Single","Married"],
          "useStaticOptions": false
        }
      ],
      "validations": [
        {"type": "required", "field": "field_1779698673548", "message": "Post Title is required"}
      ],
      "conditions": [], "apiCalls": [], "actions": []
    }
  ]
}
''';

void main() {
  print('=' * 70);
  print('BLoC Generator — End-to-End Test');
  print('=' * 70);

  _runTest('Motor Insurance Journey', _motorInsuranceJson);
  _runTest('Auto-ID Fields Journey', _autoIdJson);
}

void _runTest(String name, String jsonStr) {
  print('\n${'─' * 70}');
  print('TEST: $name');
  print('─' * 70);

  final journey = jsonDecode(jsonStr) as Map<String, dynamic>;
  final steps = (journey['steps'] as List).cast<Map<String, dynamic>>();
  final journeyName = journey['journeyName'] as String;
  final ns = _toNamespace(journeyName);

  final allFiles = <String>[];
  bool coreAdded = false;

  for (final step in steps) {
    final fields = (step['fields'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    if (fields.isEmpty) {
      print('  ⚠  Step "${step['id']}" skipped — no fields');
      continue;
    }

    final rawId = step['id'].toString();
    final clean = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final screenName =
        clean.isEmpty ? 'Step' : clean[0].toUpperCase() + clean.substring(1);

    final flatFields = flattenBlocFields(fields);
    final featureName = '${screenName}Form';

    print('\n  📋 Step: $screenName  (${flatFields.length} flat fields)');
    _printFieldMap(flatFields, featureName);

    // Generate bloc files
    final blocResult = BlocGenerator(
      featureName: featureName,
      configList: flatFields,
      stepJson: step,
    ).generateAll();

    for (final e in blocResult.entries) {
      final path =
          'lib/bloc/features/$ns/${screenName.toLowerCase()}/presentation/bloc/${e.key}';
      allFiles.add(path);
      _printFilePreview(path, e.value);
    }

    // Generate screen
    final screenCode = ScreenGenerator(
      featureName: featureName,
      flatFields: flatFields,
      stepJson: step,
      hasSubmit: true,
    ).generate();
    final screenPath =
        'lib/bloc/features/$ns/${screenName.toLowerCase()}/presentation/screens/${_snake(featureName)}_screen.dart';
    allFiles.add(screenPath);
    _printFilePreview(screenPath, screenCode);

    coreAdded = true;
  }

  print('\n  ─── SUMMARY ───');
  print('  Total generated files: ${allFiles.length}');
  for (final f in allFiles) {
    print('    ✓ $f');
  }
}

void _printFieldMap(List<Map<String, dynamic>> fields, String featureName) {
  for (final f in fields) {
    final id = f['id']?.toString() ?? '';
    final label = f['label']?.toString() ?? '';
    final type = f['type']?.toString() ?? '';
    final dartKey = _computeFieldName(f);
    final isAutoId = RegExp(r'^field_\d+$').hasMatch(id);
    final note = isAutoId ? ' ← auto-id → label used' : '';
    print('    field: id="$id" label="$label" type="$type"  → Dart key: "$dartKey"$note');
  }
}

void _printFilePreview(String path, String content) {
  final lines = content.split('\n');
  final preview = lines.take(6).join('\n');
  print('\n  📄 $path');
  print('     ${preview.replaceAll('\n', '\n     ')}');
  if (lines.length > 6) print('     ... (${lines.length} lines total)');
}

// ── Helpers matching generator logic ─────────────────────────────────────────

bool _isAutoId(String? id) {
  if (id == null) return true;
  return RegExp(r'^field_\d+$').hasMatch(id.trim());
}

String _computeFieldName(Map<String, dynamic> f) {
  final id = f['id']?.toString().trim();
  final label = (f['label'] ?? f['fieldId'] ?? 'field').toString().trim();
  if (_isAutoId(id)) return _labelToCamel(label);
  final raw = (id ?? label);
  final n = raw.replaceAll(RegExp(r'\s+'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}

String _labelToCamel(String label) {
  final parts = label.trim().split(RegExp(r'[\s_\-]+'));
  if (parts.isEmpty) return 'field';
  final first = parts.first;
  final rest = parts.skip(1).map((p) {
    if (p.isEmpty) return '';
    return p[0].toUpperCase() + p.substring(1);
  }).join();
  final camel = first[0].toLowerCase() + first.substring(1) + rest;
  final n = camel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  return n.isEmpty ? 'field' : n[0].toLowerCase() + n.substring(1);
}

String _toNamespace(String name) {
  final cleaned = name
      .replaceAll(RegExp(r'\bjourney\b', caseSensitive: false), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9\s_\-]'), '')
      .trim();
  if (cleaned.isEmpty) return 'journey';
  final parts = cleaned
      .split(RegExp(r'[\s_\-]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'journey';
  return parts.first.toLowerCase() +
      parts
          .skip(1)
          .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
          .join();
}

String _snake(String s) {
  if (s.isEmpty) return s;
  final out =
      s.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
  return out.startsWith('_') ? out.substring(1) : out;
}
