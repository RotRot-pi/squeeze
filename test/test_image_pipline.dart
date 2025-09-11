import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:squeeze/main.dart'
    as app; // adjust if your package name differs

Future<File> _writeImageJpg(
  Directory dir,
  String name, {
  int w = 3000,
  int h = 2000,
  int quality = 90,
}) async {
  final image = img.Image(width: w, height: h);
  final bytes = img.encodeJpg(image, quality: quality);
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes);
  return file;
}

Future<File> _writeImagePng(
  Directory dir,
  String name, {
  int w = 800,
  int h = 600,
  int level = 0,
}) async {
  final image = img.Image(width: w, height: h);
  final bytes = img.encodePng(image, level: level);
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes);
  return file;
}

void main() {
  test('JPEG is resized and compressed without upscaling', () async {
    final tmp = await Directory.systemTemp.createTemp('squeeze_u1_');
    final inFile = await _writeImageJpg(tmp, 'big.jpg', w: 4000, h: 3000);

    final opts = app.Options.defaultOptions.copyWith(
      maxLongEdge: 1600,
      jpegQuality: 70,
      outputDir: p.join(tmp.path, 'out'),
    );

    final result = await app.processImage(inFile.path, opts);
    expect(result.success, true);
    expect(result.outputPath.isNotEmpty, true);
    final outFile = File(result.outputPath);
    expect(outFile.existsSync(), true);

    final outBytes = await outFile.readAsBytes();
    final decoded = img.decodeImage(outBytes)!;
    expect(decoded.width <= 1600 && decoded.height <= 1600, true);

    // Should be smaller than original (likely by a lot)
    expect(outFile.lengthSync() < inFile.lengthSync(), true);
  });

  test('PNG -> JPEG conversion when toggle is ON', () async {
    final tmp = await Directory.systemTemp.createTemp('squeeze_u2_');
    final inFile = await _writeImagePng(tmp, 'shot.png', w: 1200, h: 800);

    final opts = app.Options.defaultOptions.copyWith(
      convertPngToJpeg: true,
      outputDir: p.join(tmp.path, 'out'),
    );

    final result = await app.processImage(inFile.path, opts);
    expect(result.success, true);
    expect(p.extension(result.outputPath).toLowerCase(), '.jpg');
  });

  test('PNG stays PNG when toggle is OFF', () async {
    final tmp = await Directory.systemTemp.createTemp('squeeze_u3_');
    final inFile = await _writeImagePng(tmp, 'shot.png', w: 1200, h: 800);

    final opts = app.Options.defaultOptions.copyWith(
      convertPngToJpeg: false,
      outputDir: p.join(tmp.path, 'out'),
    );

    final result = await app.processImage(inFile.path, opts);
    expect(result.success, true);
    expect(p.extension(result.outputPath).toLowerCase(), '.png');
  });
}
