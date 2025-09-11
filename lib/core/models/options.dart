import 'package:squeeze/core/constants/app_constants.dart';

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
