# Story 1 Testing Guide

**Version**: 1.0  
**Date**: July 21, 2026  
**Tester**: Jordan  
**Environment**: Sandbox

## Overview

This document provides step-by-step instructions for testing the Story 1 implementation: Repository Intelligence Dashboard with GitHub synchronization services and Lightning Web Components.

## Prerequisites Checklist

Before starting tests, verify:

- [ ] GitHub Personal Access Token created (see [PATSetup.MD](../documentation/PATSetup.MD))
- [ ] External Credential configured in Salesforce
- [ ] Named Credential `GitHubAPI` is active
- [ ] Permission Set `DevOps_Compass_Administrator` assigned to your user
- [ ] All Story 1 components deployed successfully

## Test Plan Summary

| Test # | Test Name | Category | Priority |
|--------|-----------|----------|----------|
| T1.1 | GitHub API Connectivity | Setup | Critical |
| T1.2 | Repository Sync | Core Sync | Critical |
| T1.3 | Pull Request Sync | Core Sync | Critical |
| T1.4 | Contributor Sync | Core Sync | Critical |
| T1.5 | Repository Overview Card | LWC | High |
| T1.6 | Pull Request Metrics Card | LWC | High |
| T1.7 | Contributor Leaderboard | LWC | High |
| T1.8 | Recent Activity Feed | LWC | High |
| T1.9 | Pull Request Tab Visibility | Navigation | High |
| T1.10 | Bulk Sync Performance | Performance | Medium |

---

## Test Execution

### T1.1: GitHub API Connectivity Test

**Objective**: Verify that Salesforce can successfully authenticate and communicate with GitHub API.

**Steps**:
1. Navigate to Setup → Named Credentials
2. Find `GitHubAPI` and verify status is **Active**
3. Open Developer Console → Execute Anonymous
4. Run the following script:

```apex
// Test Script 1.1: GitHub API Connectivity
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
```

**Expected Result**:
- Status Code: `200`
- Response contains your GitHub user information (login, id, name, etc.)
- Debug log shows: `✅ SUCCESS: GitHub API connection is working!`

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.2: Repository Sync Test

**Objective**: Sync a GitHub repository and verify all fields are populated correctly.

**Pre-Test State**: 
- Query existing repos: `SELECT COUNT() FROM Repository__c`
- Current Count: _______________

**Steps**:
1. Open Developer Console → Execute Anonymous
2. Run the following script:

```apex
// Test Script 1.2: Repository Sync
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
```

**Expected Result**:
- Repository record created/updated in Salesforce
- All fields populated with GitHub data:
  - Name: `DevOpsCompass`
  - External_Id__c: `jtetzelSFDC/DevOpsCompass`
  - Default_Branch__c: `main`
  - Star_Count__c, Fork_Count__c, Open_Issues_Count__c populated
  - Last_Synced__c = today

**Verification Steps**:
1. Navigate to DevOps Compass App → Repository tab
2. Open the `DevOpsCompass` repository record
3. Verify all fields are populated correctly

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.3: Pull Request Sync Test

**Objective**: Sync pull requests from GitHub and verify they appear in Salesforce.

**Pre-Test State**:
- Query existing PRs: `SELECT COUNT() FROM Pull_Request__c`
- Current Count: _______________

**Steps**:
1. Open Developer Console → Execute Anonymous
2. Run the following script:

```apex
// Test Script 1.3: Pull Request Sync
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
```

**Expected Result**:
- At least 5 pull requests synced (the ones we created earlier)
- Each PR should have:
  - Title populated
  - State (open/closed/merged)
  - PR_Number__c
  - External_Id__c format: `jtetzelSFDC/DevOpsCompass/PR-{number}`
  - Head_Branch__c and Base_Branch__c populated
  - Created_Date__c populated

**Verification Steps**:
1. Navigate to DevOps Compass App → **Pull Request tab**
2. Verify you can see all synced pull requests
3. Open one PR record and verify all fields are populated
4. Verify the PR shows the correct Repository relationship

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.4: Contributor Sync Test

