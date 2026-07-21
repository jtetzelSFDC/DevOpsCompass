/**
 * @description Service class for aggregating recent activity across repositories
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class ActivityService {

    public class Activity {
        @AuraEnabled public String id;
        @AuraEnabled public String type;
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public Datetime activityDate;
        @AuraEnabled public String recordId;
        @AuraEnabled public String sObjectType;
    }

    /**
     * @description Get recent activity for a repository
     * @param repositoryId Repository ID (optional)
     * @param days Number of days to look back
     * @return List<Activity>
     */
    @AuraEnabled(cacheable=true)
    public static List<Activity> getRecentActivity(Id repositoryId, Integer days) {
        List<Activity> activities = new List<Activity>();
        Datetime cutoffDate = Datetime.now().addDays(-days);

        // Get recent PRs
        String query = 'SELECT Id, Title__c, State__c, Author__c, Created_Date__c, Merged_Date__c, Closed_Date__c ' +
                      'FROM Pull_Request__c ' +
                      'WHERE (Created_Date__c >= :cutoffDate OR Merged_Date__c >= :cutoffDate OR Closed_Date__c >= :cutoffDate)';

        if (repositoryId != null) {
            query += ' AND Repository__c = :repositoryId';
        }

        query += ' ORDER BY Created_Date__c DESC LIMIT 50';

        List<Pull_Request__c> recentPRs = Database.query(query);

        for (Pull_Request__c pr : recentPRs) {
            // PR Created activity
            if (pr.Created_Date__c != null && pr.Created_Date__c >= cutoffDate) {
                Activity activity = new Activity();
                activity.id = pr.Id + '-created';
                activity.type = 'PR_CREATED';
                activity.title = 'Pull Request #' + pr.PR_Number__c + ' opened';
                activity.description = pr.Title__c + ' by ' + pr.Author__c;
                activity.activityDate = pr.Created_Date__c;
                activity.recordId = pr.Id;
                activity.sObjectType = 'Pull_Request__c';
                activities.add(activity);
            }

            // PR Merged activity
            if (pr.Merged_Date__c != null && pr.Merged_Date__c >= cutoffDate) {
                Activity activity = new Activity();
                activity.id = pr.Id + '-merged';
                activity.type = 'PR_MERGED';
                activity.title = 'Pull Request #' + pr.PR_Number__c + ' merged';
                activity.description = pr.Title__c + ' by ' + pr.Author__c;
                activity.activityDate = pr.Merged_Date__c;
                activity.recordId = pr.Id;
                activity.sObjectType = 'Pull_Request__c';
                activities.add(activity);
            }

            // PR Closed activity
            if (pr.Closed_Date__c != null && pr.Closed_Date__c >= cutoffDate && pr.State__c == 'Closed') {
                Activity activity = new Activity();
                activity.id = pr.Id + '-closed';
                activity.type = 'PR_CLOSED';
                activity.title = 'Pull Request #' + pr.PR_Number__c + ' closed';
                activity.description = pr.Title__c + ' by ' + pr.Author__c;
                activity.activityDate = pr.Closed_Date__c;
                activity.recordId = pr.Id;
                activity.sObjectType = 'Pull_Request__c';
                activities.add(activity);
            }
        }

        // Sort by date descending - manually since Activity is not Comparable
        for (Integer i = 0; i < activities.size(); i++) {
            for (Integer j = i + 1; j < activities.size(); j++) {
                if (activities[j].activityDate > activities[i].activityDate) {
                    Activity temp = activities[i];
                    activities[i] = activities[j];
                    activities[j] = temp;
                }
            }
        }

        // Return top 20 activities
        if (activities.size() > 20) {
            List<Activity> topActivities = new List<Activity>();
            for (Integer i = 0; i < 20; i++) {
                topActivities.add(activities[i]);
            }
            return topActivities;
        }
        return activities;
    }
}
