/**
 * @description Service class for synchronizing GitHub pull requests into Salesforce
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class PullRequestSyncService {

    private static final Integer DEFAULT_PER_PAGE = 100;
    private static final Integer DEFAULT_PAGE = 1;

    /**
     * @description Sync pull requests for a repository
     * @param repositoryId Salesforce Repository__c record ID
     * @param state PR state filter (open, closed, all)
     * @return List<Pull_Request__c> Synced pull requests
     */
    public static List<Pull_Request__c> syncPullRequests(Id repositoryId, String state) {
        try {
            // Get repository record
            Repository__c repo = RepositorySelector.getById(new Set<Id>{repositoryId})[0];

            // Extract owner and repo name from External_Id__c (format: owner/repoName)
            String[] parts = repo.External_Id__c.split('/');
            String owner = parts[0];
            String repoName = parts[1];

            // Fetch pull requests from GitHub
            List<Object> prDataList = GitHubApiClient.getPullRequests(
                owner, repoName, state, DEFAULT_PER_PAGE, DEFAULT_PAGE
            );

            // Upsert pull request records
            List<Pull_Request__c> pullRequests = upsertPullRequests(prDataList, repo.Id);

            // Log successful sync
            DevOpsLogger.info('Successfully synced ' + pullRequests.size() + ' pull requests for repository: ' + repo.Name);

            return pullRequests;

        } catch (Exception e) {
            DevOpsLogger.error('Failed to sync pull requests for repository ID: ' + repositoryId, e);
            throw new DevOpsCompassException('Pull request sync failed: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Sync pull requests for multiple repositories
     * @param repositoryIds Set of Repository__c record IDs
     * @param state PR state filter (open, closed, all)
     * @return List<Pull_Request__c> All synced pull requests
     */
    public static List<Pull_Request__c> syncPullRequestsForRepositories(Set<Id> repositoryIds, String state) {
        List<Pull_Request__c> allPullRequests = new List<Pull_Request__c>();

        for (Id repoId : repositoryIds) {
            try {
                List<Pull_Request__c> prs = syncPullRequests(repoId, state);
                allPullRequests.addAll(prs);
            } catch (Exception e) {
                // Continue syncing other repositories even if one fails
                DevOpsLogger.error('Failed to sync pull requests for repository ID: ' + repoId, e);
            }
        }

        return allPullRequests;
    }

    /**
     * @description Upsert pull request records from GitHub data
     * @param prDataList List of GitHub API PR responses
     * @param repositoryId Salesforce Repository__c ID
     * @return List<Pull_Request__c>
     */
    private static List<Pull_Request__c> upsertPullRequests(List<Object> prDataList, Id repositoryId) {
        Map<String, Pull_Request__c> prsByExternalId = new Map<String, Pull_Request__c>();

        // Get existing PRs
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

        // Create or update PRs
        List<Pull_Request__c> prsToUpsert = new List<Pull_Request__c>();

        for (Object prObj : prDataList) {
            Map<String, Object> prData = (Map<String, Object>) prObj;
            Pull_Request__c pr = mapGitHubDataToPR(prData, repositoryId, prsByExternalId);
            prsToUpsert.add(pr);
        }

        if (!prsToUpsert.isEmpty()) {
            upsert prsToUpsert External_Id__c;
        }

        return prsToUpsert;
    }

    /**
     * @description Map GitHub PR data to Salesforce Pull_Request__c record
     * @param prData GitHub API PR data
     * @param repositoryId Repository__c ID
     * @param existingPRs Map of existing PRs by external ID
     * @return Pull_Request__c
     */
    private static Pull_Request__c mapGitHubDataToPR(
        Map<String, Object> prData,
        Id repositoryId,
        Map<String, Pull_Request__c> existingPRs
    ) {
        Integer prNumber = (Integer) prData.get('number');
        String externalId = repositoryId + '-' + prNumber;

        Pull_Request__c pr = existingPRs.containsKey(externalId)
            ? existingPRs.get(externalId)
            : new Pull_Request__c();

        // Map fields
        pr.Title__c = (String) prData.get('title');
        pr.PR_Number__c = prNumber;
        pr.State__c = (String) prData.get('state');
        pr.Repository__c = repositoryId;
        pr.External_Id__c = externalId;

        // Extract branch names
        Map<String, Object> head = (Map<String, Object>) prData.get('head');
        Map<String, Object> base = (Map<String, Object>) prData.get('base');
        if (head != null) {
            pr.Source_Branch__c = (String) head.get('ref');
        }
        if (base != null) {
            pr.Target_Branch__c = (String) base.get('ref');
        }

        // Extract author
        Map<String, Object> user = (Map<String, Object>) prData.get('user');
        if (user != null) {
            pr.Author__c = (String) user.get('login');
        }

        // Parse dates
        String createdAt = (String) prData.get('created_at');
        String mergedAt = (String) prData.get('merged_at');
        String closedAt = (String) prData.get('closed_at');

        if (String.isNotBlank(createdAt)) {
            pr.Created_Date__c = parseGitHubDate(createdAt);
        }
        if (String.isNotBlank(mergedAt)) {
            pr.Merged_Date__c = parseGitHubDate(mergedAt);
        }
        if (String.isNotBlank(closedAt)) {
            pr.Closed_Date__c = parseGitHubDate(closedAt);
        }

        return pr;
    }

    /**
     * @description Parse GitHub ISO 8601 date string to Datetime
     * @param dateString GitHub date string
     * @return Datetime
     */
    private static Datetime parseGitHubDate(String dateString) {
        try {
            return Datetime.valueOfGmt(dateString.replace('T', ' ').replace('Z', ''));
        } catch (Exception e) {
            return null;
        }
    }
}
