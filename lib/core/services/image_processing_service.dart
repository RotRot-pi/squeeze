import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:squeeze/core/constants/app_constants.dart';
import 'package:squeeze/core/models/options.dart';

class ProcessResult {
  final bool success;
  final String? error;
  final String outputPath;
  final bool skipped;
  final String? note;
  ProcessResult({
    required this.success,
    this.error,
    required this.outputPath,
    required this.skipped,
    this.note,
  });
}

Future<ProcessResult> processImage(String inputPath, Options options) async {
  final res = await compute(_processImageWorker, {
    'inputPath': inputPath,
    'options': options.toMap(),
  });
  return ProcessResult(
    success: res['success'] as bool,
    error: res['error'] as String?,
    outputPath: res['outputPath'] as String,
    skipped: res['skipped'] as bool,
    note: res['note'] as String?,
  );
}

Map<String, dynamic> _processImageWorker(Map<String, dynamic> args) {
  final inputPath = args['inputPath'] as String;
  final options = Options.fromMap(
    (args['options'] as Map).cast<String, dynamic>(),
  );
  try {
    final inputFile = File(inputPath);
    if (!inputFile.existsSync()) {
      return {
        'success': false,
        'error': 'File not found',
        'outputPath': '',
        'skipped': false,
        'note': null,
      };
    }

    final inputLen = inputFile.lengthSync();
    if (options.minInputKB > 0 && inputLen < options.minInputKB * 1024) {
      return {
        'success': true,
        'error': null,
        'outputPath': '',
        'skipped': true,
        'note': 'Skipped (small file)',
      };
    }

    final bytes = inputFile.readAsBytesSync();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return {
        'success': false,
        'error': 'Unsupported or invalid image',
        'outputPath': '',
        'skipped': false,
        'note': null,
      };
    }

    final interp = _interpFor(options.resampleQuality);
    img.Image image = img.bakeOrientation(decoded);

    final ext = p.extension(inputPath).toLowerCase();

    img.Image processFit(img.Image src, int tw, int th, bool noUpscale) {
      final sw = src.width, sh = src.height;
      final scale = math.min(tw / sw, th / sh);
      final useScale = (noUpscale && scale > 1.0) ? 1.0 : scale;
      if (useScale == 1.0) return src;
      final w = (sw * useScale).round();
      final h = (sh * useScale).round();
      return img.copyResize(src, width: w, height: h, interpolation: interp);
    }

    img.Image processFill(img.Image src, int tw, int th, bool noUpscale) {
      final sw = src.width, sh = src.height;
      final requireUpscale = sw < tw || sh < th;
      if (noUpscale && requireUpscale) {
        return processFit(src, tw, th, true);
      }
      final scale = math.max(tw / sw, th / sh);
      final w = (sw * scale).round();
      final h = (sh * scale).round();
      final resized = img.copyResize(
        src,
        width: w,
        height: h,
        interpolation: interp,
      );
      final x = ((w - tw) / 2).round();
      final y = ((h - th) / 2).round();
      return img.copyCrop(resized, x: x, y: y, width: tw, height: th);
    }

    img.Image processPad(
      img.Image src,
      int tw,
      int th,
      bool noUpscale,
      bool transparentBg,
    ) {
      final sw = src.width, sh = src.height;
      final scale = math.min(tw / sw, th / sh);
      final useScale = (noUpscale && scale > 1.0) ? 1.0 : scale;
      final w = (sw * useScale).round();
      final h = (sh * useScale).round();
      final resized = (useScale == 1.0)
          ? src
          : img.copyResize(src, width: w, height: h, interpolation: interp);

      final bgColor = transparentBg
          ? img.ColorRgba8(0, 0, 0, 0)
          : img.ColorRgba8(255, 255, 255, 255);

      final canvas = img.Image(
        width: tw,
        height: th,
        numChannels: src.numChannels,
        backgroundColor: bgColor,
      );

      final dx = ((tw - resized.width) / 2).round();
      final dy = ((th - resized.height) / 2).round();

      img.compositeImage(
        canvas,
        resized,
        dstX: dx,
        dstY: dy,
        blend: img.BlendMode.direct,
      );

      return canvas;
    }

    if (options.resizeMode == ResizeMode.longEdge) {
      final w = image.width, h = image.height;
      final longEdge = math.max(w, h);
      if (longEdge > options.maxLongEdge ||
          (!options.noUpscale && longEdge < options.maxLongEdge)) {
        final scale = options.maxLongEdge / longEdge;
        final useScale = options.noUpscale && scale > 1.0 ? 1.0 : scale;
        if (useScale != 1.0) {
          image = img.copyResize(
            image,
            width: (w * useScale).round(),
            height: (h * useScale).round(),
            interpolation: interp,
          );
        }
      }
    } else {
      final tw = math.max(1, options.targetWidth);
      final th = math.max(1, options.targetHeight);
      if (options.resizeMode == ResizeMode.fit) {
        image = processFit(image, tw, th, options.noUpscale);
      } else if (options.resizeMode == ResizeMode.fill) {
        image = processFill(image, tw, th, options.noUpscale);
      } else if (options.resizeMode == ResizeMode.pad) {
        final transparentBgPreferred =
            options.preferredOutputFormat != OutputFormat.jpeg;
        image = processPad(
          image,
          tw,
          th,
          options.noUpscale,
          transparentBgPreferred,
        );
      }
    }

    OutputFormat outFmt = options.preferredOutputFormat;
    if (outFmt == OutputFormat.auto) {
      if (ext == '.jpg' || ext == '.jpeg') {
        outFmt = OutputFormat.jpeg;
      } else if (ext == '.png') {
        if (options.convertPngToJpeg) {
          final hasAlpha = _hasTransparencySampled(image);
          outFmt = hasAlpha ? OutputFormat.png : OutputFormat.jpeg;
        } else {
          outFmt = OutputFormat.png;
        }
      } else {
        outFmt = OutputFormat.jpeg;
      }
    }

    final baseName = p.basenameWithoutExtension(inputPath);
    final parentName = p.basename(p.dirname(inputPath));
    final outputDir = options.outputDir != null
        ? p.join(options.outputDir!, parentName)
        : p.join(p.dirname(inputPath), 'Compressed');
    Directory(outputDir).createSync(recursive: true);

    String outExt = '.jpg';
    if (outFmt == OutputFormat.png) outExt = '.png';

    String suffix = options.filenameSuffix;
    if (options.resizeMode == ResizeMode.fill ||
        options.resizeMode == ResizeMode.pad) {
      final tw = math.max(1, options.targetWidth);
      final th = math.max(1, options.targetHeight);
      suffix = '${suffix.isEmpty ? '' : suffix}-${tw}x$th';
    }

    String outputPath = p.join(outputDir, '$baseName$suffix$outExt');
    int counter = 1;
    while (File(outputPath).existsSync()) {
      outputPath = p.join(outputDir, '$baseName$suffix($counter)$outExt');
      counter++;
    }

    List<int> outBytes;
    if (outFmt == OutputFormat.jpeg) {
      outBytes = img.encodeJpg(
        image,
        quality: options.jpegQuality.clamp(1, 100),
      );
    } else if (outFmt == OutputFormat.png) {
      outBytes = img.encodePng(image, level: 6);
    } else {
      outBytes = img.encodeJpg(
        image,
        quality: options.jpegQuality.clamp(1, 100),
      );
    }
    File(outputPath).writeAsBytesSync(outBytes);

    if (outFmt == OutputFormat.jpeg && options.enableJpegOptim) {
      try {
        Process.runSync('jpegoptim', [
          '--strip-all',
          '--all-progressive',
          '--max=${options.jpegQuality}',
          outputPath,
        ]);
      } catch (_) {}
    }
    if (outFmt == OutputFormat.png) {
      if (options.enablePngquant) {
        try {
          final tmp = '$outputPath.qtmp.png';
          final r = Process.runSync('pngquant', [
            '--force',
            '--skip-if-larger',
            '--quality=${options.pngquantQualityMin}-${options.pngquantQualityMax}',
            '--output',
            tmp,
            outputPath,
          ]);
          if (r.exitCode == 0 && File(tmp).existsSync()) {
            final tmpFile = File(tmp);
            final orig = File(outputPath);
            if (tmpFile.lengthSync() < orig.lengthSync()) {
              try {
                orig.deleteSync();
              } catch (_) {}
              tmpFile.renameSync(outputPath);
            } else {
              try {
                tmpFile.deleteSync();
              } catch (_) {}
            }
          } else {
            try {
              File(tmp).deleteSync();
            } catch (_) {}
          }
        } catch (_) {}
      }
      if (options.enableOxipng) {
        try {
          Process.runSync('oxipng', [
            '-o',
            '4',
            '--strip',
            'all',
            '--preserve',
            outputPath,
          ]);
        } catch (_) {}
      }
    }

    return {
      'success': true,
      'error': null,
      'outputPath': outputPath,
      'skipped': false,
      'note': null,
    };
  } catch (e) {
    return {
      'success': false,
      'error': e.toString(),
      'outputPath': '',
      'skipped': false,
      'note': null,
    };
  }
}

bool _hasTransparencySampled(img.Image image, {int step = 16}) {
  final w = image.width, h = image.height;
  for (int y = 0; y < h; y += step) {
    for (int x = 0; x < w; x += step) {
      final a = image.getPixel(x, y).a;
      if (a < 255) return true;
    }
  }
  final c = image.getPixel(w - 1, h - 1);
  return c.a < 255;
}

img.Interpolation _interpFor(ResampleQuality q) {
  switch (q) {
    case ResampleQuality.quality:
      return img.Interpolation.cubic;
    case ResampleQuality.pixel:
      return img.Interpolation.nearest;
    case ResampleQuality.fast:
      return img.Interpolation.average;
  }
}
