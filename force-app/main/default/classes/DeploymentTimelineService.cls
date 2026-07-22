/**
 * @description Service class for retrieving Pull Request milestone timeline data
 * Orchestrates data gathering and delegates timeline construction to TimelineBuilder
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class DeploymentTimelineService {

    /**
     * @description Get timeline data for a Pull Request
     * @param pullRequestId Pull Request record ID
     * @return List<TimelineBuilder.Milestone> Ordered milestones
     */
    @AuraEnabled(cacheable=true)
    public static List<TimelineBuilder.Milestone> getTimelineData(Id pullRequestId) {
        try {
            // Query Pull Request
            Pull_Request__c pr = queryPullRequest(pullRequestId);

            // Query Environments ordered by Display Order
            List<Environment__c> environments = queryEnvironments();

            // Query Deployments for this PR
            List<Deployment__c> deployments = queryDeployments(pullRequestId);

            // Map deployments by environment (keep latest successful only)
            Map<Id, Deployment__c> deploymentsByEnv = mapLatestDeploymentsByEnvironment(deployments);

            // Build timeline using TimelineBuilder
            TimelineBuilder builder = new TimelineBuilder()
                .withPullRequest(pr)
                .withEnvironments(environments)
                .withDeployments(deploymentsByEnv);

            return builder.build();

        } catch (Exception e) {
            DevOpsLogger.error('Failed to retrieve timeline data for PR: ' + pullRequestId, e);
            throw new AuraHandledException('Unable to load timeline data: ' + e.getMessage());
        }
    }

    /**
     * @description Query Pull Request record
     * @param pullRequestId Pull Request ID
     * @return Pull_Request__c
     */
    private static Pull_Request__c queryPullRequest(Id pullRequestId) {
        return [
            SELECT Id, PR_Number__c, Created_Date__c, Merged_Date__c
            FROM Pull_Request__c
            WHERE Id = :pullRequestId
            LIMIT 1
        ];
    }

    /**
     * @description Query all active environments ordered by Display Order
     * @return List<Environment__c>
     */
    private static List<Environment__c> queryEnvironments() {
        return [
            SELECT Id, Name, Display_Order__c
            FROM Environment__c
            WHERE Active__c = true
            ORDER BY Display_Order__c ASC NULLS LAST, Name ASC
        ];
    }

    /**
     * @description Query successful deployments for a Pull Request
     * @param pullRequestId Pull Request ID
     * @return List<Deployment__c>
     */
    private static List<Deployment__c> queryDeployments(Id pullRequestId) {
        return [
            SELECT Id, Environment__c, Deployed_Date__c, Status__c
            FROM Deployment__c
            WHERE Pull_Request__c = :pullRequestId
              AND Status__c = 'Successful'
            ORDER BY Deployed_Date__c DESC
        ];
    }

    /**
     * @description Map deployments by environment, keeping only the latest successful deployment per environment
     * @param deployments List of Deployment records
     * @return Map<Id, Deployment__c> Map of Environment ID to latest Deployment
     */
    private static Map<Id, Deployment__c> mapLatestDeploymentsByEnvironment(List<Deployment__c> deployments) {
        Map<Id, Deployment__c> result = new Map<Id, Deployment__c>();

        for (Deployment__c dep : deployments) {
            Id envId = dep.Environment__c;

            // Keep the latest deployment per environment (list is ordered DESC by Deployed_Date__c)
            if (!result.containsKey(envId)) {
                result.put(envId, dep);
            }
        }

        return result;
    }
}
