/**
 * DevOps Compass - Story 1 Executable Test Scripts
 * Copy and paste these scripts into Developer Console → Execute Anonymous
 *
 * Version: 1.0
 * Date: July 21, 2026
 */

// ============================================================================
// Test Script 1.1: GitHub API Connectivity Test
// ============================================================================
try {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:GitHubAPI/user');
    req.setMethod('GET');

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Response Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        System.debug('✅ SUCCESS: GitHub API connection is working!');
    } else {
        System.debug('❌ FAILED: GitHub API returned status ' + res.getStatusCode());
    }
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
}

// ============================================================================
// Test Script 1.2: Repository Sync Test
// ============================================================================
try {
    // Sync the DevOpsCompass repository
    Repository__c repo = RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');

    System.debug('✅ Repository synced successfully!');
    System.debug('Repository ID: ' + repo.Id);
    System.debug('Name: ' + repo.Name);
    System.debug('External ID: ' + repo.External_Id__c);
    System.debug('Description: ' + repo.Description__c);
    System.debug('Default Branch: ' + repo.Default_Branch__c);
    System.debug('Stars: ' + repo.Star_Count__c);
    System.debug('Forks: ' + repo.Fork_Count__c);
    System.debug('Open Issues: ' + repo.Open_Issues_Count__c);
    System.debug('Last Synced: ' + repo.Last_Synced__c);

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// Test Script 1.3: Pull Request Sync Test
// ============================================================================
try {
    // First, get the Repository record
    Repository__c repo = [SELECT Id, External_Id__c FROM Repository__c WHERE External_Id__c = 'jtetzelSFDC/DevOpsCompass' LIMIT 1];

    System.debug('Repository ID: ' + repo.Id);

    // Sync all pull requests (open, closed, merged)
    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');

    System.debug('✅ Synced ' + prs.size() + ' pull requests');

    for (Pull_Request__c pr : prs) {
        System.debug('PR #' + pr.PR_Number__c + ': ' + pr.Title__c + ' (' + pr.State__c + ')');
    }

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// Test Script 1.4: Contributor Sync Test
// ============================================================================
try {
    // Get the Repository record
    Repository__c repo = [SELECT Id, External_Id__c FROM Repository__c WHERE External_Id__c = 'jtetzelSFDC/DevOpsCompass' LIMIT 1];

    System.debug('Repository ID: ' + repo.Id);

    // Sync contributors
    List<Contributor__c> contributors = ContributorSyncService.syncContributors(repo.Id);

    System.debug('✅ Synced ' + contributors.size() + ' contributors');

    for (Contributor__c c : contributors) {
        System.debug('Contributor: ' + c.Name + ' (' + c.Contribution_Count__c + ' contributions)');
    }

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// Test Script 1.10: Bulk Sync Performance Test
// ============================================================================
try {
    System.debug('=== Starting Bulk Sync Test ===');
    System.debug('Initial Limits:');
    System.debug('SOQL Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    System.debug('DML Statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
    System.debug('Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());

    // Sync repository
    Long startTime = System.now().getTime();
    Repository__c repo = RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');
    Long repoTime = System.now().getTime() - startTime;

    System.debug('Repository synced in ' + repoTime + 'ms');

    // Sync pull requests
    startTime = System.now().getTime();
    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');
    Long prTime = System.now().getTime() - startTime;

    System.debug('Pull Requests synced in ' + prTime + 'ms');

    // Sync contributors
    startTime = System.now().getTime();
    List<Contributor__c> contributors = ContributorSyncService.syncContributors(repo.Id);
    Long contribTime = System.now().getTime() - startTime;

    System.debug('Contributors synced in ' + contribTime + 'ms');

    System.debug('=== Final Limits ===');
    System.debug('SOQL Queries: ' + Limits.getQueries() + '/' + Limits.getLimitQueries());
    System.debug('DML Statements: ' + Limits.getDmlStatements() + '/' + Limits.getLimitDmlStatements());
    System.debug('Callouts: ' + Limits.getCallouts() + '/' + Limits.getLimitCallouts());
    System.debug('Heap Size: ' + Limits.getHeapSize() + '/' + Limits.getLimitHeapSize());

    System.debug('✅ Bulk sync completed successfully!');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// BONUS: Complete Sync All-in-One Script (Recommended Starting Point)
// ============================================================================
try {
    System.debug('=== DevOps Compass - Complete Sync ===');

    // Step 1: Sync Repository
    System.debug('\n1️⃣ Syncing Repository...');
    Repository__c repo = RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');
    System.debug('✅ Repository: ' + repo.Name + ' (ID: ' + repo.Id + ')');

    // Step 2: Sync Pull Requests
    System.debug('\n2️⃣ Syncing Pull Requests...');
    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');
    System.debug('✅ Synced ' + prs.size() + ' pull requests');

    // Step 3: Sync Contributors
    System.debug('\n3️⃣ Syncing Contributors...');
    List<Contributor__c> contributors = ContributorSyncService.syncContributors(repo.Id);
    System.debug('✅ Synced ' + contributors.size() + ' contributors');

    System.debug('\n🎉 All syncs completed successfully!');
    System.debug('📊 Summary:');
    System.debug('   - Repository: ' + repo.Name);
    System.debug('   - Pull Requests: ' + prs.size());
    System.debug('   - Contributors: ' + contributors.size());
    System.debug('\n👉 Next Step: Navigate to the Repository record page and add the LWC components!');

} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// Utility: Query Current Data Counts
// ============================================================================
System.debug('=== DevOps Compass - Current Data Counts ===');
System.debug('Repositories: ' + [SELECT COUNT() FROM Repository__c]);
System.debug('Pull Requests: ' + [SELECT COUNT() FROM Pull_Request__c]);
System.debug('Contributors: ' + [SELECT COUNT() FROM Contributor__c]);

// ============================================================================
// Utility: View Recent Pull Requests
// ============================================================================
List<Pull_Request__c> recentPRs = [
    SELECT Id, Name, Title__c, PR_Number__c, State__c, Author__c, Created_Date__c
    FROM Pull_Request__c
    ORDER BY Created_Date__c DESC
    LIMIT 10
];

System.debug('=== Recent Pull Requests ===');
for (Pull_Request__c pr : recentPRs) {
    System.debug('PR #' + pr.PR_Number__c + ': ' + pr.Title__c + ' [' + pr.State__c + '] by ' + pr.Author__c);
}

// ============================================================================
// Utility: Delete All Test Data (USE WITH CAUTION!)
// ============================================================================
/*
try {
    // WARNING: This will delete ALL repositories and cascade to PRs and Contributors
    List<Repository__c> repos = [SELECT Id FROM Repository__c];
    delete repos;
    System.debug('✅ Deleted ' + repos.size() + ' repositories and all related records');
} catch (Exception e) {
    System.debug('❌ ERROR: ' + e.getMessage());
}
*/
