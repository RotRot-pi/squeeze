import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:squeeze/core/constants/app_constants.dart';
import 'package:squeeze/core/models/job.dart';
import 'package:squeeze/core/models/options.dart';
import 'package:squeeze/core/services/file_service.dart';
import 'package:squeeze/core/services/image_processing_service.dart';
import 'package:squeeze/core/services/tool_service.dart';

class AppState extends ChangeNotifier {
  Options _options = Options.defaultOptions;
  Options get options => _options;

  final List<Job> _jobs = [];
  List<Job> get jobs => _jobs;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  bool _isDraggingOver = false;
  bool get isDraggingOver => _isDraggingOver;

  String? _bannerMessage;
  String? get bannerMessage => _bannerMessage;

  InfoBarSeverity _bannerSeverity = InfoBarSeverity.info;
  InfoBarSeverity get bannerSeverity => _bannerSeverity;

  Timer? _bannerTimer;
  CancelToken? _token;

  bool _hasJpegoptim = false;
  bool get hasJpegoptim => _hasJpegoptim;

  bool _hasPngquant = false;
  bool get hasPngquant => _hasPngquant;

  bool _hasOxipng = false;
  bool get hasOxipng => _hasOxipng;

  int get totalCount => _jobs.length;
  int get doneCount => _jobs.where((j) => j.status == JobStatus.done).length;
  int get errorCount => _jobs.where((j) => j.status == JobStatus.error).length;

  void onDragEntered() {
    _isDraggingOver = true;
    notifyListeners();
  }

  void onDragExited() {
    _isDraggingOver = false;
    notifyListeners();
  }

  void showBanner(
    String message,
    InfoBarSeverity severity, {
    Duration autoHide = const Duration(seconds: 3),
  }) {
    _bannerTimer?.cancel();
    _bannerMessage = message;
    _bannerSeverity = severity;
    notifyListeners();
    _bannerTimer = Timer(autoHide, () {
      _bannerMessage = null;
      notifyListeners();
    });
  }

  void clearBanner() {
    _bannerMessage = null;
    notifyListeners();
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
      if (!_jobs.any((j) => j.inputPath == path)) {
        _jobs.add(Job(id: path, inputPath: path));
        added++;
      }
    }
    notifyListeners();
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
      _options = _options.copyWith(outputDir: dir);
      notifyListeners();
    }
  }

  void clearJobs() {
    _jobs.clear();
    notifyListeners();
  }

  void removeDoneAndErrors() {
    _jobs.removeWhere(
      (j) => j.status == JobStatus.done || j.status == JobStatus.error,
    );
    notifyListeners();
  }

  Future<void> processAll() async {
    if (_isProcessing || _jobs.isEmpty) return;
    _isProcessing = true;
    notifyListeners();
    _token = CancelToken();
    final sem = _Semaphore(
      math.max(1, math.min(Platform.numberOfProcessors, 6)),
    );
    final sw = Stopwatch()..start();
    final futures = <Future<void>>[];

    for (final job in _jobs.where((j) => j.status == JobStatus.queued)) {
      if (_token!.canceled) break;
      await sem.acquire();
      job.status = JobStatus.processing;
      notifyListeners();
      futures.add(() async {
        try {
          if (_token!.canceled) return;
          final res = await processImage(job.inputPath, _options);
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
          notifyListeners();
        } finally {
          sem.release();
        }
      }());
    }

    await Future.wait(futures);
    sw.stop();
    _isProcessing = false;
    notifyListeners();
    showBanner(
      'Finished in ${sw.elapsed.inSeconds}s • ${formatCountSummary(doneCount, totalCount, errorCount)}',
      errorCount > 0 ? InfoBarSeverity.warning : InfoBarSeverity.success,
    );
  }

  void cancelProcessing() {
    _token?.cancel();
    showBanner('Cancel requested', InfoBarSeverity.info);
  }

  void updateOptions(Options newOptions) {
    _options = newOptions;
    notifyListeners();
  }

  Future<void> detectExternalTools() async {
    final j = await cmdOnPath('jpegoptim');
    final pz = await cmdOnPath('pngquant');
    final ox = await cmdOnPath('oxipng');
    _hasJpegoptim = j;
    _hasPngquant = pz;
    _hasOxipng = ox;
    if (!j && _options.enableJpegOptim) {
      _options = _options.copyWith(enableJpegOptim: false);
    }
    if (!pz && _options.enablePngquant) {
      _options = _options.copyWith(enablePngquant: false);
    }
    if (!ox && _options.enableOxipng) {
      _options = _options.copyWith(enableOxipng: false);
    }
    notifyListeners();
  }

  String formatCountSummary(int done, int total, int errors) {
    final parts = <String>[];
    parts.add('$done/$total done');
    if (errors > 0) parts.add('$errors error${errors > 1 ? 's' : ''}');
    return parts.join(' • ');
  }
}

class CancelToken {
  bool _canceled = false;
  bool get canceled => _canceled;
  void cancel() => _canceled = true;
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
