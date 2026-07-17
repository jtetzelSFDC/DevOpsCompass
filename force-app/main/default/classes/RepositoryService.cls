/**
 * @description Service class for Repository business logic
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class RepositoryService {

    /**
     * @description Upsert repository from GitHub data
     * @param githubData Repository data from GitHub API
     * @return Repository__c
     */
    public static Repository__c upsertFromGitHub(Map<String, Object> githubData) {
        String externalId = String.valueOf(githubData.get('id'));

        Repository__c repo = RepositorySelector.getByExternalId(externalId);

        if (repo == null) {
            repo = new Repository__c();
            repo.External_Id__c = externalId;
        }

        repo.Name = (String) githubData.get('name');
        repo.Provider__c = 'GitHub';
        repo.Owner__c = getOwnerFromGitHub(githubData);
        repo.Default_Branch__c = (String) githubData.get('default_branch');
        repo.Repository_URL__c = (String) githubData.get('html_url');
        repo.Description__c = (String) githubData.get('description');
        repo.Active__c = true;
        repo.Last_Sync_Date__c = Datetime.now();
        repo.Last_Sync_Status__c = 'Success';

        upsert repo External_Id__c;

        return repo;
    }

    /**
     * @description Extract owner from GitHub data
     * @param githubData Repository data
     * @return String Owner name
     */
    private static String getOwnerFromGitHub(Map<String, Object> githubData) {
        Map<String, Object> ownerData = (Map<String, Object>) githubData.get('owner');
        return ownerData != null ? (String) ownerData.get('login') : null;
    }

    /**
     * @description Update sync status for repository
     * @param repositoryId Repository ID
     * @param status Sync status
     * @param syncDate Sync date/time
     */
    public static void updateSyncStatus(Id repositoryId, String status, Datetime syncDate) {
        Repository__c repo = new Repository__c(
            Id = repositoryId,
            Last_Sync_Status__c = status,
            Last_Sync_Date__c = syncDate
        );

        update repo;
    }

    /**
     * @description Bulk upsert repositories from GitHub data
     * @param githubDataList List of GitHub repository data
     * @return List<Repository__c>
     */
    public static List<Repository__c> bulkUpsertFromGitHub(List<Map<String, Object>> githubDataList) {
        List<Repository__c> repos = new List<Repository__c>();

        for (Map<String, Object> githubData : githubDataList) {
            repos.add(upsertFromGitHub(githubData));
        }

        return repos;
    }
}
