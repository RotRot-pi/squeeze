import 'package:fluent_ui/fluent_ui.dart';
import 'package:squeeze/core/constants/app_constants.dart';
import 'package:squeeze/core/models/options.dart';
import 'package:squeeze/core/services/file_service.dart';

class SettingsPane extends StatefulWidget {
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

  const SettingsPane({
    super.key,
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
  State<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends State<SettingsPane> {
  late final TextEditingController _suffixCtl;
  late final ScrollController _scrollCtl;

  @override
  void initState() {
    super.initState();
    _suffixCtl = TextEditingController(text: widget.options.filenameSuffix);
    _scrollCtl = ScrollController();
  }

  @override
  void didUpdateWidget(covariant SettingsPane oldWidget) {
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

  String formatCountSummary(int done, int total, int errors) {
    final parts = <String>[];
    parts.add('$done/$total done');
    if (errors > 0) parts.add('$errors error${errors > 1 ? 's' : ''}');
    return parts.join(' • ');
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
                          // final shellState = context
                          //     .findAncestorStateOfType<_HomePageState>();
                          // final firstCompletedJob = shellState?.jobs.firstWhere(
                          //   (job) => job.outputPath != null,
                          //   orElse: () => Job(id: '', inputPath: ''),
                          // );
                          // final outputDir = firstCompletedJob?.outputPath;
                          // if (outputDir != null) {
                          //   openDirectoryInExplorer(p.dirname(outputDir));
                          // }
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
