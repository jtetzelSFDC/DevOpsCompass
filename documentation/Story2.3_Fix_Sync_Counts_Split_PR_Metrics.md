# Story 2.3: Fix Sync Counts and Split PR Metrics

**Status**: ✅ Complete  
**Date**: July 23, 2026  
**Deployed To**: devops-compass sandbox

## Overview

Fixed incorrect sync result counts displaying in the sync button component and enhanced the UI to distinguish between open and total pull requests, providing clearer insights into repository activity.

## Problem Statement

### User-Reported Issues
After clicking "Sync All Repositories":
- **0** Repositories displayed (expected: **1**)
- **0** Pull Requests displayed (expected: **3+**)
- **7** Contributors displayed (expected: **1**)

User quote: "Seems like all records are showing up as contributors on the page."

### Additional Enhancement Request
User asked: "Do you think we should only show open pull requests? Maybe just split the result, show total historical pull requests so that people will not get confused? Then show currently open as a separate box?"

## Root Cause Analysis

### Issue 1: Incorrect Field Mapping
The LWC was reading counts from the wrong fields:
```javascript
// OLD - WRONG
this.repositoriesSynced = job.Records_Inserted__c || 0;       // Generic insert count
this.pullRequestsSynced = job.Records_Updated__c || 0;        // Generic update count
this.contributorsSynced = (job.Records_Processed__c || 0) - this.repositoriesSynced - this.pullRequestsSynced;  // Subtraction math
```

**Why This Failed:**
- `Records_Inserted__c` and `Records_Updated__c` were never populated by the queueable
- Subtraction logic assumed all remaining records were contributors (incorrect)
- No way to distinguish between entity types (repos, PRs, contributors)

### Issue 2: Missing Data Storage
`GitHubSyncQueueable` tracked counts in local variables but never persisted them:
```apex
Integer repositoriesSynced = 0;
Integer pullRequestsSynced = 0;
Integer contributorsSynced = 0;
// ... counted during execution ...
updateSyncJob(status, totalRecords, errorMessage);  // Only total passed!
```

### Issue 3: No Open PR Tracking
All pull requests (open, closed, merged) were counted together with no way to show current activity.

## Solution Architecture

### 1. Added Dedicated Count Fields
Created 4 new fields on `Sync_Job__c`:

| Field API Name | Label | Type | Description |
|----------------|-------|------|-------------|
| `Repositories_Synced__c` | Repositories Synced | Number(18,0) | Count of repositories synced |
| `Pull_Requests_Synced__c` | Pull Requests Synced | Number(18,0) | Count of all PRs synced (total historical) |
| `Open_Pull_Requests__c` | Open Pull Requests | Number(18,0) | Count of currently open PRs |
| `Contributors_Synced__c` | Contributors Synced | Number(18,0) | Count of contributors synced |

### 2. Updated Queueable to Track Open PRs
**File**: `GitHubSyncQueueable.cls`

Added tracking for open PRs:
```apex
public void execute(QueueableContext context) {
    Integer repositoriesSynced = 0;
    Integer pullRequestsSynced = 0;
    Integer openPullRequests = 0;  // NEW
    Integer contributorsSynced = 0;
    
    // ... sync logic ...
    
    // Count open PRs after upserting
    if (prDataMap.containsKey(repoKey)) {
        List<Pull_Request__c> prs = upsertPullRequestData(prDataMap.get(repoKey), updatedRepo.Id);
        pullRequestsSynced += prs.size();
        
        // Count open PRs
        for (Pull_Request__c pr : prs) {
            if (pr.State__c == 'open') {
                openPullRequests++;
            }
        }
    }
}
```

Updated method signature to accept all counts:
```apex
private void updateSyncJob(String status, Integer recordsProcessed, Integer repositoriesSynced,
                           Integer pullRequestsSynced, Integer openPullRequests, Integer contributorsSynced, String errorLog) {
    Sync_Job__c job = [SELECT Id FROM Sync_Job__c WHERE Id = :syncJobId LIMIT 1];
    job.Status__c = status;
    job.End_Time__c = System.now();
    job.Records_Processed__c = recordsProcessed;
    job.Repositories_Synced__c = repositoriesSynced;           // NEW
    job.Pull_Requests_Synced__c = pullRequestsSynced;         // NEW
    job.Open_Pull_Requests__c = openPullRequests;             // NEW
    job.Contributors_Synced__c = contributorsSynced;           // NEW
    job.Error_Count__c = String.isBlank(errorLog) ? 0 : 1;
    job.Error_Log__c = errorLog;
    update job;
}
```

### 3. Updated Orchestrator to Query New Fields
**File**: `GitHubSyncOrchestrator.cls`

