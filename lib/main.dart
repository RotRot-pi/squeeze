import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

const appTitle = 'Squeeze';

const supportedExtensions = {'.jpg', '.jpeg', '.png'};

enum JobStatus { queued, processing, done, error }

enum ResizeMode { longEdge, fit, fill, pad }

enum OutputFormat { auto, jpeg, png }

enum ResampleQuality { fast, quality, pixel }

String formatCountSummary(int done, int total, int errors) {
  final parts = <String>[];
  parts.add('$done/$total done');
  if (errors > 0) parts.add('$errors error${errors > 1 ? 's' : ''}');
  return parts.join(' • ');
}

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

class Options {
  final int maxLongEdge;
  final int jpegQuality;
  final bool convertPngToJpeg;
  final bool stripMetadata;
  final String filenameSuffix;
  final String? outputDir;
  final int minInputKB;
  final ResizeMode resizeMode;
  final int targetWidth;
  final int targetHeight;
  final bool noUpscale;
  final OutputFormat preferredOutputFormat;
  final ResampleQuality resampleQuality;
  final bool enableJpegOptim;
  final bool enablePngquant;
  final bool enableOxipng;
  final int pngquantQualityMin;
  final int pngquantQualityMax;

  const Options({
    required this.maxLongEdge,
    required this.jpegQuality,
    required this.convertPngToJpeg,
    required this.stripMetadata,
    required this.filenameSuffix,
    this.outputDir,
    required this.minInputKB,
    required this.resizeMode,
    required this.targetWidth,
    required this.targetHeight,
    required this.noUpscale,
    required this.preferredOutputFormat,
    required this.resampleQuality,
    required this.enableJpegOptim,
    required this.enablePngquant,
    required this.enableOxipng,
    required this.pngquantQualityMin,
    required this.pngquantQualityMax,
  });

  Options copyWith({
    int? maxLongEdge,
    int? jpegQuality,
    bool? convertPngToJpeg,
    bool? stripMetadata,
    String? filenameSuffix,
    String? outputDir,
    int? minInputKB,
    ResizeMode? resizeMode,
    int? targetWidth,
    int? targetHeight,
    bool? noUpscale,
    OutputFormat? preferredOutputFormat,
    ResampleQuality? resampleQuality,
    bool? enableJpegOptim,
    bool? enablePngquant,
    bool? enableOxipng,
    int? pngquantQualityMin,
    int? pngquantQualityMax,
  }) {
    return Options(
      maxLongEdge: maxLongEdge ?? this.maxLongEdge,
      jpegQuality: jpegQuality ?? this.jpegQuality,
      convertPngToJpeg: convertPngToJpeg ?? this.convertPngToJpeg,
      stripMetadata: stripMetadata ?? this.stripMetadata,
      filenameSuffix: filenameSuffix ?? this.filenameSuffix,
      outputDir: outputDir ?? this.outputDir,
      minInputKB: minInputKB ?? this.minInputKB,
      resizeMode: resizeMode ?? this.resizeMode,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      noUpscale: noUpscale ?? this.noUpscale,
      preferredOutputFormat:
          preferredOutputFormat ?? this.preferredOutputFormat,
      resampleQuality: resampleQuality ?? this.resampleQuality,
      enableJpegOptim: enableJpegOptim ?? this.enableJpegOptim,
      enablePngquant: enablePngquant ?? this.enablePngquant,
      enableOxipng: enableOxipng ?? this.enableOxipng,
      pngquantQualityMin: pngquantQualityMin ?? this.pngquantQualityMin,
      pngquantQualityMax: pngquantQualityMax ?? this.pngquantQualityMax,
    );
  }

