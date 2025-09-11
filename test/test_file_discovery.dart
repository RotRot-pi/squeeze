import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:squeeze/main.dart' as app; // adjust if needed

void main() {
  test('discoverSupportedFiles finds images recursively', () async {
    final tmp = await Directory.systemTemp.createTemp('squeeze_d1_');
    final sub = Directory(p.join(tmp.path, 'nested'))
      ..createSync(recursive: true);
    final files = <String>[
      p.join(tmp.path, 'a.jpg'),
      p.join(tmp.path, 'b.JPEG'),
      p.join(tmp.path, 'ignore.txt'),
      p.join(sub.path, 'c.PNG'),
      p.join(sub.path, 'd.webp'),
    ];
    for (final f in files) {
      File(f).writeAsBytesSync([0x00]); // just create files
    }

    final result = await app.discoverSupportedFiles([tmp.path]);
    // Normalize extensions to lowercase
    final names = result.map((e) => p.basename(e).toLowerCase()).toList()
      ..sort();

    expect(names, ['a.jpg', 'b.jpeg', 'c.png', 'd.webp']);
  });
}