```apex
@AuraEnabled(cacheable=false)
public static Sync_Job__c getSyncJobStatus(Id syncJobId) {
    return [
        SELECT Id, Status__c, Records_Processed__c, Records_Inserted__c,
               Records_Updated__c, Repositories_Synced__c, Pull_Requests_Synced__c,
               Open_Pull_Requests__c, Contributors_Synced__c, Error_Log__c, Start_Time__c, End_Time__c
        FROM Sync_Job__c
        WHERE Id = :syncJobId
        LIMIT 1
    ];
}
```

### 4. Updated LWC to Read Correct Fields
**File**: `syncAllRepositories.js`

```javascript
// NEW - CORRECT
this.repositoriesSynced = job.Repositories_Synced__c || 0;
this.pullRequestsSynced = job.Pull_Requests_Synced__c || 0;
this.openPullRequests = job.Open_Pull_Requests__c || 0;         // NEW
this.contributorsSynced = job.Contributors_Synced__c || 0;
```

### 5. Updated UI to 4-Box Layout
**File**: `syncAllRepositories.html`

Changed from 3 equal boxes to 4 equal boxes:
```html
<!-- OLD: 3 boxes, 1-of-3 -->
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
    <div class="stat-box">
        <div class="stat-number">{repositoriesSynced}</div>
        <div class="stat-label">Repositories</div>
    </div>
</div>
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
    <div class="stat-box">
        <div class="stat-number">{pullRequestsSynced}</div>
        <div class="stat-label">Pull Requests</div>
    </div>
</div>
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-3">
    <div class="stat-box">
        <div class="stat-number">{contributorsSynced}</div>
        <div class="stat-label">Contributors</div>
    </div>
</div>

<!-- NEW: 4 boxes, 1-of-4 -->
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
    <div class="stat-box">
        <div class="stat-number">{repositoriesSynced}</div>
        <div class="stat-label">Repositories</div>
    </div>
</div>
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
    <div class="stat-box">
        <div class="stat-number">{openPullRequests}</div>
        <div class="stat-label">Open PRs</div>
    </div>
</div>
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
    <div class="stat-box">
        <div class="stat-number">{pullRequestsSynced}</div>
        <div class="stat-label">Total PRs</div>
    </div>
</div>
<div class="slds-col slds-size_1-of-1 slds-medium-size_1-of-4">
    <div class="stat-box">
        <div class="stat-number">{contributorsSynced}</div>
        <div class="stat-label">Contributors</div>
    </div>
</div>
```

## User Experience Improvement

### Before Story 2.3
```
┌─────────────────┬─────────────────┬─────────────────┐
│        0        │        0        │        7        │
│  Repositories   │  Pull Requests  │  Contributors   │
└─────────────────┴─────────────────┴─────────────────┘
```
❌ All counts wrong  
❌ No distinction between open/closed PRs  
❌ Confusing for users

### After Story 2.3
```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│      1      │      3      │      5      │      1      │
│ Repositories│  Open PRs   │  Total PRs  │Contributors │
└─────────────┴─────────────┴─────────────┴─────────────┘
```
✅ All counts accurate  
✅ Clear distinction: open PRs (current activity) vs total PRs (historical)  
✅ Users can quickly see what's currently active

## Files Modified

### Custom Fields (New)
- `Sync_Job__c.Repositories_Synced__c`
- `Sync_Job__c.Pull_Requests_Synced__c`
- `Sync_Job__c.Open_Pull_Requests__c`
- `Sync_Job__c.Contributors_Synced__c`

### Apex Classes (Modified)
- **GitHubSyncQueueable.cls**
  - Added `openPullRequests` local variable
  - Added loop to count PRs with `State__c == 'open'`
  - Updated `updateSyncJob()` signature to accept 4 individual counts
  - Updated all `updateSyncJob()` calls to pass all counts

- **GitHubSyncOrchestrator.cls**
  - Updated `getSyncJobStatus()` SOQL to include 4 new fields

### Lightning Web Component (Modified)
- **syncAllRepositories.js**
  - Added `@track openPullRequests = 0;`
  - Updated `checkSyncJobStatus()` to read from dedicated fields
  - Removed incorrect subtraction math

- **syncAllRepositories.html**
  - Changed from 3-box to 4-box layout
  - Changed grid sizing from `1-of-3` to `1-of-4`
  - Renamed "Pull Requests" to "Total PRs"
  - Added "Open PRs" box

## Testing

### Manual Testing Steps
1. ✅ Navigate to DevOps Compass app
2. ✅ Click "Sync All Repositories" button
3. ✅ Wait for polling to complete (~2-5 seconds)
4. ✅ Verify 4 boxes display with correct counts:
   - Repositories: 1
   - Open PRs: 3
   - Total PRs: 5
   - Contributors: 1

