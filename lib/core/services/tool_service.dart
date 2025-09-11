import 'dart:io';

Future<bool> cmdOnPath(String cmd) async {
  try {
    final res = await Process.run(Platform.isWindows ? 'where' : 'which', [
      cmd,
    ]);
    return res.exitCode == 0 &&
        res.stdout.toString().toString().trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}
