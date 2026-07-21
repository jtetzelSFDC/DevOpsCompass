/**
 * DevOps Compass - Debug Script
 * Use this to diagnose sync issues
 */

// ============================================================================
// STEP 1: Check what's in Salesforce RIGHT NOW
// ============================================================================
System.debug('=== CURRENT SALESFORCE DATA ===');

Integer repoCount = [SELECT COUNT() FROM Repository__c];
Integer prCount = [SELECT COUNT() FROM Pull_Request__c];
Integer contribCount = [SELECT COUNT() FROM Contributor__c];

System.debug('Repository records: ' + repoCount);
System.debug('Pull Request records: ' + prCount);
System.debug('Contributor records: ' + contribCount);

if (repoCount > 0) {
    List<Repository__c> repos = [SELECT Id, Name, External_Id__c, Last_Synced__c FROM Repository__c];
    for (Repository__c r : repos) {
        System.debug('  → Repo: ' + r.Name + ' | External ID: ' + r.External_Id__c + ' | Last Sync: ' + r.Last_Synced__c);
    }
}

if (prCount > 0) {
    List<Pull_Request__c> prs = [
        SELECT Id, Name, PR_Number__c, Title__c, State__c, Repository__c, Repository__r.Name
        FROM Pull_Request__c
        LIMIT 10
    ];
    System.debug('\n=== EXISTING PULL REQUESTS ===');
    for (Pull_Request__c pr : prs) {
        System.debug('  → PR #' + pr.PR_Number__c + ': ' + pr.Title__c + ' [' + pr.State__c + '] on repo: ' + pr.Repository__r.Name);
    }
}

// ============================================================================
// STEP 2: Check what GitHub API is returning
// ============================================================================
System.debug('\n=== GITHUB API RAW RESPONSE ===');

try {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:GitHubAPI/repos/jtetzelSFDC/DevOpsCompass/pulls?state=all&per_page=100');
    req.setMethod('GET');

    Http http = new Http();
    HttpResponse res = http.send(req);

    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Response Body:');
    System.debug(res.getBody());

    if (res.getStatusCode() == 200) {
        // Parse the response to count PRs
        String body = res.getBody();
        List<Object> prList = (List<Object>) JSON.deserializeUntyped(body);
        System.debug('\n✅ GitHub returned ' + prList.size() + ' pull requests');

        // Show details of each PR
        for (Object prObj : prList) {
            Map<String, Object> pr = (Map<String, Object>) prObj;
            System.debug('  → PR #' + pr.get('number') + ': ' + pr.get('title') + ' [' + pr.get('state') + ']');
        }
    } else {
        System.debug('❌ GitHub API returned status: ' + res.getStatusCode());
    }

} catch (Exception e) {
    System.debug('❌ ERROR calling GitHub API: ' + e.getMessage());
}

// ============================================================================
// STEP 3: Try syncing again with verbose logging
// ============================================================================
System.debug('\n=== ATTEMPTING SYNC WITH VERBOSE LOGGING ===');

try {
    // Sync repository first
    System.debug('Step 1: Syncing repository...');
    Repository__c repo = RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');
    System.debug('✅ Repository ID: ' + repo.Id);
    System.debug('   Name: ' + repo.Name);
    System.debug('   External ID: ' + repo.External_Id__c);

    // Now sync PRs
    System.debug('\nStep 2: Syncing pull requests...');
    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');
    System.debug('✅ Sync returned ' + prs.size() + ' pull requests');

    if (prs.size() == 0) {
        System.debug('⚠️ WARNING: Sync completed but returned 0 pull requests!');
        System.debug('   This means GitHub API returned an empty list or all PRs filtered out.');
    } else {
        for (Pull_Request__c pr : prs) {
            System.debug('   → PR #' + pr.PR_Number__c + ': ' + pr.Title__c + ' [' + pr.State__c + ']');
        }
    }

} catch (Exception e) {
    System.debug('❌ ERROR during sync: ' + e.getMessage());
    System.debug('Stack Trace: ' + e.getStackTraceString());
}

// ============================================================================
// STEP 4: Check your user permissions
// ============================================================================
System.debug('\n=== USER PERMISSION CHECK ===');

User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
System.debug('Current User: ' + currentUser.Name);
System.debug('Profile: ' + currentUser.Profile.Name);

List<PermissionSetAssignment> psas = [
    SELECT PermissionSet.Name
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name LIKE '%DevOps%'
];

System.debug('DevOps Compass Permission Sets assigned: ' + psas.size());
for (PermissionSetAssignment psa : psas) {
    System.debug('  → ' + psa.PermissionSet.Name);
}

if (psas.size() == 0) {
    System.debug('⚠️ WARNING: You do not have DevOps_Compass_Administrator permission set!');
    System.debug('   Run: sf org assign permset --name DevOps_Compass_Administrator');
}

System.debug('\n=== DEBUG COMPLETE ===');
System.debug('Check the log output above to identify the issue.');
