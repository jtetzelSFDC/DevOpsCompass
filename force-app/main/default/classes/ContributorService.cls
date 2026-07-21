/**
 * @description Service class for Contributor business logic
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class ContributorService {

    /**
     * @description Get top contributors (for LWC)
     * @param repositoryId Optional repository ID filter
     * @param limitCount Number of contributors to return
     * @return List<Contributor__c>
     */
    @AuraEnabled(cacheable=true)
    public static List<Contributor__c> getTopContributors(Id repositoryId, Integer limitCount) {
        if (repositoryId != null) {
            return ContributorSelector.getByRepositoryId(repositoryId);
        }
        return ContributorSelector.getTopContributors(limitCount);
    }
}
