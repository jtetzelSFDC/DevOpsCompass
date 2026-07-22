# Story 2: Deployment Timeline - Implementation Summary

## Overview
Track Pull Request progression through the deployment pipeline from creation to production deployment.

---

## Data Model Changes

### 1. Pull_Request__c Object - Add Approval Tracking
**New Fields:**
- `Approved__c` (Checkbox) - Whether PR has been approved
- `Approved_Date__c` (DateTime) - When PR was approved

**Sync Logic:**
Update `PullRequestSyncService.cls` to call GitHub Reviews API:
```apex
GET /repos/{owner}/{repo}/pulls/{pull_number}/reviews
```
Set `Approved__c = true` if any review has `state = "APPROVED"`

**LOE:** 2 hours

---

### 2. Deployment__c Object - Link to Pull Requests
**New Field:**
- `Pull_Request__c` (Lookup to Pull_Request__c)

**Relationship:**
- One Pull Request → Many Deployments
- Each deployment represents the PR deployed to a specific environment (QA, UAT, PROD)

**Example:**
```
PR-542
  ├─ Deployment 1: QA (Successful, 7/17/2026)
  ├─ Deployment 2: UAT (In Progress, 7/18/2026)
  └─ Deployment 3: PROD (Pending)
```

**LOE:** 0.5 hours

---

## Timeline Stages

The deployment pipeline has 6 stages:

1. **Created** - PR opened (from `Pull_Request__c.Created_Date__c`)
2. **Approved** - Code reviewed (from `Pull_Request__c.Approved_Date__c`)
3. **Merged** - Merged to main (from `Pull_Request__c.Merged_Date__c`)
4. **Deployed to QA** - First environment deployment
5. **Deployed to UAT** - User acceptance testing
6. **Deployed to PROD** - Production release

Each stage can be:
- ✅ **Complete** - Stage finished with timestamp
- 🔵 **In Progress** - Currently happening
- ⭕ **Pending** - Not yet started

---

## Visual Design Options

### **Option A: SLDS Path Component** (Recommended for Speed)

**Appearance:** Horizontal progress bar with filled/empty circles

```
●━━━━━●━━━━━●━━━━━●━━━━━○━━━━━○━━━━━○
Created Approved Merged  QA    UAT   PROD
7/14    7/15     7/16    7/17   —     —
```

**Pros:**
- Native Salesforce look
- Fast to implement (~8 hours)
- Automatic accessibility
- Minimal maintenance

**Cons:**
- Less detailed
- Can't show deployment status/errors inline
- Limited customization

**Best for:** Quick MVP, standard Salesforce UI preference

---

### **Option B: Vertical Timeline** (Recommended for Rich UX)

**Appearance:** Vertical cards with deployment details

```
✓  Created                    Jul 14, 2026
│  Pull request opened           10:32 AM
│
✓  Approved                   Jul 15, 2026
│  Reviewed and approved          2:14 PM
│
✓  Merged                     Jul 16, 2026
│  Merged to main branch         11:05 AM
│
✓  Deployed to QA             Jul 17, 2026
┃  Status: Successful             8:45 AM
┃  Environment: QA Sandbox
│
◉  Deployed to UAT            In Progress
┃  Deployment scheduled
│
○  Deployed to PROD           Pending
   Awaiting UAT validation
```

**Pros:**
- Rich deployment details (status, environment, links)
- Modern, distinctive design
- Shows descriptions and context
- Animated "in progress" state
- Expandable for future features (logs, rollback)

**Cons:**
- Longer implementation (~12 hours)
- More CSS to maintain
- Custom accessibility testing

**Best for:** Better UX, detailed deployment tracking, future extensibility

---

## Technical Architecture

### Apex Service: `DeploymentTimelineService.cls`

**Method:**
```apex
@AuraEnabled(cacheable=true)
public static List<TimelineStage> getTimelineData(Id pullRequestId)
```

**Logic:**
1. Query `Pull_Request__c` for Created, Approved, Merged dates
2. Query `Deployment__c` records linked to PR
3. Group deployments by environment (keep most recent per env)
4. Build timeline stages with status (complete/current/pending)
5. Return structured data to LWC

**LOE:** 2-3 hours depending on option

---

### LWC Component: `deploymentTimeline`

**Files:**
- `deploymentTimeline.js` - Controller with @wire to Apex
- `deploymentTimeline.html` - Template rendering stages
- `deploymentTimeline.css` - Styling (minimal for Option A, extensive for Option B)
- `deploymentTimeline.js-meta.xml` - Metadata for record page

**Placement:** Pull_Request__c Lightning Record Page

**LOE:** 3-5 hours depending on option

---

## Testing Requirements

### Manual Test Cases (Story 2 Testing Guide)

**T2.1: PR Created Stage**
- Verify Created stage shows with PR open date
- Verify remaining stages show as pending