### Test Apex Query
```apex
List<Sync_Job__c> jobs = [
    SELECT Id, Name, Repositories_Synced__c, Pull_Requests_Synced__c,
           Open_Pull_Requests__c, Contributors_Synced__c
    FROM Sync_Job__c
    ORDER BY CreatedDate DESC
    LIMIT 1
];
System.debug('Repos: ' + jobs[0].Repositories_Synced__c);
System.debug('Open PRs: ' + jobs[0].Open_Pull_Requests__c);
System.debug('Total PRs: ' + jobs[0].Pull_Requests_Synced__c);
System.debug('Contributors: ' + jobs[0].Contributors_Synced__c);
```

### Edge Cases Tested
- ✅ No active repositories → All counts show 0
- ✅ Repository with no PRs → Repos=1, Open PRs=0, Total PRs=0
- ✅ Repository with only closed PRs → Open PRs=0, Total PRs > 0
- ✅ Repository with mixed open/closed PRs → Open PRs < Total PRs

## Business Value

### For DevOps Teams
- **Quick Activity Scan**: See at a glance how many PRs need attention (Open PRs)
- **Historical Context**: Total PRs shows overall repository activity level
- **Accurate Tracking**: No more confusion about what data was synced

### For Product Managers
- **Sprint Planning**: Open PRs indicates current work in progress
- **Velocity Tracking**: Total PRs over time shows team throughput
- **Resource Planning**: Contributor count shows team size

### For Executives
- **Dashboard Accuracy**: Can trust the numbers displayed
- **Current State**: Open PRs is a real-time metric, not historical noise

## Future Enhancements

### Short Term (Next Sprint)
1. **PR Age Distribution**: Show how long PRs have been open
   - Fields: `Oldest_Open_PR_Days__c`, `Average_PR_Age_Days__c`
2. **Stale PR Alerts**: Flag PRs open > 30 days
3. **Sync History Chart**: Line chart showing Open PRs trend over time

### Medium Term
1. **Drill-Down**: Click "Open PRs" box → navigate to filtered list view
2. **PR Status Breakdown**: Show open/closed/merged counts separately
3. **Contributor Activity**: Show active vs inactive contributors

### Long Term
1. **Predictive Analytics**: "Projected merge date" for open PRs
2. **Anomaly Detection**: Alert when PR counts spike unexpectedly
3. **Custom Metrics**: User-defined calculations (e.g., "PR velocity")

## Deployment Notes

### Prerequisites
- Story 2.2 must be deployed (polling mechanism required)

### Deployment Order
1. Deploy Sync_Job__c fields
2. Deploy GitHubSyncQueueable and GitHubSyncOrchestrator
3. Deploy syncAllRepositories LWC
4. Hard refresh browser (Cmd+Shift+R / Ctrl+Shift+R)

### Rollback Plan
If issues occur:
1. Revert LWC to use old 3-box layout
2. LWC can still read `Records_Processed__c` for total count
3. Fields can remain (harmless if unpopulated)

### Post-Deployment
- No manual steps required
- Existing Sync_Job__c records will have null values for new fields (expected)
- Next sync will populate new fields correctly

## Lessons Learned

1. **Field Naming Matters**: Generic fields like `Records_Inserted__c` are ambiguous; specific fields like `Repositories_Synced__c` are self-documenting

2. **User Feedback is Gold**: User immediately spotted the confusing data → led to better UX with open vs total PRs split

3. **Don't Derive, Store**: Deriving counts with subtraction math is fragile; storing each count explicitly is reliable

4. **Iterate Based on Usage**: Started with simple count display (Story 2.2), enhanced with split metrics (Story 2.3) based on real usage

## Related Stories

- **Story 2.1**: Auto Sync Job - Created base sync infrastructure
- **Story 2.2**: Real-Time Results - Added polling to display sync results
- **Story 2.3**: ✅ This story - Fixed counts and split PR metrics
- **Story 2.4** (Future): Scheduled nightly sync job
- **Story 3.x** (Next): Jira integration for ticket tracking

## References

- [Salesforce SOQL Aggregate Functions](https://developer.salesforce.com/docs/atlas.en-us.soql_sosl.meta/soql_sosl/sforce_api_calls_soql_select_aggregate.htm)
- [Lightning Design System Grid](https://www.lightningdesignsystem.com/utilities/grid/)
- User feedback: "Seems like all records are showing up as contributors on the page."

---

**Completion Checklist**:
- ✅ Accurate repository count
- ✅ Accurate contributor count
- ✅ Split PRs into open vs total
- ✅ 4-box layout deployed
- ✅ All fields created and populated
- ✅ Documentation complete
- ✅ Tested in devops-compass sandbox
- ✅ User confirmed "Perfect"
