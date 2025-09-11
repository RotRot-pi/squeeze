import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:squeeze/core/constants/app_constants.dart';

Future<void> openDirectoryInExplorer(String dirPath) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [dirPath]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [dirPath.replaceAll('/', '\\')]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dirPath]);
    }
  } catch (_) {}
}

List<String> _discoverSupportedFilesWorker(Map<String, dynamic> args) {
  final inputs = (args['inputs'] as List).cast<String>();
  final exts = ((args['exts'] as List).cast<String>())
      .map((e) => e.toLowerCase())
      .toSet();
  final results = <String>{};
  for (final input in inputs) {
    final type = FileSystemEntity.typeSync(input, followLinks: false);
    if (type == FileSystemEntityType.file) {
      if (exts.contains(p.extension(input).toLowerCase())) {
        results.add(p.normalize(input));
      }
    } else if (type == FileSystemEntityType.directory) {
      try {
        for (final e in Directory(
          input,
        ).listSync(recursive: true, followLinks: false)) {
          if (e is File && exts.contains(p.extension(e.path).toLowerCase())) {
            results.add(p.normalize(e.path));
          }
        }
      } catch (_) {}
    }
  }
  final out = results.toList()..sort();
  return out;
}

Future<List<String>> discoverSupportedFiles(List<String> paths) async {
  return compute(_discoverSupportedFilesWorker, {
    'inputs': paths,
    'exts': supportedExtensions.toList(),
  });
}
