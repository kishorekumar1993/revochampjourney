import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('saveMultipleFilesToFolders')
external JSPromise _saveMultipleFilesToFolders(JSString jsonString);

@JS('downloadProjectZip')
external JSPromise _downloadProjectZip(JSString jsonString);

class WebFileExporter {
  /// Calls the JS File System API to save generated files.
  static Future<void> exportFiles(List<Map<String, String>> files) async {
    try {
      final jsonString = jsonEncode(files);
      await _saveMultipleFilesToFolders(jsonString.toJS).toDart;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting files to local file system: $e');
      }
    }
  }

  /// Packages and downloads files as a single ZIP file.
  static Future<void> exportZip(List<Map<String, String>> files) async {
    try {
      final jsonString = jsonEncode(files);
      await _downloadProjectZip(jsonString.toJS).toDart;
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting files to ZIP: $e');
      }
    }
  }
}
