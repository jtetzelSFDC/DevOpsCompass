// Debug script for Activity Feed issue
System.debug('=== Checking Pull Request Data ===');

// Get repository
Repository__c repo = [SELECT Id, External_Id__c FROM Repository__c WHERE External_Id__c = 'jtetzelSFDC/DevOpsCompass' LIMIT 1];
System.debug('Repository ID: ' + repo.Id);

// Check PRs
List<Pull_Request__c> prs = [SELECT Id, PR_Number__c, Title__c, State__c, Author__c,
                               Created_Date__c, Merged_Date__c, Closed_Date__c
                               FROM Pull_Request__c
                               WHERE Repository__c = :repo.Id];

System.debug('Total PRs found: ' + prs.size());

if (prs.size() > 0) {
    System.debug('Sample PR data:');
    Pull_Request__c sample = prs[0];
    System.debug('  PR Number: ' + sample.PR_Number__c);
    System.debug('  Title: ' + sample.Title__c);
    System.debug('  State: ' + sample.State__c);
    System.debug('  Author: ' + sample.Author__c);
    System.debug('  Created Date: ' + sample.Created_Date__c);
    System.debug('  Merged Date: ' + sample.Merged_Date__c);
    System.debug('  Closed Date: ' + sample.Closed_Date__c);
}

// Try the activity service
try {
    List<ActivityService.Activity> activities = ActivityService.getRecentActivity(repo.Id, 30);
    System.debug('✅ Activities found: ' + activities.size());
} catch (Exception e) {
    System.debug('❌ ERROR in ActivityService: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}
