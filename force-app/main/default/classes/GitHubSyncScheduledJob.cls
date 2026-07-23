/**
 * @description Scheduled job for nightly GitHub synchronization
 * @author DevOps Compass Team
 * @date 2026
 */
public class GitHubSyncScheduledJob implements Schedulable {

    /**
     * @description Execute scheduled sync job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        // Run the sync
        GitHubSyncOrchestrator.SyncResult result = GitHubSyncOrchestrator.syncAllRepositoriesScheduled();

        // Send email notification
        sendNotificationEmail(result);

        // Clean up old sync job records (older than 10 days)
        GitHubSyncOrchestrator.deleteOldSyncJobs(10);
    }

    /**
     * @description Send email notification to admins
     * @param result Sync result
     */
    private void sendNotificationEmail(GitHubSyncOrchestrator.SyncResult result) {
        // Get all users with DevOps_Compass_Administrator permission set
        List<PermissionSetAssignment> assignments = [
            SELECT AssigneeId, Assignee.Email, Assignee.Name
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'DevOps_Compass_Administrator'
            AND Assignee.IsActive = true
            AND Assignee.Email != null
        ];

        if (assignments.isEmpty()) {
            DevOpsLogger.warn('No active administrators found for sync notification');
            return;
        }

        // Collect email addresses
        List<String> toAddresses = new List<String>();
        for (PermissionSetAssignment psa : assignments) {
            toAddresses.add(psa.Assignee.Email);
        }

        // Build email content
        String subject = result.success && String.isBlank(result.errorMessage)
            ? 'DevOps Compass: Nightly Sync Completed Successfully'
            : 'DevOps Compass: Nightly Sync Completed with Errors';

        String body = buildEmailBody(result);

        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(toAddresses);
        email.setSubject(subject);
        email.setPlainTextBody(body);
        email.setSaveAsActivity(false);

        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
            DevOpsLogger.info('Sync notification email sent to ' + toAddresses.size() + ' administrators');
        } catch (Exception ex) {
            DevOpsLogger.error('Failed to send sync notification email', ex);
        }
    }

    /**
     * @description Build simple text email body
     * @param result Sync result
     * @return String email body
     */
    private String buildEmailBody(GitHubSyncOrchestrator.SyncResult result) {
        String body = 'DevOps Compass Nightly Sync Results\n';
        body += '=====================================\n\n';

        body += 'Repositories Synced: ' + result.repositoriesSynced + '\n';
        body += 'Pull Requests Synced: ' + result.pullRequestsSynced + '\n';
        body += 'Contributors Synced: ' + result.contributorsSynced + '\n\n';

        if (String.isNotBlank(result.errorMessage)) {
            body += 'ERRORS:\n';
            body += '-------\n';
            body += result.errorMessage + '\n\n';
        } else {
            body += 'No errors.\n\n';
        }

        body += 'Sync completed at: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n';

        return body;
    }

    /**
     * @description Schedule the nightly sync job (run at 2 AM daily)
     * @return String Scheduled job ID
     */
    public static String scheduleNightlySync() {
        // Remove any existing scheduled jobs
        List<CronTrigger> existingJobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'DevOps Compass Nightly Sync'
        ];

        for (CronTrigger job : existingJobs) {
            System.abortJob(job.Id);
        }

        // Schedule for 2 AM daily (0 0 2 * * ?)
        String cronExp = '0 0 2 * * ?';
        String jobName = 'DevOps Compass Nightly Sync';

        return System.schedule(jobName, cronExp, new GitHubSyncScheduledJob());
    }
}
