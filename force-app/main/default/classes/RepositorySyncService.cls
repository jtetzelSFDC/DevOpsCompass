/**
 * @description Service class for synchronizing GitHub repositories into Salesforce
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class RepositorySyncService {

    /**
     * @description Sync a single repository from GitHub
     * @param owner Repository owner (GitHub username or org)
     * @param repoName Repository name
     * @return Repository__c The synced repository record
     */
    public static Repository__c syncRepository(String owner, String repoName) {
        try {
            // Fetch repository data from GitHub
            Map<String, Object> repoData = GitHubApiClient.getRepository(owner, repoName);

            // Create or update repository record
            Repository__c repo = upsertRepository(repoData, owner, repoName);

            // Log successful sync
            DevOpsLogger.info('Successfully synced repository: ' + owner + '/' + repoName);

            return repo;

        } catch (Exception e) {
            // Log error
            DevOpsLogger.error('Failed to sync repository: ' + owner + '/' + repoName, e);
            throw new DevOpsCompassException('Repository sync failed: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Sync multiple repositories from GitHub
     * @param repositories List of owner/repo pairs
     * @return List<Repository__c> Synced repository records
     */
    public static List<Repository__c> syncRepositories(List<RepositoryInfo> repositories) {
        List<Repository__c> syncedRepos = new List<Repository__c>();

        for (RepositoryInfo repoInfo : repositories) {
            try {
                Repository__c repo = syncRepository(repoInfo.owner, repoInfo.repoName);
                syncedRepos.add(repo);
            } catch (Exception e) {
                // Continue syncing other repositories even if one fails
                DevOpsLogger.error('Failed to sync repository: ' + repoInfo.owner + '/' + repoInfo.repoName, e);
            }
        }

        return syncedRepos;
    }

    /**
     * @description Upsert repository record from GitHub data
     * @param repoData GitHub API response data
     * @param owner Repository owner
     * @param repoName Repository name
     * @return Repository__c
     */
    private static Repository__c upsertRepository(Map<String, Object> repoData, String owner, String repoName) {
        // Check if repository already exists
        String externalId = owner + '/' + repoName;
        List<Repository__c> existing = RepositorySelector.getByExternalId(new Set<String>{externalId});

        Repository__c repo;
        if (!existing.isEmpty()) {
            repo = existing[0];
        } else {
            repo = new Repository__c();
        }

        // Map GitHub data to Salesforce fields
        repo.Name = (String) repoData.get('name');
        repo.Description__c = (String) repoData.get('description');
        repo.Repository_URL__c = (String) repoData.get('html_url');
        repo.Default_Branch__c = (String) repoData.get('default_branch');
        repo.Provider__c = 'GitHub';
        repo.Owner__c = owner;
        repo.External_Id__c = externalId;
        repo.Active__c = true;
        repo.Last_Sync_Date__c = System.now();
        repo.Last_Sync_Status__c = 'Success';

        upsert repo External_Id__c;

        return repo;
    }

    /**
     * @description Inner class to hold repository information
     */
    public class RepositoryInfo {
        public String owner;
        public String repoName;

        public RepositoryInfo(String owner, String repoName) {
            this.owner = owner;
            this.repoName = repoName;
        }
    }
}