  Map<String, dynamic> toMap() => {
    'maxLongEdge': maxLongEdge,
    'jpegQuality': jpegQuality,
    'convertPngToJpeg': convertPngToJpeg,
    'stripMetadata': stripMetadata,
    'filenameSuffix': filenameSuffix,
    'outputDir': outputDir,
    'minInputKB': minInputKB,
    'resizeMode': resizeMode.index,
    'targetWidth': targetWidth,
    'targetHeight': targetHeight,
    'noUpscale': noUpscale,
    'preferredOutputFormat': preferredOutputFormat.index,
    'resampleQuality': resampleQuality.index,
    'enableJpegOptim': enableJpegOptim,
    'enablePngquant': enablePngquant,
    'enableOxipng': enableOxipng,
    'pngquantQualityMin': pngquantQualityMin,
    'pngquantQualityMax': pngquantQualityMax,
  };

  static Options fromMap(Map<String, dynamic> m) => Options(
    maxLongEdge: m['maxLongEdge'] as int,
    jpegQuality: m['jpegQuality'] as int,
    convertPngToJpeg: m['convertPngToJpeg'] as bool,
    stripMetadata: m['stripMetadata'] as bool,
    filenameSuffix: m['filenameSuffix'] as String,
    outputDir: m['outputDir'] as String?,
    minInputKB: m['minInputKB'] as int,
    resizeMode: ResizeMode.values[m['resizeMode'] as int],
    targetWidth: m['targetWidth'] as int,
    targetHeight: m['targetHeight'] as int,
    noUpscale: m['noUpscale'] as bool,
    preferredOutputFormat:
        OutputFormat.values[m['preferredOutputFormat'] as int],
    resampleQuality: ResampleQuality.values[m['resampleQuality'] as int],
    enableJpegOptim: m['enableJpegOptim'] as bool,
    enablePngquant: m['enablePngquant'] as bool,
    enableOxipng: m['enableOxipng'] as bool,
    pngquantQualityMin: m['pngquantQualityMin'] as int,
    pngquantQualityMax: m['pngquantQualityMax'] as int,
  );

  static const defaultOptions = Options(
    maxLongEdge: 1600,
    jpegQuality: 70,
    convertPngToJpeg: true,
    stripMetadata: true,
    filenameSuffix: '-compressed',
    outputDir: null,
    minInputKB: 0,
    resizeMode: ResizeMode.longEdge,
    targetWidth: 1024,
    targetHeight: 1024,
    noUpscale: true,
    preferredOutputFormat: OutputFormat.auto,
    resampleQuality: ResampleQuality.fast,
    enableJpegOptim: false,
    enablePngquant: false,
    enableOxipng: false,
    pngquantQualityMin: 65,
    pngquantQualityMax: 85,
  );
}

class Job {
  final String id;
  final String inputPath;
  String? outputPath;
  JobStatus status;
  String? error;
  String? note;
  Job({
    required this.id,
    required this.inputPath,
    this.outputPath,
    this.status = JobStatus.queued,
    this.error,
    this.note,
  });
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
    default:
      return img.Interpolation.average;
  }
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

class _ProcessResult {
  final bool success;
  final String? error;
  final String outputPath;
  final bool skipped;
  final String? note;
  _ProcessResult({
    required this.success,
    this.error,
    required this.outputPath,
    required this.skipped,
    this.note,
  });
}

Future<_ProcessResult> processImage(String inputPath, Options options) async {
  final res = await compute(_processImageWorker, {
    'inputPath': inputPath,
    'options': options.toMap(),
  });
  return _ProcessResult(
    success: res['success'] as bool,
    error: res['error'] as String?,
    outputPath: res['outputPath'] as String,
    skipped: res['skipped'] as bool,
    note: res['note'] as String?,
  );
}

class _Semaphore {
  int _available;
  final _waiters = <Completer<void>>[];
  _Semaphore(this._available);
  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return SynchronousFuture(null);
    }
    final c = Completer<void>();
    _waiters.add(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      final c = _waiters.removeAt(0);
      c.complete();
    } else {
      _available++;
    }
  }
}

class CancelToken {
  bool _canceled = false;
  bool get canceled => _canceled;
  void cancel() => _canceled = true;
}

void main() {
  runApp(const SqueezeApp());
}

