import 'package:fluent_ui/fluent_ui.dart';
import 'package:path/path.dart' as p;
import 'package:squeeze/core/models/job.dart';
import 'package:squeeze/core/constants/app_constants.dart';

class JobList extends StatefulWidget {
  final List<Job> jobs;
  final bool isProcessing;
  const JobList({super.key, required this.jobs, required this.isProcessing});

  @override
  State<JobList> createState() => _JobListState();
}

class _JobListState extends State<JobList> {
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
