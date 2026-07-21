/**
 * Simple Debug Script - Run this first to diagnose the issue
 */

System.debug('=== STEP 1: Check Current Salesforce Records ===');
System.debug('Repositories: ' + [SELECT COUNT() FROM Repository__c]);
System.debug('Pull Requests: ' + [SELECT COUNT() FROM Pull_Request__c]);
System.debug('Contributors: ' + [SELECT COUNT() FROM Contributor__c]);

System.debug('\n=== STEP 2: Check GitHub API ===');
try {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:GitHubAPI/repos/jtetzelSFDC/DevOpsCompass/pulls?state=all&per_page=10');
    req.setMethod('GET');
    Http http = new Http();
    HttpResponse res = http.send(req);

    if (res.getStatusCode() == 200) {
        List<Object> prList = (List<Object>) JSON.deserializeUntyped(res.getBody());
        System.debug('✅ GitHub API returned ' + prList.size() + ' pull requests');
        for (Object prObj : prList) {
            Map<String, Object> pr = (Map<String, Object>) prObj;
            System.debug('  → PR #' + pr.get('number') + ': ' + pr.get('title'));
        }
    } else {
        System.debug('❌ GitHub API Error: ' + res.getStatusCode() + ' - ' + res.getBody());
    }
} catch (Exception e) {
    System.debug('❌ Exception: ' + e.getMessage());
}

System.debug('\n=== STEP 3: Re-run Sync ===');
try {
    Repository__c repo = RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');
    System.debug('✅ Repo synced: ' + repo.Id);

    List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'all');
    System.debug('✅ Synced ' + prs.size() + ' pull requests');

    if (prs.size() > 0) {
        System.debug('\n=== Pull Requests Created ===');
        for (Pull_Request__c pr : prs) {
            System.debug('  PR #' + pr.PR_Number__c + ': ' + pr.Title__c + ' [' + pr.State__c + ']');
        }
    }
} catch (Exception e) {
    System.debug('❌ Sync Error: ' + e.getMessage());
    System.debug(e.getStackTraceString());
}

System.debug('\n=== STEP 4: Verify Permission Set ===');
List<PermissionSetAssignment> psas = [
    SELECT PermissionSet.Name
    FROM PermissionSetAssignment
    WHERE AssigneeId = :UserInfo.getUserId()
    AND PermissionSet.Name LIKE '%DevOps%'
];
System.debug('Permission Sets: ' + psas.size());
for (PermissionSetAssignment psa : psas) {
    System.debug('  → ' + psa.PermissionSet.Name);
}
