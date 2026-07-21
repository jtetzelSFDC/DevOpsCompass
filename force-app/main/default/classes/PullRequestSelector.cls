/**
 * @description Selector class for Pull_Request__c queries
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class PullRequestSelector {

    /**
     * @description Get pull requests by repository ID
     * @param repositoryId Repository ID
     * @param limitCount Number of records to return
     * @return List<Pull_Request__c>
     */
    public static List<Pull_Request__c> getByRepository(Id repositoryId, Integer limitCount) {
        return [
            SELECT Id, Name, PR_Number__c, External_Id__c, Repository__c,
                   Title__c, Author__c, State__c, Source_Branch__c, Target_Branch__c,
                   Created_Date__c, Closed_Date__c, Merged_Date__c,
                   Review_Count__c, Commit_Count__c, Files_Changed__c,
                   Lines_Added__c, Lines_Removed__c, URL__c
            FROM Pull_Request__c
            WHERE Repository__c = :repositoryId
            ORDER BY Created_Date__c DESC
            LIMIT :limitCount
        ];
    }

    /**
     * @description Get pull request by external ID
     * @param externalId GitHub PR ID
     * @return Pull_Request__c
     */
    public static Pull_Request__c getByExternalId(String externalId) {
        List<Pull_Request__c> prs = getByExternalId(new Set<String>{externalId});
        return prs.isEmpty() ? null : prs[0];
    }

    /**
     * @description Get pull requests by external IDs
     * @param externalIds Set of external IDs
     * @return List<Pull_Request__c>
     */
    public static List<Pull_Request__c> getByExternalId(Set<String> externalIds) {
        return [
            SELECT Id, Name, PR_Number__c, External_Id__c, Repository__c,
                   Title__c, Author__c, State__c, Source_Branch__c, Target_Branch__c,
                   Created_Date__c, Closed_Date__c, Merged_Date__c,
                   Review_Count__c, Commit_Count__c, Files_Changed__c,
                   Lines_Added__c, Lines_Removed__c, URL__c
            FROM Pull_Request__c
            WHERE External_Id__c IN :externalIds
        ];
    }

    /**
     * @description Get open pull requests
     * @param repositoryId Repository ID (optional)
     * @return List<Pull_Request__c>
     */
    public static List<Pull_Request__c> getOpenPullRequests(Id repositoryId) {
        String query = 'SELECT Id, Name, PR_Number__c, External_Id__c, Repository__c, ' +
                       'Title__c, Author__c, State__c, Source_Branch__c, Target_Branch__c, ' +
                       'Created_Date__c, Closed_Date__c, Merged_Date__c, ' +
                       'Review_Count__c, Commit_Count__c, Files_Changed__c, ' +
                       'Lines_Added__c, Lines_Removed__c, URL__c ' +
                       'FROM Pull_Request__c ' +
                       'WHERE State__c = \'Open\'';

        if (repositoryId != null) {
            query += ' AND Repository__c = :repositoryId';
        }

        query += ' ORDER BY Created_Date__c DESC';

        return Database.query(query);
    }

    /**
     * @description Get merged pull requests within date range
     * @param startDate Start date
     * @param endDate End date
     * @return List<Pull_Request__c>
     */
    public static List<Pull_Request__c> getMergedInDateRange(Date startDate, Date endDate) {
        Datetime startDateTime = Datetime.newInstance(startDate, Time.newInstance(0, 0, 0, 0));
        Datetime endDateTime = Datetime.newInstance(endDate, Time.newInstance(23, 59, 59, 0));

        return [
            SELECT Id, Name, PR_Number__c, External_Id__c, Repository__c,
                   Title__c, Author__c, State__c, Source_Branch__c, Target_Branch__c,
                   Created_Date__c, Closed_Date__c, Merged_Date__c,
                   Review_Count__c, Commit_Count__c, Files_Changed__c,
                   Lines_Added__c, Lines_Removed__c, URL__c
            FROM Pull_Request__c
            WHERE State__c = 'Merged'
              AND Merged_Date__c >= :startDateTime
              AND Merged_Date__c <= :endDateTime
            ORDER BY Merged_Date__c DESC
        ];
    }
}