**Objective**: Sync contributor data and verify master-detail relationship to Repository.

**Pre-Test State**:
- Query existing contributors: `SELECT COUNT() FROM Contributor__c`
- Current Count: _______________

**Steps**:
1. Open Developer Console → Execute Anonymous
2. Run the following script:

```apex
// Test Script 1.4: Contributor Sync
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
```

**Expected Result**:
- At least 1 contributor synced
- Each contributor should have:
  - Name populated (GitHub username)
  - Contribution_Count__c populated
  - Repository__c (Master-Detail) pointing to the correct repository
  - External_Id__c format: `jtetzelSFDC/DevOpsCompass/CONTRIB-{username}`

**Verification Steps**:
1. Navigate to DevOps Compass App → Contributor tab
2. Verify contributors are visible
3. Open a contributor record
4. Verify the Repository field shows the correct master record
5. Try to change the Repository field (should fail - it's master-detail)

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.5: Repository Overview Card (LWC) Test

**Objective**: Verify the Repository Overview Card displays correct information on the repository record page.

**Pre-Requisites**:
- Repository record exists (from T1.2)

**Steps**:
1. Navigate to DevOps Compass App → Repository tab
2. Open the `DevOpsCompass` repository record
3. Click the gear icon → Edit Page
4. From the Lightning App Builder left panel, find **repositoryOverviewCard**
5. Drag it onto the page (top of the right column recommended)
6. Save and Activate the page

**Verification Steps**:
1. Refresh the repository record page
2. Verify the card displays:
   - Repository name
   - Description
   - Default branch with badge
   - Sync status badge (green if recent, yellow if stale)
   - Star count
   - Fork count
   - Open issues count
   - "View in GitHub" button that opens correct URL
3. Click "View in GitHub" button - should open `https://github.com/jtetzelSFDC/DevOpsCompass`

**Expected Result**:
- Card renders without errors
- All data displays correctly
- Visual styling is appropriate (badges, colors, spacing)
- GitHub button links correctly

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Screenshot**: (optional) _______________

**Notes**: _______________

---

### T1.6: Pull Request Metrics Card (LWC) Test

**Objective**: Verify the Pull Request Metrics Card displays correct PR counts and lists.

**Pre-Requisites**:
- Repository record exists
- Pull requests synced (from T1.3)

**Steps**:
1. On the same Repository record page (Edit Page mode)
2. Find **pullRequestMetrics** in the left panel
3. Drag it onto the page (below the overview card)
4. Save and Activate

**Verification Steps**:
1. Refresh the repository record page
2. Verify the card displays:
   - "Open Pull Requests" count
   - "Recently Merged" count
   - List of recent PRs with:
     - PR number and title
     - Author name
     - State badge (color-coded)
     - Created date
   - Empty state message if no PRs exist

**Expected Result**:
- Card renders without errors
- Counts match actual PR data
- PRs are listed with correct information
- State badges are color-coded (green=merged, blue=open, gray=closed)

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.7: Contributor Leaderboard (LWC) Test

**Objective**: Verify the Contributor Leaderboard displays ranked contributors.

**Pre-Requisites**:
- Repository record exists
- Contributors synced (from T1.4)

**Steps**:
1. On the same Repository record page (Edit Page mode)
2. Find **contributorLeaderboard** in the left panel
3. Drag it onto the page
4. (Optional) In the component properties, set "Number of Contributors" to `10`
5. Save and Activate

**Verification Steps**:
1. Refresh the repository record page
2. Verify the card displays:
   - Ranked list of contributors (with rank numbers)
   - Each contributor shows:
     - Rank number
     - Name with avatar/initials
     - Contribution count
   - Contributors sorted by contribution count (highest first)

**Expected Result**:
- Card renders without errors
- Contributors ranked correctly
- Avatar initials display correctly
- Contribution counts are accurate

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.8: Recent Activity Feed (LWC) Test

**Objective**: Verify the Recent Activity Feed displays timeline of PR activities.

**Pre-Requisites**:
- Repository record exists
- Pull requests synced with various states

**Steps**:
1. On the same Repository record page (Edit Page mode)
2. Find **recentActivityFeed** in the left panel
3. Drag it onto the page
4. (Optional) In the component properties, set "Number of Days" to `30`
5. Save and Activate

**Verification Steps**:
1. Refresh the repository record page
2. Verify the card displays:
   - Timeline of recent activities
   - Each activity shows:
     - Icon indicating type (created/merged/closed)
     - Activity description (e.g., "PR #5 opened: Implement Story 1")
     - Date/time
   - Activities sorted by date (most recent first)
   - Different icons/colors for different activity types

**Expected Result**:
- Card renders without errors
- Activities are chronologically sorted
- Icons match activity types
- Activity descriptions are clear and informative

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.9: Pull Request Tab Visibility Test

**Objective**: Verify pull request records are visible in the Pull Request tab with proper list views.

**Steps**:
1. Navigate to DevOps Compass App
2. Click the **Pull Request** tab
3. Check available list views in the dropdown

**Verification Steps**:
1. Default list view shows pull requests
2. You can see the 5 PRs created earlier (feature/story1, etc.)
3. Fields visible in list view:
   - PR Number
   - Title
   - State
   - Repository Name
   - Author
   - Created Date
4. Can click into a PR record to see full details

**Expected Result**:
- All synced PRs visible
- List views work correctly
- Can filter by state (open, closed, merged)
- Record details page opens correctly

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

### T1.10: Bulk Sync Performance Test

**Objective**: Test bulk synchronization of multiple repositories/PRs and verify governor limits are respected.

**Steps**:
1. Open Developer Console → Execute Anonymous
2. Run the following script:

```apex
// Test Script 1.10: Bulk Sync Performance
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
```

**Expected Result**:
- All syncs complete without hitting governor limits
- SOQL Queries < 100
- DML Statements < 150
- Callouts = 3 (one per sync service)
- No "LIMIT exceeded" errors
- Performance is acceptable (< 10 seconds total)

**Actual Result**: _______________

**Status**: [ ] Pass [ ] Fail

**Notes**: _______________

---

## Additional Exploratory Testing

### Permission Set Testing
- [ ] Test with user who does NOT have `DevOps_Compass_Administrator` permission set
- [ ] Verify they cannot see Repository/PR/Contributor tabs
- [ ] Verify they cannot execute sync services

### Error Handling Testing
- [ ] Test with invalid repository name (should handle gracefully)
- [ ] Test with GitHub API down (should log error, not crash)
- [ ] Test with expired GitHub PAT (should return authentication error)

### Data Quality Testing
- [ ] Verify External ID uniqueness constraints
- [ ] Verify master-detail cascade delete (delete repo → contributors deleted)
- [ ] Verify date formats are correct (no timezone issues)
- [ ] Verify text fields handle special characters and emojis

---

## Test Results Summary

| Test # | Status | Pass/Fail | Notes |
|--------|--------|-----------|-------|
| T1.1 | | | |
| T1.2 | | | |
| T1.3 | | | |
| T1.4 | | | |
| T1.5 | | | |
| T1.6 | | | |
| T1.7 | | | |
| T1.8 | | | |
| T1.9 | | | |
| T1.10 | | | |

**Overall Status**: _______________

**Total Tests**: 10  
**Passed**: _______________  
**Failed**: _______________  
**Blocked**: _______________

---

## Issues/Bugs Found

| Issue # | Severity | Description | Test # | Status |
|---------|----------|-------------|--------|--------|
| | | | | |

---

## Sign-Off

**Tester**: Jordan  
**Date**: _______________  
**Signature**: _______________

**Approved for Production**: [ ] Yes [ ] No

**Notes**: _______________
