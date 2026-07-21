/**
 * @description Service class for Pull Request business logic
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class PullRequestService {

    /**
     * @description Upsert pull request from GitHub data
     * @param githubData PR data from GitHub API
     * @param repositoryId Salesforce Repository ID
     * @return Pull_Request__c
     */
    public static Pull_Request__c upsertFromGitHub(Map<String, Object> githubData, Id repositoryId) {
        String externalId = String.valueOf(githubData.get('id'));

        Pull_Request__c pr = PullRequestSelector.getByExternalId(externalId);

        if (pr == null) {
            pr = new Pull_Request__c();
            pr.External_Id__c = externalId;
        }

        pr.PR_Number__c = (Integer) githubData.get('number');
        pr.Repository__c = repositoryId;
        pr.Title__c = truncateString((String) githubData.get('title'), 255);
        pr.Author__c = getAuthorFromGitHub(githubData);
        pr.State__c = capitalizeState((String) githubData.get('state'));
        pr.Source_Branch__c = getHeadBranch(githubData);
        pr.Target_Branch__c = getBaseBranch(githubData);
        pr.Created_Date__c = parseGitHubDateTime((String) githubData.get('created_at'));
        pr.Closed_Date__c = parseGitHubDateTime((String) githubData.get('closed_at'));
        pr.Merged_Date__c = parseGitHubDateTime((String) githubData.get('merged_at'));
        pr.URL__c = (String) githubData.get('html_url');

        // These may come from detailed PR endpoint
        pr.Review_Count__c = (Integer) githubData.get('review_comments');
        pr.Commit_Count__c = (Integer) githubData.get('commits');
        pr.Files_Changed__c = (Integer) githubData.get('changed_files');
        pr.Lines_Added__c = (Integer) githubData.get('additions');
        pr.Lines_Removed__c = (Integer) githubData.get('deletions');

        upsert pr External_Id__c;

        return pr;
    }

    /**
     * @description Bulk upsert pull requests from GitHub data
     * @param githubDataList List of GitHub PR data
     * @param repositoryId Salesforce Repository ID
     * @return List<Pull_Request__c>
     */
    public static List<Pull_Request__c> bulkUpsertFromGitHub(List<Object> githubDataList, Id repositoryId) {
        List<Pull_Request__c> prs = new List<Pull_Request__c>();

        for (Object obj : githubDataList) {
            Map<String, Object> githubData = (Map<String, Object>) obj;
            prs.add(upsertFromGitHub(githubData, repositoryId));
        }

        return prs;
    }

    /**
     * @description Extract author from GitHub data
     */
    private static String getAuthorFromGitHub(Map<String, Object> githubData) {
        Map<String, Object> userData = (Map<String, Object>) githubData.get('user');
        return userData != null ? (String) userData.get('login') : 'Unknown';
    }

    /**
     * @description Get head branch from GitHub data
     */
    private static String getHeadBranch(Map<String, Object> githubData) {
        Map<String, Object> head = (Map<String, Object>) githubData.get('head');
        return head != null ? (String) head.get('ref') : null;
    }

    /**
     * @description Get base branch from GitHub data
     */
    private static String getBaseBranch(Map<String, Object> githubData) {
        Map<String, Object> base = (Map<String, Object>) githubData.get('base');
        return base != null ? (String) base.get('ref') : null;
    }

    /**
     * @description Parse GitHub ISO datetime string
     */
    private static Datetime parseGitHubDateTime(String datetimeStr) {
        if (String.isBlank(datetimeStr)) {
            return null;
        }

        try {
            return (Datetime) JSON.deserialize('"' + datetimeStr + '"', Datetime.class);
        } catch (Exception ex) {
            DevOpsLogger.error('Failed to parse datetime: ' + datetimeStr, ex);
            return null;
        }
    }

    /**
     * @description Capitalize state for picklist
     */
    private static String capitalizeState(String state) {
        if (String.isBlank(state)) {
            return 'Open';
        }
        return state.substring(0, 1).toUpperCase() + state.substring(1).toLowerCase();
    }

    /**
     * @description Truncate string to max length
     */
    private static String truncateString(String str, Integer maxLength) {
        if (String.isBlank(str)) {
            return str;
        }
        return str.length() > maxLength ? str.substring(0, maxLength) : str;
    }

    /**
     * @description Get open pull requests (for LWC)
     * @param repositoryId Optional repository ID filter
     * @return List<Pull_Request__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<Pull_Request__c> getOpenPullRequests(Id repositoryId) {
        return PullRequestSelector.getOpenPullRequests(repositoryId);
    }

    /**
     * @description Get recently merged pull requests (for LWC)
     * @param repositoryId Optional repository ID filter
     * @param days Number of days to look back
     * @return List<Pull_Request__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<Pull_Request__c> getRecentlyMergedPullRequests(Id repositoryId, Integer days) {
        Date startDate = Date.today().addDays(-days);
        Date endDate = Date.today();
        return PullRequestSelector.getMergedInDateRange(startDate, endDate);
    }
}
