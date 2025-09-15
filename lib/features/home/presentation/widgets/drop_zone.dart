import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DropZone extends StatelessWidget {
  final bool isDraggingOver;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final Future<void> Function(List<String> paths) onDropPaths;
  final VoidCallback onPickFiles;
  final VoidCallback onPickFolder;
  final List<String> imagePaths;

  const DropZone({
    super.key,
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
                ? theme.accentColor.lighter.withAlpha(20)
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
