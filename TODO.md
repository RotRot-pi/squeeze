# FIX

**Problem:**
When the process happens the first time, you need to clear and select again to be able to start another process even on the same file.

**More details:**
The problem lies in the processAll method within the AppState class
  (lib/features/home/providers/app_state.dart). This method is designed to only process jobs that have the status
  JobStatus.queued. After the first time you run the process, all the jobs in the list are updated to either
  JobStatus.done or JobStatus.error.

  When you try to start the process again without clearing the list, the processAll method finds no jobs with the
  queued status and therefore does nothing. This is why you are forced to clear the list and add the files again
  to re-process them.

**Suggested Solution:**

  To fix this, you should modify the processAll method. Before it starts processing, it should first iterate
  through all the jobs currently in the list. For any job that is marked as done or error, its status should be
  reset to queued. This change will ensure that all files in the list are ready to be processed every time you
  initiate the action, resolving the issue.
