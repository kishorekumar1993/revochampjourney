import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';

@JS('saveMultipleFilesToFolders')
external void _jsSaveMultipleFilesToFolders(JSString json);

Future<void> downloadGeneratedFiles(
  List<Map<String, String>> files,
  BuildContext context,
) async {
  if (files.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No BLoC files were generated.'),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  _jsSaveMultipleFilesToFolders(jsonEncode(files).toJS);
}
