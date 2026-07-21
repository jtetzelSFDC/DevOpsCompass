# DevOps Compass Test Scripts

This folder contains comprehensive testing documentation and executable scripts for manual testing of DevOps Compass functionality.

## Contents

| File | Purpose |
|------|---------|
| **[Story1_Testing_Guide.md](./Story1_Testing_Guide.md)** | Complete testing guide with 10 test cases for Story 1 |
| **[ExecutableTestScripts.apex](./ExecutableTestScripts.apex)** | Copy-paste ready Apex scripts for Developer Console |

## Quick Start

### Option 1: Comprehensive Testing (Recommended)

1. Open **[Story1_Testing_Guide.md](./Story1_Testing_Guide.md)**
2. Follow each test case in order (T1.1 → T1.10)
3. Document your results in the guide
4. Use the executable scripts from **[ExecutableTestScripts.apex](./ExecutableTestScripts.apex)**

### Option 2: Quick Smoke Test

If you just want to verify everything works:

1. Open Developer Console in your Salesforce org
2. Go to Debug → Open Execute Anonymous Window
3. Copy the **"Complete Sync All-in-One Script"** from **[ExecutableTestScripts.apex](./ExecutableTestScripts.apex)**
4. Paste and Execute
5. Check the logs for success messages
6. Navigate to Repository tab and verify data synced

## Testing Checklist

### Prerequisites ✅
- [ ] GitHub Personal Access Token configured
- [ ] Named Credential `GitHubAPI` is active
- [ ] Permission Set `DevOps_Compass_Administrator` assigned
- [ ] Story 1 components deployed to sandbox

### Core Functionality Tests
- [ ] T1.1: GitHub API Connectivity
- [ ] T1.2: Repository Sync
- [ ] T1.3: Pull Request Sync  ← **YOUR PRIORITY TEST**
- [ ] T1.4: Contributor Sync

### UI Component Tests
- [ ] T1.5: Repository Overview Card (LWC)
- [ ] T1.6: Pull Request Metrics Card (LWC)
- [ ] T1.7: Contributor Leaderboard (LWC)
- [ ] T1.8: Recent Activity Feed (LWC)

### Navigation & Access Tests
- [ ] T1.9: Pull Request Tab Visibility  ← **YOUR PRIORITY TEST**

### Performance Tests
- [ ] T1.10: Bulk Sync Performance

## What to Test First

Based on your needs, I recommend testing in this order:

1. **T1.1**: GitHub API Connectivity (5 min)
   - Ensures your GitHub PAT is working

2. **T1.2**: Repository Sync (5 min)
   - Creates the repository record needed for other tests

3. **T1.3**: Pull Request Sync (10 min) ⭐
   - This is one of your stated priorities
   - Syncs the 5 PRs we created earlier

4. **T1.9**: Pull Request Tab Visibility (5 min) ⭐
   - Your other stated priority
   - Verifies you can see PRs in the UI

5. **T1.6**: Pull Request Metrics Card (10 min)
   - Visual verification of PR data

6. **Others**: As time permits

## Common Issues & Solutions

### Issue: "Named Credential 'GitHubAPI' not found"
**Solution**: Complete the setup in [PATSetup.MD](../documentation/PATSetup.MD)

### Issue: "Insufficient privileges" error
**Solution**: 
```bash
sf org assign permset --name DevOps_Compass_Administrator
```

### Issue: No pull requests showing in Pull Request tab
**Solution**: 
1. Run Test Script 1.3 to sync PRs
2. Verify the Repository record exists first (Test 1.2)
3. Check the External ID on the repository matches `jtetzelSFDC/DevOpsCompass`

### Issue: LWC components not visible in Lightning App Builder
**Solution**: 
1. Verify components are deployed: `sf project deploy report`
2. Check the record page type matches the component's target (Repository__c)
3. Refresh the Lightning App Builder

## Test Data Notes

The 5 pull requests you created earlier (feature/story1, feature/story1a-e) are in your GitHub repository. When you run Test Script 1.3, these PRs will sync into Salesforce and become visible in:

- Pull Request tab (List View)
- Pull Request Metrics Card on Repository page
- Recent Activity Feed on Repository page

## Reporting Issues

If you find issues during testing:

1. Document in the "Issues/Bugs Found" section of Story1_Testing_Guide.md
2. Include:
   - Test number where issue occurred
   - Severity (Critical/High/Medium/Low)
   - Steps to reproduce
   - Expected vs Actual result
   - Debug log output (if applicable)

## Additional Testing

Beyond the 10 core tests, consider:

### Security Testing
- Test with a user who does NOT have the Administrator permission set
- Verify record-level security (Repository → Contributors cascade)

### Data Quality Testing
- Test with repositories that have special characters in names
- Test with very large PR titles (> 255 chars)
- Test date handling across timezones

### Error Handling Testing
- Test with invalid repository name
- Test with expired GitHub PAT
- Test with GitHub API rate limit reached

## Questions?

Refer to:
- **[Story1_Completion_Summary.md](../documentation/Story1_Completion_Summary.md)** - Story 1 technical details
- **[PATSetup.MD](../documentation/PATSetup.MD)** - GitHub authentication setup
- **[DEPLOY.md](../documentation/DEPLOY.md)** - Deployment guide

---

**Good luck with testing!** 🚀

Start with the **Complete Sync All-in-One Script** from ExecutableTestScripts.apex to quickly verify everything works end-to-end.
