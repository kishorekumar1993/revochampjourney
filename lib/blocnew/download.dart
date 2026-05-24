import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:revojourneytryone/core/theme.dart';  // only used on web, add at top
import 'dart:js' as js;

Future<void> downloadGeneratedFiles(List<Map<String, String>> files, BuildContext context) async {
  for (final file in files) {
    final fileName = file['name']!;
    final content = file['content']!;
   js.context.callMethod("saveMultipleFilesToFolders", [content]);

    // if (kIsWeb) {
    //   final blob = html.Blob([content], 'text/plain');
    //   final url = html.Url.createObjectUrlFromBlob(blob);
    //   final anchor = html.AnchorElement(href: url)
    //     ..setAttribute('download', fileName)
    //     ..click();
    //   html.Url.revokeObjectUrl(url);
    // } else {
    //   final directory = await getApplicationDocumentsDirectory();
    //   final file = File('${directory.path}/$fileName');
    //   await file.writeAsString(content);
    //   // optionally show a snackbar with the file path
    // }
  }
}