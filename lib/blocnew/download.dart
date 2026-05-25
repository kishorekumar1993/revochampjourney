import 'dart:js_interop';

import 'package:flutter/material.dart';

// ── File System Access API — JS interop bindings ─────────────────────────────

@JS()
extension type _CreateOpts._(JSObject _) implements JSObject {
  external factory _CreateOpts({bool create});
}

@JS()
extension type _Writable._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSString data);
  external JSPromise<JSAny?> close();
}

@JS()
extension type _FileHandle._(JSObject _) implements JSObject {
  external JSPromise<_Writable> createWritable();
}

@JS()
extension type _DirHandle._(JSObject _) implements JSObject {
  external JSPromise<_DirHandle> getDirectoryHandle(
    String name,
    _CreateOpts opts,
  );
  external JSPromise<_FileHandle> getFileHandle(
    String name,
    _CreateOpts opts,
  );
}

@JS('showDirectoryPicker')
external JSPromise<_DirHandle> _showDirectoryPicker();

// ── Public API ────────────────────────────────────────────────────────────────

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

  try {
    final root      = await _showDirectoryPicker().toDart;
    final createOpt = _CreateOpts(create: true);

    for (final file in files) {
      var dir = root;

      for (final part in (file['folderPath'] ?? '')
          .replaceAll(r'\', '/')
          .split('/')
          .where((p) => p.isNotEmpty)) {
        dir = await dir.getDirectoryHandle(part, createOpt).toDart;
      }

      final fh       = await dir.getFileHandle(file['fileName']!, createOpt).toDart;
      final writable = await fh.createWritable().toDart;
      await writable.write((file['textContent'] ?? '').toJS).toDart;
      await writable.close().toDart;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All files saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
