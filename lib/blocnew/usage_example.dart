// ignore_for_file: avoid_print
// usage_example.dart
//
// ╔══════════════════════════════════════════════════════════════════════╗
// ║  How to call RevochampBlocGenerator from your Revochamp platform     ║
// ║  This replaces blocGenerator() + blocConfigGenerator() +            ║
// ║  blocStateConfigGenerator() with one clean call.                    ║
// ╚══════════════════════════════════════════════════════════════════════╝
//
// In your saveRepositoryFile() function, replace the three separate bloc
// generator calls with:
//
//   import 'package:revojourneytryone/bloc/revochamp_bloc_generator.dart';
//
//   final blocFiles = generateFileDataArray(
//     screenName:   screenName,   // e.g. "User"
//     modelName:    modelName,    // e.g. "Form"
//     fieldJsonRaw: fieldJson,    // the parsed List<Map<String, dynamic>>
//   );
//   fileDataArray.addAll(blocFiles);
//
// ─────────────────────────────────────────────────────────────────────────
// Below is a runnable standalone demo using the exact JSON from the spec.
// ─────────────────────────────────────────────────────────────────────────

import 'dart:convert';

import 'package:revojourneytryone/blocnew/revochamp_bloc_generator.dart';

void main() {
  // ── 1. The raw field JSON array (from Revochamp UI) ─────────────────────
  //   This is exactly what the Revochamp platform passes as `fieldJsonRaw`.
  final fieldJson = _sampleFieldJson();

  // ── 2. Call the generator ────────────────────────────────────────────────
  final generator = RevochampBlocGenerator(
    screenName:   'User',     // Screen identifier — becomes folder/class prefix
    modelName:    'Form',     // Model suffix   — UserFormBloc, UserFormState …
    fieldJsonRaw: fieldJson,
  );

  final generatedFiles = generator.generate();
  // generatedFiles: Map<String, String>
  //   key   = full path  e.g. "lib/bloc/features/user/domain/entities/user_form_entity.dart"
  //   value = dart source code

  // ── 3. Print summary ─────────────────────────────────────────────────────
  print('═══════════════════════════════════════════════════');
  print('  Revochamp BLoC Generator — Generated Files       ');
  print('═══════════════════════════════════════════════════');
  for (final path in generatedFiles.keys) {
    print('  ✓  $path');
  }
  print('─── Total: ${generatedFiles.length} files ──────────────────────');

  // ── 4. Print one sample file ─────────────────────────────────────────────
  final stateFile = generatedFiles.entries.firstWhere(
    (e) => e.key.contains('feature_state'),
    orElse: () => generatedFiles.entries.first,
  );
  print('\n── SAMPLE OUTPUT: ${stateFile.key} ──\n');
  print(stateFile.value);

  // ── 5. Build the fileDataArray format for JS interop ────────────────────
  //   Use this when calling js.context.callMethod("saveMultipleFilesToFolders", ...)
  final fileDataArray = generateFileDataArray(
    screenName:   'User',
    modelName:    'Form',
    fieldJsonRaw: fieldJson,
  );

  // Serialize to JSON for the JS bridge
  final jsonPayload = jsonEncode(fileDataArray);
  print('\n── fileDataArray length: ${fileDataArray.length} entries ──');
  print('── First entry: ${fileDataArray.first} ──');
  print('── JSON Payload Size: ${jsonPayload.length} characters ──');
  // In real code:  js.context.callMethod("saveMultipleFilesToFolders", [jsonPayload]);
}

// ─────────────────────────────────────────────────────────────────────────
// Integration into existing saveRepositoryFile()
// ─────────────────────────────────────────────────────────────────────────
//
// Replace this in your existing code:
//
//   blocGenerator(fieldJson: fieldJson, baseName: baseName,
//       fileDataArray: fileDataArray, screenName: screenName, modelName: modelName);
//   blocConfigGenerator(fieldJson: fieldJson, baseName: baseName,
//       fileDataArray: fileDataArray, screenName: screenName, modelName: modelName);
//   blocStateConfigGenerator(fieldJson: fieldJson, baseName: baseName,
//       fileDataArray: fileDataArray, screenName: screenName, modelName: modelName);
//
// With this single call:
//
//   final blocFiles = generateFileDataArray(
//     screenName:   screenName,
//     modelName:    modelName,
//     fieldJsonRaw: fieldJson,
//   );
//   fileDataArray.addAll(blocFiles);
//
// ─────────────────────────────────────────────────────────────────────────

// Sample field JSON — mirrors the exact input from the spec document
List<Map<String, dynamic>> _sampleFieldJson() => [
      {
        "id": "[#ccf90]",
        "useStaticOptions": false,
        "staticOptions": [],
        "type": "TextField",
        "label": "First Name",
        "required": true,
        "initialValue": "",
        "hintText": "Enter first name",
        "maxLength": null,
        "minLength": 3,
        "readOnly": false,
        "disable": false,
        "hidden": false,
        "apiParam": "",
        "api": false,
        "dropdownApiUrl": "",
        "dropdownApiMethod": "GET",
        "dropdownApiHeaders": null,
        "dropdownApiBody": "",
        "dropdownkey": "",
        "dropdownValue": "",
        "dropdowndata": null,
        "validationPattern": r"^[a-zA-Z ]+$",
        "errorMessage": "Only alphabets allowed",
        "obscureText": false,
        "keyboardType": "text",
      },
      {
        "id": "[#d695d]",
        "useStaticOptions": false,
        "staticOptions": [],
        "type": "Dropdown",
        "label": "Title",
        "required": false,
        "initialValue": "",
        "hintText": "",
        "maxLength": null,
        "minLength": null,
        "readOnly": false,
        "disable": false,
        "hidden": false,
        "dropdownApiUrl": "https://dummyjson.com/posts",
        "dropdownApiMethod": "GET",
        "dropdownApiHeaders": null,
        "dropdownkey": "id",
        "dropdownValue": "title",
        "dropdowndata": [
          {
            "id": 1,
            "title": "His mother had always taught him",
            "body": "His mother had always taught him not to...",
            "tags": ["history", "american"],
            "views": 305,
            "userId": 121,
          }
        ],
        "validationPattern": "",
        "errorMessage": "",
        "keyboardType": "text",
      },
      {
        "id": "[#cbb7a]",
        "useStaticOptions": true,
        "staticOptions": [
          {"key": "M", "value": "Male"},
          {"key": "F", "value": "Female"},
          {"key": "O", "value": "Other"},
        ],
        "type": "Radio Buttons",
        "label": "Gender",
        "required": false,
        "initialValue": "",
        "hintText": "",
        "dropdownApiUrl": "",
        "dropdowndata": null,
        "validationPattern": "",
        "errorMessage": "",
        "keyboardType": "text",
      },
      {
        "id": "[#f7390]",
        "useStaticOptions": false,
        "staticOptions": [],
        "type": "Date",
        "label": "Date of Birth",
        "required": false,
        "initialValue": "",
        "hintText": "",
        "dropdownApiUrl": "",
        "dropdowndata": null,
        "validationPattern": "",
        "errorMessage": "",
        "keyboardType": "text",
      },
    ];
