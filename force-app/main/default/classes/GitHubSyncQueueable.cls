/**
 * @description Queueable class for GitHub synchronization operations
 * @author DevOps Compass Team
 * @date 2026
 */
public class GitHubSyncQueueable implements Queueable, Database.AllowsCallouts {

    private Id syncJobId;

    public GitHubSyncQueueable(Id syncJobId) {
        this.syncJobId = syncJobId;
    }

    public void execute(QueueableContext context) {
        Integer repositoriesSynced = 0;
        Integer pullRequestsSynced = 0;
        Integer openPullRequests = 0;
        Integer contributorsSynced = 0;
        String errorMessage = '';

        try {
            // Get all active repositories
            List<Repository__c> activeRepos = RepositorySelector.getActiveRepositories();

            if (activeRepos.isEmpty()) {
                errorMessage = 'No active repositories found to sync';
                updateSyncJob('Completed', 0, 0, 0, 0, 0, errorMessage);
                return;
            }

            // PHASE 1: Fetch ALL data from GitHub (callouts only, no DML)
            Map<String, Map<String, Object>> repoDataMap = new Map<String, Map<String, Object>>();
            Map<String, List<Object>> prDataMap = new Map<String, List<Object>>();
            Map<String, List<Object>> contributorDataMap = new Map<String, List<Object>>();

            for (Repository__c repo : activeRepos) {
                try {
                    String[] parts = repo.External_Id__c.split('/');
                    String owner = parts[0];
                    String repoName = parts[1];
                    String repoKey = owner + '/' + repoName;

                    // Fetch repository data
                    Map<String, Object> repoData = GitHubApiClient.getRepository(owner, repoName);
                    repoDataMap.put(repoKey, repoData);

                    // Fetch PR data
                    List<Object> prData = GitHubApiClient.getPullRequests(owner, repoName, 'all', 100, 1);
                    prDataMap.put(repoKey, prData);

                    // Fetch contributor data
                    List<Object> contributorData = GitHubApiClient.getContributors(owner, repoName, 100, 1);
                    contributorDataMap.put(repoKey, contributorData);

                } catch (Exception calloutEx) {
                    String errorMsg = 'Error fetching data for ' + repo.Name + ': ' + calloutEx.getMessage();
                    DevOpsLogger.error(errorMsg, calloutEx);
                    if (String.isBlank(errorMessage)) {
                        errorMessage = errorMsg;
                    } else {
                        errorMessage += '\n' + errorMsg;
                    }
                }
            }

            // PHASE 2: Process and upsert all data (DML only, no callouts)
            for (Repository__c repo : activeRepos) {
                try {
                    String[] parts = repo.External_Id__c.split('/');
                    String owner = parts[0];
                    String repoName = parts[1];
                    String repoKey = owner + '/' + repoName;

                    // Skip if we didn't fetch data for this repo
                    if (!repoDataMap.containsKey(repoKey)) {
                        continue;
                    }

                    // Process repository (calls private method that does DML)
                    Repository__c updatedRepo = upsertRepositoryData(repoDataMap.get(repoKey), owner, repoName);
                    repositoriesSynced++;

                    // Process PRs
                    if (prDataMap.containsKey(repoKey)) {
                        List<Pull_Request__c> prs = upsertPullRequestData(prDataMap.get(repoKey), updatedRepo.Id);
                        pullRequestsSynced += prs.size();

                        // Count open PRs
                        for (Pull_Request__c pr : prs) {
                            if (pr.State__c == 'open') {
                                openPullRequests++;
                            }
                        }
                    }

                    // Process contributors
                    if (contributorDataMap.containsKey(repoKey)) {
                        List<Contributor__c> contributors = upsertContributorData(contributorDataMap.get(repoKey), updatedRepo.Id);
                        contributorsSynced += contributors.size();
                    }

                } catch (Exception dmlEx) {
                    String errorMsg = 'Error saving data for ' + repo.Name + ': ' + dmlEx.getMessage();
                    DevOpsLogger.error(errorMsg, dmlEx);
                    if (String.isBlank(errorMessage)) {
                        errorMessage = errorMsg;
                    } else {
                        errorMessage += '\n' + errorMsg;
                    }
                }
            }

            // Update sync job with results
            String status = String.isBlank(errorMessage) ? 'Completed' : 'Completed with Errors';
            Integer totalRecords = repositoriesSynced + pullRequestsSynced + contributorsSynced;
            updateSyncJob(status, totalRecords, repositoriesSynced, pullRequestsSynced, openPullRequests, contributorsSynced, errorMessage);

        } catch (Exception ex) {
            errorMessage = 'Sync failed: ' + ex.getMessage();
            DevOpsLogger.error('GitHub sync queueable failed', ex);
            updateSyncJob('Failed', 0, 0, 0, 0, 0, errorMessage);
        }
    }

