/**
 * @description Builder class for constructing Pull Request milestone timelines
 * Isolates timeline construction logic from service orchestration
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class TimelineBuilder {

    private List<Milestone> milestones;
    private Pull_Request__c pullRequest;
    private Map<Id, Deployment__c> deploymentsByEnvironment;
    private List<Environment__c> environments;

    /**
     * @description Inner class representing a timeline milestone
     */
    public class Milestone {
        @AuraEnabled public String label;
        @AuraEnabled public Integer order;
        @AuraEnabled public Boolean completed;
        @AuraEnabled public Boolean isCurrent;
        @AuraEnabled public DateTime completedDate;
        @AuraEnabled public Id environmentId;
        @AuraEnabled public String milestoneType;
        @AuraEnabled public String displayDate;

        public Milestone(String label, Integer order, String milestoneType) {
            this.label = label;
            this.order = order;
            this.milestoneType = milestoneType;
            this.completed = false;
            this.isCurrent = false;
            this.completedDate = null;
            this.environmentId = null;
            this.displayDate = null;
        }
    }

    /**
     * @description Constructor initializes empty milestone list
     */
    public TimelineBuilder() {
        this.milestones = new List<Milestone>();
    }

    /**
     * @description Set the Pull Request for timeline construction
     * @param pr Pull Request record
     * @return TimelineBuilder for method chaining
     */
    public TimelineBuilder withPullRequest(Pull_Request__c pr) {
        this.pullRequest = pr;
        return this;
    }

    /**
     * @description Set the environments for timeline construction
     * @param envs List of Environment records ordered by Display_Order__c
     * @return TimelineBuilder for method chaining
     */
    public TimelineBuilder withEnvironments(List<Environment__c> envs) {
        this.environments = envs;
        return this;
    }

    /**
     * @description Set the deployments mapped by environment ID
     * @param deploymentMap Map of Environment ID to latest successful Deployment
     * @return TimelineBuilder for method chaining
     */
    public TimelineBuilder withDeployments(Map<Id, Deployment__c> deploymentMap) {
        this.deploymentsByEnvironment = deploymentMap;
        return this;
    }

    /**
     * @description Build the complete timeline
     * @return List<Milestone> Ordered list of milestones
     */
    public List<Milestone> build() {
        addCreatedMilestone();
        addMergedMilestone();
        addEnvironmentMilestones();
        determineCurrentMilestone();
        return milestones;
    }

    /**
     * @description Add Created milestone from Pull Request
     */
    private void addCreatedMilestone() {
        Milestone created = new Milestone('Created', 1, 'CREATED');

        if (pullRequest != null && pullRequest.Created_Date__c != null) {
            created.completed = true;
            created.completedDate = pullRequest.Created_Date__c;
            created.displayDate = formatDate(pullRequest.Created_Date__c);
        }

        milestones.add(created);
    }

    /**
     * @description Add Merged milestone from Pull Request
     */
    private void addMergedMilestone() {
        Milestone merged = new Milestone('Merged', 2, 'MERGED');

        if (pullRequest != null && pullRequest.Merged_Date__c != null) {
            merged.completed = true;
            merged.completedDate = pullRequest.Merged_Date__c;
            merged.displayDate = formatDate(pullRequest.Merged_Date__c);
        }

        milestones.add(merged);
    }

    /**
     * @description Add environment milestones dynamically from Environment records
     */
    private void addEnvironmentMilestones() {
        if (environments == null || environments.isEmpty()) {
            return;
        }

        Integer order = 3; // Start after Created and Merged

        for (Environment__c env : environments) {
            Milestone envMilestone = new Milestone(env.Name, order, 'ENVIRONMENT');
            envMilestone.environmentId = env.Id;

            // Check if this environment has a successful deployment
            if (deploymentsByEnvironment != null && deploymentsByEnvironment.containsKey(env.Id)) {
                Deployment__c deployment = deploymentsByEnvironment.get(env.Id);
                envMilestone.completed = true;
                envMilestone.completedDate = deployment.End_Time__c;
                envMilestone.displayDate = formatDate(deployment.End_Time__c);
            }

            milestones.add(envMilestone);
            order++;
        }
    }

    /**
     * @description Determine which milestone is current
     * Algorithm: Highest completed milestone is current
     * If no deployments exist, Merged is current
     */
    private void determineCurrentMilestone() {
        Milestone currentMilestone = null;

        // Find the highest completed milestone
        for (Milestone m : milestones) {
            if (m.completed) {
                currentMilestone = m;
            }
        }

        // If no completed milestones, current is Created
        if (currentMilestone == null && !milestones.isEmpty()) {
            currentMilestone = milestones[0];
        }

        // Mark the current milestone
        if (currentMilestone != null) {
            currentMilestone.isCurrent = true;
        }
    }

    /**
     * @description Format DateTime for display
     * @param dt DateTime to format
     * @return Formatted string (e.g., "Jul 14, 2026")
     */
    private String formatDate(DateTime dt) {
        if (dt == null) {
            return null;
        }
        return dt.format('MMM dd, yyyy');
    }
}
