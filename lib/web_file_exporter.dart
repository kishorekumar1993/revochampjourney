import 'dart:convert';
import 'dart:js_interop';

/// Binds the Dart function to the top-level JavaScript function defined in index.html.
@JS('saveMultipleFilesToFolders')
external JSPromise _saveMultipleFilesToFolders(JSString jsonString);

@JS('downloadProjectZip')
external JSPromise _downloadProjectZip(JSString jsonString);

class WebFileExporter {
  /// Calls the JS File System API to save generated files.
  /// 
  /// Takes a list of file maps containing 'folderPath', 'fileName', and 'textContent'.
  static Future<void> exportFiles(List<Map<String, String>> files) async {
    try {
      // Convert the Dart list to a JSON string
      final jsonString = jsonEncode(files);
      
      // Call the external JavaScript function and await its promise
      await _saveMultipleFilesToFolders(jsonString.toJS).toDart;
      
    } catch (e) {
      print('Error exporting files to local file system: $e');
    }
  }

  /// Packages and downloads files as a single ZIP file.
  static Future<void> exportZip(List<Map<String, String>> files) async {
    try {
      final jsonString = jsonEncode(files);
      await _downloadProjectZip(jsonString.toJS).toDart;
    } catch (e) {
      print('Error exporting files to ZIP: $e');
    }
  }
}