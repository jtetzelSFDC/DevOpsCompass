/**
 * @description Orchestrates GitHub synchronization across repositories
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class GitHubSyncOrchestrator {

    /**
     * @description Result class for sync operations
     */
    public class SyncResult {
        @AuraEnabled
        @InvocableVariable(label='Success' description='Whether the sync completed successfully')
        public Boolean success;

        @AuraEnabled
        @InvocableVariable(label='Repositories Synced' description='Number of repositories synced')
        public Integer repositoriesSynced;

        @AuraEnabled
        @InvocableVariable(label='Pull Requests Synced' description='Number of pull requests synced')
        public Integer pullRequestsSynced;

        @AuraEnabled
        @InvocableVariable(label='Contributors Synced' description='Number of contributors synced')
        public Integer contributorsSynced;

        @AuraEnabled
        @InvocableVariable(label='Error Message' description='Error details if sync failed')
        public String errorMessage;

        @AuraEnabled
        @InvocableVariable(label='Sync Job ID' description='ID of the Sync_Job__c record')
        public String syncJobId;

        public SyncResult() {
            this.success = true;
            this.repositoriesSynced = 0;
            this.pullRequestsSynced = 0;
            this.contributorsSynced = 0;
            this.errorMessage = '';
        }
    }

    /**
     * @description Invocable method to sync all active repositories (for Flow)
     * @return List<SyncResult> Sync results
     */
    @InvocableMethod(label='Sync All GitHub Repositories'
                     description='Syncs all active repositories with GitHub data'
                     category='DevOps Compass')
    public static List<SyncResult> syncAllRepositories() {
        SyncResult result = new SyncResult();
        Sync_Job__c syncJob;

        try {
            // Get all active repositories
            List<Repository__c> activeRepos = RepositorySelector.getActiveRepositories();

            if (activeRepos.isEmpty()) {
                result.errorMessage = 'No active repositories found to sync';
                // Create sync job AFTER checking (no callouts made yet)
                syncJob = createSyncJob();
                updateSyncJob(syncJob, result, 'Completed');
                return new List<SyncResult>{ result };
            }

            // Sync each repository and its data (CALLOUTS HAPPEN HERE)
            for (Repository__c repo : activeRepos) {
                try {
                    // Sync repository metadata
                    String[] parts = repo.External_Id__c.split('/');
                    String owner = parts[0];
                    String repoName = parts[1];

                    RepositorySyncService.syncRepository(owner, repoName);
                    result.repositoriesSynced++;

                    // Sync pull requests
                    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');
                    result.pullRequestsSynced += prs.size();

                    // Sync contributors
                    List<Contributor__c> contributors = ContributorSyncService.syncContributors(repo.Id);
                    result.contributorsSynced += contributors.size();

                } catch (Exception repoEx) {
                    // Log individual repo error but continue with others
                    String errorMsg = 'Error syncing ' + repo.Name + ': ' + repoEx.getMessage();
                    DevOpsLogger.error(errorMsg, repoEx);

                    if (String.isBlank(result.errorMessage)) {
                        result.errorMessage = errorMsg;
                    } else {
                        result.errorMessage += '\n' + errorMsg;
                    }
                }
            }

            // Create sync job AFTER all callouts complete
            syncJob = createSyncJob();

            // Update sync job with results
            String status = String.isBlank(result.errorMessage) ? 'Completed' : 'Completed with Errors';
            updateSyncJob(syncJob, result, status);
            result.syncJobId = syncJob.Id;

        } catch (Exception ex) {
            result.success = false;
            result.errorMessage = 'Sync failed: ' + ex.getMessage();
            DevOpsLogger.error('GitHub sync orchestration failed', ex);

            // Create sync job if it doesn't exist yet
            if (syncJob == null) {
                syncJob = createSyncJob();
            }
            updateSyncJob(syncJob, result, 'Failed');
        }

        return new List<SyncResult>{ result };
    }

    /**
     * @description Sync all repositories (non-invocable version for scheduled job and LWC)
     * Uses queueable to avoid DML before callout issues
     * @return SyncResult
     */
    @AuraEnabled
    public static SyncResult syncAllRepositoriesScheduled() {
        SyncResult result = new SyncResult();

        try {
            // Create sync job immediately
            Sync_Job__c syncJob = createSyncJob();
            result.syncJobId = syncJob.Id;

            // Enqueue the queueable job to perform the actual sync
            System.enqueueJob(new GitHubSyncQueueable(syncJob.Id));

            result.success = true;
            result.errorMessage = 'Sync job started. Check the Sync Jobs tab for results.';

        } catch (Exception ex) {
            result.success = false;
            result.errorMessage = 'Failed to start sync: ' + ex.getMessage();
            DevOpsLogger.error('Failed to enqueue sync job', ex);
        }

        return result;
    }

    /**
     * @description Get sync job status for polling
     * @param syncJobId ID of Sync_Job__c record
     * @return Sync_Job__c
     */
    @AuraEnabled(cacheable=false)
    public static Sync_Job__c getSyncJobStatus(Id syncJobId) {
        try {
            return [
                SELECT Id, Status__c, Records_Processed__c, Records_Inserted__c,
                       Records_Updated__c, Repositories_Synced__c, Pull_Requests_Synced__c,
                       Open_Pull_Requests__c, Contributors_Synced__c, Error_Log__c, Start_Time__c, End_Time__c
                FROM Sync_Job__c
                WHERE Id = :syncJobId
                LIMIT 1
            ];
        } catch (Exception ex) {
            DevOpsLogger.error('Failed to get sync job status', ex);
            return null;
        }
    }

    /**
     * @description Create a new Sync_Job__c record
     * @return Sync_Job__c
     */
    private static Sync_Job__c createSyncJob() {
        Sync_Job__c job = new Sync_Job__c(
            Job_Type__c = 'Full Sync',
            Status__c = 'In Progress',
            Start_Time__c = System.now(),
            Records_Processed__c = 0,
            Records_Inserted__c = 0,
            Records_Updated__c = 0,
            Error_Count__c = 0
        );
        insert job;
        return job;
    }

    /**
     * @description Update Sync_Job__c record with results
     * @param job Sync job record
     * @param result Sync result
     * @param status Final status
     */
    private static void updateSyncJob(Sync_Job__c job, SyncResult result, String status) {
        job.Status__c = status;
        job.End_Time__c = System.now();
        job.Records_Processed__c = result.repositoriesSynced + result.pullRequestsSynced + result.contributorsSynced;
        job.Error_Count__c = String.isBlank(result.errorMessage) ? 0 : 1;
        job.Error_Log__c = result.errorMessage;

        update job;
    }

    /**
     * @description Delete Sync_Job__c records older than specified days
     * @param daysToKeep Number of days to keep records
     */
    public static void deleteOldSyncJobs(Integer daysToKeep) {
        Date cutoffDate = Date.today().addDays(-daysToKeep);
        Datetime cutoffDatetime = Datetime.newInstance(cutoffDate, Time.newInstance(0, 0, 0, 0));

        List<Sync_Job__c> oldJobs = [
            SELECT Id
            FROM Sync_Job__c
            WHERE CreatedDate < :cutoffDatetime
            LIMIT 10000
        ];

        if (!oldJobs.isEmpty()) {
            delete oldJobs;
            DevOpsLogger.info('Deleted ' + oldJobs.size() + ' old sync job records');
        }
    }
}
