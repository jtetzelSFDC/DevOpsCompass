/**
 * @description Selector class for Contributor__c queries
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class ContributorSelector {

    /**
     * @description Get all active contributors
     * @return List<Contributor__c>
     */
    public static List<Contributor__c> getAllActive() {
        return [
            SELECT Id, Name, GitHub_Username__c, Contribution_Count__c,
                   Repository__c, External_Id__c, Profile_URL__c,
                   Avatar_URL__c, Active__c, Email__c
            FROM Contributor__c
            WHERE Active__c = true
            ORDER BY Contribution_Count__c DESC NULLS LAST
        ];
    }

    /**
     * @description Get contributors by external IDs
     * @param externalIds Set of external IDs
     * @return List<Contributor__c>
     */
    public static List<Contributor__c> getByExternalId(Set<String> externalIds) {
        return [
            SELECT Id, Name, GitHub_Username__c, Contribution_Count__c,
                   Repository__c, External_Id__c, Profile_URL__c,
                   Avatar_URL__c, Active__c, Email__c
            FROM Contributor__c
            WHERE External_Id__c IN :externalIds
        ];
    }

    /**
     * @description Get contributors by repository ID
     * @param repositoryId Repository__c ID
     * @return List<Contributor__c>
     */
    public static List<Contributor__c> getByRepositoryId(Id repositoryId) {
        return [
            SELECT Id, Name, GitHub_Username__c, Contribution_Count__c,
                   Repository__c, External_Id__c, Profile_URL__c,
                   Avatar_URL__c, Active__c, Email__c
            FROM Contributor__c
            WHERE Repository__c = :repositoryId
               AND Active__c = true
            ORDER BY Contribution_Count__c DESC NULLS LAST
        ];
    }

    /**
     * @description Get top contributors across all repositories
     * @param limitCount Number of contributors to return
     * @return List<Contributor__c>
     */
    public static List<Contributor__c> getTopContributors(Integer limitCount) {
        return [
            SELECT Id, Name, GitHub_Username__c, Contribution_Count__c,
                   Repository__c, Repository__r.Name, External_Id__c,
                   Profile_URL__c, Avatar_URL__c, Active__c, Email__c
            FROM Contributor__c
            WHERE Active__c = true
            ORDER BY Contribution_Count__c DESC NULLS LAST
            LIMIT :limitCount
        ];
    }

    /**
     * @description Get contributors by IDs
     * @param contributorIds Set of contributor IDs
     * @return List<Contributor__c>
     */
    public static List<Contributor__c> getByIds(Set<Id> contributorIds) {
        return [
            SELECT Id, Name, GitHub_Username__c, Contribution_Count__c,
                   Repository__c, External_Id__c, Profile_URL__c,
                   Avatar_URL__c, Active__c, Email__c
            FROM Contributor__c
            WHERE Id IN :contributorIds
        ];
    }
}
