/**
 * @description Selector class for Repository__c queries
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class RepositorySelector {

    /**
     * @description Get all active repositories
     * @return List<Repository__c>
     */
    public static List<Repository__c> getAllActive() {
        return [
            SELECT Id, Name, External_Id__c, Provider__c, Owner__c,
                   Default_Branch__c, Repository_URL__c, Description__c,
                   Active__c, Last_Sync_Date__c, Last_Sync_Status__c
            FROM Repository__c
            WHERE Active__c = true
            ORDER BY Name
        ];
    }

    /**
     * @description Get repository by external ID
     * @param externalId GitHub repository ID
     * @return Repository__c
     */
    public static Repository__c getByExternalId(String externalId) {
        List<Repository__c> repos = [
            SELECT Id, Name, External_Id__c, Provider__c, Owner__c,
                   Default_Branch__c, Repository_URL__c, Description__c,
                   Active__c, Last_Sync_Date__c, Last_Sync_Status__c
            FROM Repository__c
            WHERE External_Id__c = :externalId
            LIMIT 1
        ];

        return repos.isEmpty() ? null : repos[0];
    }

    /**
     * @description Get repositories by IDs
     * @param repoIds Set of repository IDs
     * @return List<Repository__c>
     */
    public static List<Repository__c> getByIds(Set<Id> repoIds) {
        return [
            SELECT Id, Name, External_Id__c, Provider__c, Owner__c,
                   Default_Branch__c, Repository_URL__c, Description__c,
                   Active__c, Last_Sync_Date__c, Last_Sync_Status__c
            FROM Repository__c
            WHERE Id IN :repoIds
        ];
    }

    /**
     * @description Get repositories that need synchronization
     * @param minutesThreshold Minutes since last sync
     * @return List<Repository__c>
     */
    public static List<Repository__c> getRepositoriesNeedingSync(Integer minutesThreshold) {
        Datetime thresholdTime = Datetime.now().addMinutes(-minutesThreshold);

        return [
            SELECT Id, Name, External_Id__c, Provider__c, Owner__c,
                   Default_Branch__c, Repository_URL__c, Description__c,
                   Active__c, Last_Sync_Date__c, Last_Sync_Status__c
            FROM Repository__c
            WHERE Active__c = true
              AND (Last_Sync_Date__c = null OR Last_Sync_Date__c < :thresholdTime)
            ORDER BY Last_Sync_Date__c NULLS FIRST
        ];
    }
}
