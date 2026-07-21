/**
 * @description Service class for synchronizing GitHub contributors into Salesforce
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class ContributorSyncService {

    private static final Integer DEFAULT_PER_PAGE = 100;
    private static final Integer DEFAULT_PAGE = 1;

    /**
     * @description Sync contributors for a repository
     * @param repositoryId Salesforce Repository__c record ID
     * @return List<Contributor__c> Synced contributors
     */
    public static List<Contributor__c> syncContributors(Id repositoryId) {
        try {
            // Get repository record
            Repository__c repo = RepositorySelector.getById(new Set<Id>{repositoryId})[0];

            // Extract owner and repo name from External_Id__c
            String[] parts = repo.External_Id__c.split('/');
            String owner = parts[0];
            String repoName = parts[1];

            // Fetch contributors from GitHub
            List<Object> contributorDataList = GitHubApiClient.getContributors(
                owner, repoName, DEFAULT_PER_PAGE, DEFAULT_PAGE
            );

            // Upsert contributor records
            List<Contributor__c> contributors = upsertContributors(contributorDataList, repo.Id);

            // Log successful sync
            DevOpsLogger.info('Successfully synced ' + contributors.size() + ' contributors for repository: ' + repo.Name);

            return contributors;

        } catch (Exception e) {
            DevOpsLogger.error('Failed to sync contributors for repository ID: ' + repositoryId, e);
            throw new DevOpsCompassException('Contributor sync failed: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Sync contributors for multiple repositories
     * @param repositoryIds Set of Repository__c record IDs
     * @return List<Contributor__c> All synced contributors
     */
    public static List<Contributor__c> syncContributorsForRepositories(Set<Id> repositoryIds) {
        List<Contributor__c> allContributors = new List<Contributor__c>();

        for (Id repoId : repositoryIds) {
            try {
                List<Contributor__c> contributors = syncContributors(repoId);
                allContributors.addAll(contributors);
            } catch (Exception e) {
                // Continue syncing other repositories even if one fails
                DevOpsLogger.error('Failed to sync contributors for repository ID: ' + repoId, e);
            }
        }

        return allContributors;
    }

    /**
     * @description Upsert contributor records from GitHub data
     * @param contributorDataList List of GitHub API contributor responses
     * @param repositoryId Salesforce Repository__c ID
     * @return List<Contributor__c>
     */
    private static List<Contributor__c> upsertContributors(List<Object> contributorDataList, Id repositoryId) {
        Map<String, Contributor__c> contributorsByExternalId = new Map<String, Contributor__c>();

        // Get existing contributors
        Set<String> externalIds = new Set<String>();
        for (Object contribObj : contributorDataList) {
            Map<String, Object> contribData = (Map<String, Object>) contribObj;
            String githubUsername = (String) contribData.get('login');
            externalIds.add(repositoryId + '-' + githubUsername);
        }

        List<Contributor__c> existingContributors = ContributorSelector.getByExternalId(externalIds);
        for (Contributor__c contributor : existingContributors) {
            contributorsByExternalId.put(contributor.External_Id__c, contributor);
        }

        // Create or update contributors
        List<Contributor__c> contributorsToUpsert = new List<Contributor__c>();

        for (Object contribObj : contributorDataList) {
            Map<String, Object> contribData = (Map<String, Object>) contribObj;
            Contributor__c contributor = mapGitHubDataToContributor(contribData, repositoryId, contributorsByExternalId);
            contributorsToUpsert.add(contributor);
        }

        if (!contributorsToUpsert.isEmpty()) {
            upsert contributorsToUpsert External_Id__c;
        }

        return contributorsToUpsert;
    }

    /**
     * @description Map GitHub contributor data to Salesforce Contributor__c record
     * @param contribData GitHub API contributor data
     * @param repositoryId Repository__c ID
     * @param existingContributors Map of existing contributors by external ID
     * @return Contributor__c
     */
    private static Contributor__c mapGitHubDataToContributor(
        Map<String, Object> contribData,
        Id repositoryId,
        Map<String, Contributor__c> existingContributors
    ) {
        String githubUsername = (String) contribData.get('login');
        String externalId = repositoryId + '-' + githubUsername;

        Contributor__c contributor = existingContributors.containsKey(externalId)
            ? existingContributors.get(externalId)
            : new Contributor__c();

        // Map fields
        contributor.Name = githubUsername;
        contributor.GitHub_Username__c = githubUsername;
        contributor.Contribution_Count__c = (Integer) contribData.get('contributions');
        contributor.Repository__c = repositoryId;
        contributor.External_Id__c = externalId;
        contributor.Profile_URL__c = (String) contribData.get('html_url');
        contributor.Avatar_URL__c = (String) contribData.get('avatar_url');
        contributor.Active__c = true;

        return contributor;
    }
}
