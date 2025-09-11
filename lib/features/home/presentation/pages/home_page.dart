import 'package:fluent_ui/fluent_ui.dart';
import 'package:squeeze/core/constants/app_constants.dart';
import 'package:squeeze/features/home/presentation/widgets/drop_zone.dart';
import 'package:squeeze/features/home/presentation/widgets/job_list.dart';
import 'package:squeeze/features/home/presentation/widgets/settings_pane.dart';
import 'package:squeeze/features/home/providers/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(_update);
    _appState.detectExternalTools();
  }

  @override
  void dispose() {
    _appState.removeListener(_update);
    _appState.dispose();
    super.dispose();
  }

  void _update() => setState(() {});

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
                    child: DropZone(
                      isDraggingOver: _appState.isDraggingOver,
                      onDragEntered: _appState.onDragEntered,
                      onDragExited: _appState.onDragExited,
                      onDropPaths: _appState.addDroppedItems,
                      onPickFiles: _appState.pickFiles,
                      onPickFolder: _appState.pickFolderAndAdd,
                      imagePaths: _appState.jobs
                          .map((j) => j.inputPath)
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: JobList(
                      jobs: _appState.jobs,
                      isProcessing: _appState.isProcessing,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              flex: 4,
              child: SettingsPane(
                options: _appState.options,
                onOptionsChanged: _appState.updateOptions,
                onPickOutput: _appState.pickOutputDir,
                onProcess: _appState.processAll,
                onCancel: _appState.cancelProcessing,
                onClearQueue: _appState.clearJobs,
                onClearFinished: _appState.removeDoneAndErrors,
                isProcessing: _appState.isProcessing,
                bannerMessage: _appState.bannerMessage,
                bannerSeverity: _appState.bannerSeverity,
                onCloseBanner: _appState.clearBanner,
                doneCount: _appState.doneCount,
                totalCount: _appState.totalCount,
                errorCount: _appState.errorCount,
                hasJpegoptim: _appState.hasJpegoptim,
                hasPngquant: _appState.hasPngquant,
                hasOxipng: _appState.hasOxipng,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