    // Helper methods to process fetched data (DML only, no callouts)
    private Repository__c upsertRepositoryData(Map<String, Object> repoData, String owner, String repoName) {
        String externalId = owner + '/' + repoName;
        List<Repository__c> existing = RepositorySelector.getByExternalId(new Set<String>{externalId});

        Repository__c repo = existing.isEmpty() ? new Repository__c() : existing[0];
        repo.Name = (String) repoData.get('name');
        repo.Description__c = (String) repoData.get('description');
        repo.Repository_URL__c = (String) repoData.get('html_url');
        repo.Default_Branch__c = (String) repoData.get('default_branch');
        repo.Provider__c = 'GitHub';
        repo.Owner__c = owner;
        repo.External_Id__c = externalId;
        repo.Active__c = true;

        upsert repo External_Id__c;
        return repo;
    }

    private List<Pull_Request__c> upsertPullRequestData(List<Object> prDataList, Id repositoryId) {
        Map<String, Pull_Request__c> prsByExternalId = new Map<String, Pull_Request__c>();
        Set<String> externalIds = new Set<String>();

        for (Object prObj : prDataList) {
            Map<String, Object> prData = (Map<String, Object>) prObj;
            String prNumber = String.valueOf(prData.get('number'));
            externalIds.add(repositoryId + '-' + prNumber);
        }

        List<Pull_Request__c> existingPRs = PullRequestSelector.getByExternalId(externalIds);
        for (Pull_Request__c pr : existingPRs) {
            prsByExternalId.put(pr.External_Id__c, pr);
        }

        List<Pull_Request__c> prsToUpsert = new List<Pull_Request__c>();
        for (Object prObj : prDataList) {
            Map<String, Object> prData = (Map<String, Object>) prObj;
            String prNumber = String.valueOf(prData.get('number'));
            String externalId = repositoryId + '-' + prNumber;

            Pull_Request__c pr = prsByExternalId.containsKey(externalId) ? prsByExternalId.get(externalId) : new Pull_Request__c();
            pr.Repository__c = repositoryId;
            pr.External_Id__c = externalId;
            pr.Title__c = (String) prData.get('title');
            pr.State__c = (String) prData.get('state');
            pr.PR_Number__c = Integer.valueOf(prData.get('number'));
            pr.URL__c = (String) prData.get('html_url');

            prsToUpsert.add(pr);
        }

        if (!prsToUpsert.isEmpty()) {
            upsert prsToUpsert External_Id__c;
        }
        return prsToUpsert;
    }

    private List<Contributor__c> upsertContributorData(List<Object> contributorDataList, Id repositoryId) {
        Map<String, Contributor__c> contributorsByExternalId = new Map<String, Contributor__c>();
        Set<String> externalIds = new Set<String>();

        for (Object contribObj : contributorDataList) {
            Map<String, Object> contribData = (Map<String, Object>) contribObj;
            String username = (String) contribData.get('login');
            externalIds.add(repositoryId + '-' + username);
        }

        List<Contributor__c> existingContributors = ContributorSelector.getByExternalId(externalIds);
        for (Contributor__c contrib : existingContributors) {
            contributorsByExternalId.put(contrib.External_Id__c, contrib);
        }

        List<Contributor__c> contributorsToUpsert = new List<Contributor__c>();
        for (Object contribObj : contributorDataList) {
            Map<String, Object> contribData = (Map<String, Object>) contribObj;
            String username = (String) contribData.get('login');
            String externalId = repositoryId + '-' + username;

            Contributor__c contrib = contributorsByExternalId.containsKey(externalId) ? contributorsByExternalId.get(externalId) : new Contributor__c();
            // Only set Repository__c on new records (master-detail can't be changed)
            if (contrib.Id == null) {
                contrib.Repository__c = repositoryId;
            }
            contrib.External_Id__c = externalId;
            contrib.Name = username;
            contrib.GitHub_Username__c = username;
            contrib.Avatar_URL__c = (String) contribData.get('avatar_url');
            contrib.Profile_URL__c = (String) contribData.get('html_url');

            contributorsToUpsert.add(contrib);
        }

        if (!contributorsToUpsert.isEmpty()) {
            upsert contributorsToUpsert External_Id__c;
        }
        return contributorsToUpsert;
    }

    private void updateSyncJob(String status, Integer recordsProcessed, Integer repositoriesSynced,
                               Integer pullRequestsSynced, Integer openPullRequests, Integer contributorsSynced, String errorLog) {
        Sync_Job__c job = [SELECT Id FROM Sync_Job__c WHERE Id = :syncJobId LIMIT 1];
        job.Status__c = status;
        job.End_Time__c = System.now();
        job.Records_Processed__c = recordsProcessed;
        job.Repositories_Synced__c = repositoriesSynced;
        job.Pull_Requests_Synced__c = pullRequestsSynced;
        job.Open_Pull_Requests__c = openPullRequests;
        job.Contributors_Synced__c = contributorsSynced;
        job.Error_Count__c = String.isBlank(errorLog) ? 0 : 1;
        job.Error_Log__c = errorLog;
        update job;
    }
}
