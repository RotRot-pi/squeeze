import 'package:squeeze/core/constants/app_constants.dart';

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