class SqueezeApp extends StatelessWidget {
  const SqueezeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: FluentThemeData(
        brightness: Brightness.light,
        visualDensity: VisualDensity.standard,
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        visualDensity: VisualDensity.standard,
      ),
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  Options options = Options.defaultOptions;
  final List<Job> jobs = [];
  bool isProcessing = false;
  bool isDraggingOver = false;
  String? bannerMessage;
  InfoBarSeverity bannerSeverity = InfoBarSeverity.info;
  Timer? _bannerTimer;
  CancelToken? _token;

  bool hasJpegoptim = false;
  bool hasPngquant = false;
  bool hasOxipng = false;

  int get totalCount => jobs.length;
  int get doneCount => jobs.where((j) => j.status == JobStatus.done).length;
  int get errorCount => jobs.where((j) => j.status == JobStatus.error).length;

  @override
  void initState() {
    super.initState();
    _detectExternalTools();
  }

  Future<bool> _cmdOnPath(String cmd) async {
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

  Future<void> _detectExternalTools() async {
    final j = await _cmdOnPath('jpegoptim');
    final pz = await _cmdOnPath('pngquant');
    final ox = await _cmdOnPath('oxipng');
    if (!mounted) return;
    setState(() {
      hasJpegoptim = j;
      hasPngquant = pz;
      hasOxipng = ox;
      if (!j && options.enableJpegOptim) {
        options = options.copyWith(enableJpegOptim: false);
      }
      if (!pz && options.enablePngquant) {
        options = options.copyWith(enablePngquant: false);
      }
      if (!ox && options.enableOxipng) {
        options = options.copyWith(enableOxipng: false);
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  void showBanner(
    String message,
    InfoBarSeverity severity, {
    Duration autoHide = const Duration(seconds: 3),
  }) {
    _bannerTimer?.cancel();
    setState(() {
      bannerMessage = message;
      bannerSeverity = severity;
    });
    _bannerTimer = Timer(autoHide, () {
      if (mounted) setState(() => bannerMessage = null);
    });
  }

  Future<void> addDroppedItems(List<String> paths) async {
    if (paths.isEmpty) return;
    final files = await discoverSupportedFiles(paths);
    if (files.isEmpty) {
      showBanner('No supported images found.', InfoBarSeverity.info);
      return;
    }
    int added = 0;
    for (final path in files) {
      if (!jobs.any((j) => j.inputPath == path)) {
        jobs.add(Job(id: path, inputPath: path));
        added++;
      }
    }
    setState(() {});
    showBanner(
      'Added $added file${added == 1 ? '' : 's'}',
      InfoBarSeverity.success,
    );
  }

  Future<void> pickFiles() async {
    final typeGroup = XTypeGroup(
      label: 'images',
      extensions: supportedExtensions
          .map((e) => e.replaceFirst('.', ''))
          .toList(),
    );
    final selected = await openFiles(acceptedTypeGroups: [typeGroup]);
    await addDroppedItems(selected.map((x) => x.path).toList());
  }

  Future<void> pickFolderAndAdd() async {
    final dir = await getDirectoryPath();
    if (dir != null) await addDroppedItems([dir]);
  }

  Future<void> pickOutputDir() async {
    final dir = await getDirectoryPath();
    if (dir != null) {
      setState(() => options = options.copyWith(outputDir: dir));
    }
  }

  void clearJobs() {
    setState(() => jobs.clear());
  }

  void removeDoneAndErrors() {
    setState(() {
      jobs.removeWhere(
        (j) => j.status == JobStatus.done || j.status == JobStatus.error,
      );
    });
  }

  Future<void> processAll() async {
    if (isProcessing || jobs.isEmpty) return;
    setState(() => isProcessing = true);
    _token = CancelToken();
    final sem = _Semaphore(
      math.max(1, math.min(Platform.numberOfProcessors, 6)),
    );
    final sw = Stopwatch()..start();
    final futures = <Future<void>>[];

    for (final job in jobs.where((j) => j.status == JobStatus.queued)) {
      if (_token!.canceled) break;
      await sem.acquire();
      if (!mounted) {
        sem.release();
        break;
      }
      setState(() => job.status = JobStatus.processing);
      futures.add(() async {
        try {
          if (_token!.canceled) return;
          final res = await processImage(job.inputPath, options);
          if (!mounted) return;
          setState(() {
            if (res.success) {
              job.status = JobStatus.done;
              if (res.outputPath.isNotEmpty) {
                job.outputPath = res.outputPath;
              }
              if (res.skipped || (res.note != null && res.note!.isNotEmpty)) {
                job.note = res.note ?? 'Skipped';
              }
            } else {
              job.status = JobStatus.error;
              job.error = res.error ?? 'Unknown error';
            }
          });
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(futures);
    sw.stop();
    if (!mounted) return;
    setState(() => isProcessing = false);
    showBanner(
      'Finished in ${sw.elapsed.inSeconds}s • ${formatCountSummary(doneCount, totalCount, errorCount)}',
      errorCount > 0 ? InfoBarSeverity.warning : InfoBarSeverity.success,
    );
  }

  void cancelProcessing() {
    _token?.cancel();
    showBanner('Cancel requested', InfoBarSeverity.info);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text(appTitle),
        automaticallyImplyLeading: false,
      ),
      content: ScaffoldPage(
        padding: const EdgeInsets.all(12),
        content: Row(
          children: [
            Expanded(
              flex: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 3,
                    child: _DropZone(
                      isDraggingOver: isDraggingOver,
                      onDragEntered: () =>
                          setState(() => isDraggingOver = true),
                      onDragExited: () =>
                          setState(() => isDraggingOver = false),
                      onDropPaths: (paths) async {
                        setState(() => isDraggingOver = false);
                        await addDroppedItems(paths);
                      },
                      onPickFiles: pickFiles,
                      onPickFolder: pickFolderAndAdd,
                      imagePaths: jobs.map((j) => j.inputPath).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: _JobList(jobs: jobs, isProcessing: isProcessing),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 4,
              child: _SettingsPane(
                options: options,
                onOptionsChanged: (o) => setState(() => options = o),
                onPickOutput: pickOutputDir,
                onProcess: processAll,
                onCancel: cancelProcessing,
                onClearQueue: clearJobs,
                onClearFinished: removeDoneAndErrors,
                isProcessing: isProcessing,
                bannerMessage: bannerMessage,
                bannerSeverity: bannerSeverity,
                onCloseBanner: () => setState(() => bannerMessage = null),
                doneCount: doneCount,
                totalCount: totalCount,
                errorCount: errorCount,
                hasJpegoptim: hasJpegoptim,
                hasPngquant: hasPngquant,
                hasOxipng: hasOxipng,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  final bool isDraggingOver;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final Future<void> Function(List<String> paths) onDropPaths;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final List<String> imagePaths;

  const _DropZone({
    required this.isDraggingOver,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDropPaths,
    required this.imagePaths,
    required this.onPickFiles,
    required this.onPickFolder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropTarget(
        onDragEntered: (_) => onDragEntered(),
        onDragExited: (_) => onDragExited(),
        onDragDone: (details) {
          final paths = details.files.map((x) => x.path).toList();
          onDropPaths(paths);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: isDraggingOver
                ? theme.accentColor.lighter.withOpacity(0.08)
                : theme.micaBackgroundColor,
            border: Border.all(
              color: isDraggingOver
                  ? theme.accentColor
                  : theme.resources.controlStrongStrokeColorDefault,
              width: isDraggingOver ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: imagePaths.isEmpty
              ? _buildEmptyDropZone(context)
              : _buildImagePreview(context),
        ),
      ),
    );
  }

  Widget _buildEmptyDropZone(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.cloud_download,
              size: 56,
              color: theme.accentColor,
            ),
            const SizedBox(height: 10),
            Text(
              'Drag & drop images or folders here',
              style: theme.typography.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text('Supported: JPG, JPEG, PNG', style: theme.typography.caption),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                FilledButton(
                  onPressed: onPickFiles,
                  child: const Text('Select files'),
                ),
                Button(
                  onPressed: onPickFolder,
                  child: const Text('Select folder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (imagePaths.length == 1) {
      return Image.file(
        File(imagePaths.first),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
      );
    } else {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: imagePaths.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: Image.file(
              File(imagePaths[index]),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          );
        },
      );
    }
  }
}

class _SettingsPane extends StatefulWidget {
  final Options options;
  final ValueChanged<Options> onOptionsChanged;
  final VoidCallback onPickOutput;
  final VoidCallback onProcess;
  final VoidCallback onCancel;
  final VoidCallback onClearQueue;
  final VoidCallback onClearFinished;
  final bool isProcessing;
  final String? bannerMessage;
  final InfoBarSeverity bannerSeverity;
  final VoidCallback onCloseBanner;
  final int doneCount;
  final int totalCount;
  final int errorCount;
  final bool hasJpegoptim;
  final bool hasPngquant;
  final bool hasOxipng;

  const _SettingsPane({
    required this.options,
    required this.onOptionsChanged,
    required this.onPickOutput,
    required this.onProcess,
    required this.onCancel,
    required this.onClearQueue,
    required this.onClearFinished,
    required this.isProcessing,
    required this.bannerMessage,
    required this.bannerSeverity,
    required this.onCloseBanner,
    required this.doneCount,
    required this.totalCount,
    required this.errorCount,
    required this.hasJpegoptim,
    required this.hasPngquant,
    required this.hasOxipng,
  });

  @override
  State<_SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends State<_SettingsPane> {
  late final TextEditingController _suffixCtl;
  late final ScrollController _scrollCtl;

  @override
  void initState() {
    super.initState();
    _suffixCtl = TextEditingController(text: widget.options.filenameSuffix);
    _scrollCtl = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _SettingsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.filenameSuffix != widget.options.filenameSuffix &&
        _suffixCtl.text != widget.options.filenameSuffix) {
      _suffixCtl.text = widget.options.filenameSuffix;
    }
  }

  @override
  void dispose() {
    _suffixCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final o = widget.options;
    final total = widget.totalCount;
    final done = widget.doneCount;
    final errs = widget.errorCount;
    final progress = total == 0 ? null : (done + errs) / total.toDouble();

    return Card(
      backgroundColor: theme.micaBackgroundColor,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(FluentIcons.image_pixel, size: 18),
                    const SizedBox(width: 8),
                    Text('Settings', style: theme.typography.subtitle),
                    const Spacer(),
                    if (progress != null && progress < 1.0)
                      SizedBox(height: 16, child: ProgressBar(value: progress)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollCtl,
                    child: SingleChildScrollView(
                      controller: _scrollCtl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoLabel(
                            label: 'Resize mode',
                            child: ComboBox<ResizeMode>(
                              value: o.resizeMode,
                              isExpanded: true,
                              onChanged: widget.isProcessing
                                  ? null
                                  : (v) => widget.onOptionsChanged(
                                      o.copyWith(resizeMode: v),
                                    ),
                              items: ResizeMode.values.map((m) {
                                final text = {
                                  ResizeMode.longEdge: 'Constrain long edge',
                                  ResizeMode.fit: 'Fit within WxH',
                                  ResizeMode.fill: 'Fill to WxH (crop)',
                                  ResizeMode.pad: 'Pad to WxH',
                                }[m]!;
                                return ComboBoxItem(
                                  value: m,
                                  child: Text(text),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          InfoLabel(
                            label: 'Resampling',
                            child: ComboBox<ResampleQuality>(
                              value: o.resampleQuality,
                              isExpanded: true,
                              onChanged: widget.isProcessing
                                  ? null
                                  : (v) => widget.onOptionsChanged(
                                      o.copyWith(resampleQuality: v),
                                    ),
                              items: const [
                                ComboBoxItem(
                                  value: ResampleQuality.fast,
                                  child: Text('Fast'),
                                ),
                                ComboBoxItem(
                                  value: ResampleQuality.quality,
                                  child: Text('Quality'),
                                ),
                                ComboBoxItem(
                                  value: ResampleQuality.pixel,
                                  child: Text('Pixel art (nearest)'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (o.resizeMode == ResizeMode.longEdge)
                            InfoLabel(
                              label: 'Max long edge: ${o.maxLongEdge}px',
                              child: Slider(
                                value: o.maxLongEdge.toDouble(),
                                min: 400,
                                max: 6000,
                                divisions: (6000 - 400) ~/ 100,
                                onChanged: widget.isProcessing
                                    ? null
                                    : (v) => widget.onOptionsChanged(
                                        o.copyWith(maxLongEdge: v.round()),
                                      ),
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: InfoLabel(
                                        label: 'Width',
                                        child: NumberBox(
                                          value: o.targetWidth,
                                          mode: SpinButtonPlacementMode.inline,
                                          min: 1,
                                          max: 10000,
                                          onChanged: widget.isProcessing
                                              ? null
                                              : (int? v) =>
                                                    widget.onOptionsChanged(
                                                      o.copyWith(
                                                        targetWidth:
                                                            v ?? o.targetWidth,
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: InfoLabel(
                                        label: 'Height',
                                        child: NumberBox(
                                          value: o.targetHeight,
                                          mode: SpinButtonPlacementMode.inline,
                                          min: 1,
                                          max: 10000,
                                          onChanged: widget.isProcessing
                                              ? null
                                              : (int? v) =>
                                                    widget.onOptionsChanged(
                                                      o.copyWith(
                                                        targetHeight:
                                                            v ?? o.targetHeight,
                                                      ),
                                                    ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ToggleSwitch(
                                  checked: o.noUpscale,
                                  onChanged: widget.isProcessing
                                      ? null
                                      : (v) => widget.onOptionsChanged(
                                          o.copyWith(noUpscale: v),
                                        ),
                                  content: const Text(
                                    'No upscaling',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 10),
                          InfoLabel(
                            label: 'Output format',
                            child: ComboBox<OutputFormat>(
                              value: o.preferredOutputFormat,
                              isExpanded: true,
                              onChanged: widget.isProcessing
                                  ? null
                                  : (v) => widget.onOptionsChanged(
                                      o.copyWith(preferredOutputFormat: v),
                                    ),
                              items: const [
                                ComboBoxItem(
                                  value: OutputFormat.auto,
                                  child: Text('Auto'),
                                ),
                                ComboBoxItem(
                                  value: OutputFormat.jpeg,
                                  child: Text('JPEG'),
                                ),
                                ComboBoxItem(
                                  value: OutputFormat.png,
                                  child: Text('PNG'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ToggleSwitch(
                            checked: o.convertPngToJpeg,
                            onChanged: widget.isProcessing
                                ? null
                                : (v) => widget.onOptionsChanged(
                                    o.copyWith(convertPngToJpeg: v),
                                  ),
                            content: const Text(
                              'Convert PNG to JPEG when safe',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InfoLabel(
                            label: 'JPEG quality: ${o.jpegQuality}',
                            child: Slider(
                              value: o.jpegQuality.toDouble(),
                              min: 30,
                              max: 95,
                              divisions: 65,
                              onChanged: widget.isProcessing
                                  ? null
                                  : (v) => widget.onOptionsChanged(
                                      o.copyWith(jpegQuality: v.round()),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ToggleSwitch(
                            checked: o.stripMetadata,
                            onChanged: widget.isProcessing
                                ? null
                                : (v) => widget.onOptionsChanged(
                                    o.copyWith(stripMetadata: v),
                                  ),
                            content: const Text('Strip metadata'),
                          ),
                          const SizedBox(height: 8),
                          InfoLabel(
                            label: 'Min input size (KB)',
                            child: NumberBox(
                              value: o.minInputKB,
                              mode: SpinButtonPlacementMode.inline,
                              min: 0,
                              max: 100000,
                              onChanged: widget.isProcessing
                                  ? null
                                  : (int? v) => widget.onOptionsChanged(
                                      o.copyWith(minInputKB: v ?? o.minInputKB),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          InfoLabel(
                            label: 'Filename suffix',
                            child: TextBox(
                              controller: _suffixCtl,
                              placeholder: '-compressed',
                              enabled: !widget.isProcessing,
                              onChanged: (t) => widget.onOptionsChanged(
                                o.copyWith(filenameSuffix: t),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text('Output folder'),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  o.outputDir ??
                                      'Compressed (next to each original)',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.typography.caption,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Button(
                                onPressed: widget.isProcessing
                                    ? null
                                    : widget.onPickOutput,
                                child: const Text('Choose...'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Pro optimize',
                            style: theme.typography.bodyStrong,
                          ),
                          const SizedBox(height: 8),
                          ToggleSwitch(
                            checked: o.enableJpegOptim,
                            onChanged:
                                (!widget.hasJpegoptim || widget.isProcessing)
                                ? null
                                : (v) => widget.onOptionsChanged(
                                    o.copyWith(enableJpegOptim: v),
                                  ),
                            content: Text(
                              widget.hasJpegoptim
                                  ? 'Optimize JPEG (jpegoptim)'
                                  : 'Optimize JPEG (jpegoptim not found)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ToggleSwitch(
                            checked: o.enablePngquant,
                            onChanged:
                                (!widget.hasPngquant || widget.isProcessing)
                                ? null
                                : (v) => widget.onOptionsChanged(
                                    o.copyWith(enablePngquant: v),
                                  ),
                            content: Text(
                              widget.hasPngquant
                                  ? 'Quantize PNG palette (pngquant)'
                                  : 'Quantize PNG (pngquant not found)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InfoLabel(
                                  label: 'PNGquant min',
                                  child: NumberBox(
                                    value: o.pngquantQualityMin,
                                    min: 0,
                                    max: 100,
                                    mode: SpinButtonPlacementMode.inline,
                                    onChanged:
                                        (!widget.hasPngquant ||
                                            !o.enablePngquant ||
                                            widget.isProcessing)
                                        ? null
                                        : (int? v) => widget.onOptionsChanged(
                                            o.copyWith(
                                              pngquantQualityMin:
                                                  (v ?? o.pngquantQualityMin)
                                                      .clamp(
                                                        0,
                                                        o.pngquantQualityMax,
                                                      ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InfoLabel(
                                  label: 'PNGquant max',
                                  child: NumberBox(
                                    value: o.pngquantQualityMax,
                                    min: 0,
                                    max: 100,
                                    mode: SpinButtonPlacementMode.inline,
                                    onChanged:
                                        (!widget.hasPngquant ||
                                            !o.enablePngquant ||
                                            widget.isProcessing)
                                        ? null
                                        : (int? v) => widget.onOptionsChanged(
                                            o.copyWith(
                                              pngquantQualityMax:
                                                  (v ?? o.pngquantQualityMax)
                                                      .clamp(
                                                        o.pngquantQualityMin,
                                                        100,
                                                      ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ToggleSwitch(
                            checked: o.enableOxipng,
                            onChanged:
                                (!widget.hasOxipng || widget.isProcessing)
                                ? null
                                : (v) => widget.onOptionsChanged(
                                    o.copyWith(enableOxipng: v),
                                  ),
                            content: Text(
                              widget.hasOxipng
                                  ? 'Lossless optimize PNG (oxipng)'
                                  : 'Optimize PNG (oxipng not found)',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: widget.isProcessing ? null : widget.onProcess,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isProcessing
                                ? FluentIcons.sync
                                : FluentIcons.play,
                          ),
                          const SizedBox(width: 8),
                          Text(widget.isProcessing ? 'Processing...' : 'Start'),
                        ],
                      ),
                    ),
                    Button(
                      onPressed: widget.isProcessing
                          ? widget.onCancel
                          : widget.onClearFinished,
                      child: Text(
                        widget.isProcessing ? 'Cancel' : 'Clear finished',
                      ),
                    ),
                    Button(
                      onPressed: widget.isProcessing
                          ? null
                          : widget.onClearQueue,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          errs > 0
                              ? FluentIcons.status_error_full
                              : FluentIcons.check_mark,
                          size: 16,
                          color: errs > 0
                              ? Colors.red
                              : FluentTheme.of(context).accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(formatCountSummary(done, total, errs)),
                      ],
                    ),
                    Button(
                      onPressed: () {
                        final dir = o.outputDir;
                        if (dir != null) {
                          openDirectoryInExplorer(dir);
                        } else {
                          final shellState = context
                              .findAncestorStateOfType<_AppShellState>();
                          final firstCompletedJob = shellState?.jobs.firstWhere(
                            (job) => job.outputPath != null,
                            orElse: () => Job(id: '', inputPath: ''),
                          );
                          final outputDir = firstCompletedJob?.outputPath;
                          if (outputDir != null) {
                            openDirectoryInExplorer(p.dirname(outputDir));
                          }
                        }
                      },
                      child: const Text('Open output folder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: widget.bannerMessage == null
                  ? const SizedBox.shrink()
                  : InfoBar(
                      key: const ValueKey('banner'),
                      title: Text(widget.bannerMessage!),
                      severity: widget.bannerSeverity,
                      isLong: true,
                      action: IconButton(
                        icon: const Icon(FluentIcons.clear),
                        onPressed: widget.onCloseBanner,
                      ),
                    ),
            ),
          ), //
        ],
      ),
    );
  }
}

class _JobList extends StatefulWidget {
  final List<Job> jobs;
  final bool isProcessing;
  const _JobList({required this.jobs, required this.isProcessing});

  @override
  State<_JobList> createState() => _JobListState();
}

class _JobListState extends State<_JobList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return Card(
      backgroundColor: theme.micaBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: widget.jobs.isEmpty
            ? Center(
                child: Text(
                  'No jobs queued yet.',
                  style: theme.typography.caption,
                ),
              )
            : Scrollbar(
                controller: _scrollController,
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: widget.jobs.length,
                  itemBuilder: (context, i) {
                    final j = widget.jobs[i];
                    Icon icon;
                    Color color;
                    switch (j.status) {
                      case JobStatus.queued:
                        icon = const Icon(FluentIcons.history);
                        color = Colors.grey;
                        break;
                      case JobStatus.processing:
                        icon = const Icon(FluentIcons.sync);
                        color = Colors.blue;
                        break;
                      case JobStatus.done:
                        icon = const Icon(FluentIcons.check_mark);
                        color = Colors.green;
                        break;
                      case JobStatus.error:
                        icon = const Icon(FluentIcons.status_error_full);
                        color = Colors.red;
                        break;
                    }
                    return _JobTile(
                      job: j,
                      leading: IconTheme(
                        data: IconThemeData(color: color),
                        child: icon,
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(size: 1),
                ),
              ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final Job job;
  final Widget leading;
  const _JobTile({required this.job, required this.leading});

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final name = p.basename(job.inputPath);
    final subtitle = () {
      if (job.status == JobStatus.error) {
        return Text(
          job.error ?? 'Error',
          style: TextStyle(color: Colors.red, fontSize: 11),
          overflow: TextOverflow.ellipsis,
        );
      } else if (job.note != null) {
        return Text(
          job.note!,
          style: theme.typography.caption,
          overflow: TextOverflow.ellipsis,
        );
      } else if (job.outputPath != null) {
        return Text(
          job.outputPath!,
          style: theme.typography.caption,
          overflow: TextOverflow.ellipsis,
        );
      } else {
        return Text(
          job.inputPath,
          style: theme.typography.caption,
          overflow: TextOverflow.ellipsis,
        );
      }
    }();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          SizedBox(width: 28, child: Center(child: leading)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.typography.body),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(job.status.name, style: theme.typography.caption),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}