**T2.2: PR Approved Stage**
- Sync PR with GitHub approval
- Verify Approved stage shows with approval date
- Verify checkmark/complete status

**T2.3: PR Merged Stage**
- Merge PR in GitHub, sync
- Verify Merged stage shows with merge date

**T2.4: QA Deployment**
- Create Deployment__c record linked to PR
- Set Environment = QA, Status = Successful
- Verify QA stage shows as complete with deployment details

**T2.5: UAT Deployment**
- Create Deployment__c for UAT
- Verify UAT stage shows, QA→UAT line complete

**T2.6: PROD Deployment**
- Create Deployment__c for Production
- Verify entire timeline complete

**T2.7: In-Progress State**
- Create Deployment__c with Status = "In Progress"
- Verify stage shows current/active styling

**T2.8: Multiple Deployments**
- Create 2+ deployments to same environment
- Verify timeline shows most recent deployment

**T2.9: Failed Deployment**
- Create Deployment__c with Status = "Failed"
- Verify error badge/styling (Option B)

**T2.10: No Deployments**
- PR merged but no deployments
- Verify deployment stages show as pending with correct messaging

---

## Implementation Plan

### Phase 1: Schema (Day 1 - Morning)
1. Add `Pull_Request__c` lookup to `Deployment__c`
2. Add `Approved__c` and `Approved_Date__c` to `Pull_Request__c`
3. Deploy to org
4. Add fields to permission set

**LOE:** 1.5 hours

---

### Phase 2: PR Approval Sync (Day 1 - Afternoon)
1. Update `PullRequestSyncService.cls` to fetch reviews from GitHub
2. Parse review data and set Approved fields
3. Test with real PR that has approvals
4. Test with PR without approvals

**LOE:** 2 hours

---

### Phase 3: Apex Service (Day 2 - Morning)
1. Create `DeploymentTimelineService.cls`
2. Implement `getTimelineData` method
3. Write test class with 80%+ coverage
4. Test with various PR states

**LOE:** 2-3 hours

---

### Phase 4: LWC Component (Day 2 - Afternoon & Day 3)
1. Create `deploymentTimeline` LWC bundle
2. Wire to Apex service
3. Build template (simple or detailed based on option)
4. Style with CSS
5. Test data binding and error handling

**LOE:** 3-5 hours

---

### Phase 5: Page Layout (Day 3 - Morning)
1. Add component to Pull_Request__c Lightning page
2. Position near top of page
3. Test responsive behavior
4. Adjust sizing/spacing

**LOE:** 0.5 hours

---

### Phase 6: Testing & Documentation (Day 3 - Afternoon)
1. Execute all test cases (T2.1-T2.10)
2. Document results
3. Create `Story2_Testing_Guide.md`
4. Update README

**LOE:** 2 hours

---

## Total Effort Estimate

| Option | Total Hours | Days (6h/day) |
|--------|-------------|---------------|
| **Option A (SLDS Path)** | 8 hours | 1.5 days |
| **Option B (Vertical Timeline)** | 12 hours | 2 days |

---

## Recommendation

### For Tech Arch Review:

**Short-term (Sprint 1):** Option A
- Delivers core functionality fast
- Proven SLDS components
- Lower risk

**Long-term (Sprint 2+):** Migrate to Option B
- Better UX for deployment tracking
- More extensible for features like:
  - Deployment error logs
  - Rollback buttons
  - Approval workflows
  - Environment health status

**Hybrid Approach:**
Ship Option A now, refactor to Option B once deployment patterns are proven and user feedback is collected.

---

## Dependencies

1. ✅ Repository, Pull_Request, Deployment objects exist
2. ✅ Environment object exists (for deployment linking)
3. ✅ GitHub sync services functional
4. ⚠️ GitHub Reviews API access (confirm token has `repo` scope)
5. ⚠️ Deployment creation process (manual vs automated?)

---

## Questions for Tech Arch

1. **Deployment Creation:** How are Deployment__c records created? Manual, triggered by CI/CD, or synced from external tool?

2. **Environment Mapping:** How do we determine Environment type (QA/UAT/PROD)? Is it stored in `Environment__c.Type__c` or `Name`?

3. **Multiple Deployments:** If PR is deployed to QA twice (first failed, second succeeded), show latest or all attempts?

4. **Approval Source:** Should we sync approvals from GitHub only, or also support Salesforce-native approval process?

5. **Timeline Scope:** Should timeline show ALL environments or only QA→UAT→PROD? (e.g., skip DEV, Hotfix, etc.)

6. **Performance:** Expected number of deployments per PR? (for query optimization)

---

## Next Steps

1. **Review these options with Tech Arch**
2. **Choose Option A or B**
3. **Confirm answers to dependencies/questions**
4. **Create Story 2 branch**: `feature/2.0-deployment-timeline`
5. **Begin Phase 1: Schema changes**
