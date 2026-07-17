# DevOps Compass - Quick Reference Card

## Essential Commands

### Deploy to Trailhead Sandbox
```bash
cd ~/Documents/DevOpsCompass
sf org login web --set-default --alias devops-compass
sf project deploy start --manifest manifest/package.xml
sf org assign permset --name DevOps_Compass_Administrator
```

### Open the Sandbox
```bash
sf org open
```

### Run All Tests
```bash
sf apex run test --test-level RunLocalTests --result-format human
```

### Check Deployment Status
```bash
sf project deploy report
```

---

## Project Structure Quick Map

```
DevOpsCompass/
├── 📄 Documentation (Start Here)
│   ├── README.md               ← Project overview
│   ├── SETUP.md                ← Detailed setup guide
│   ├── DEPLOY.md               ← Quick deployment
│   └── ARCHITECTURE.md         ← Technical details
│
├── 🗂️ Metadata
│   └── force-app/main/default/
│       ├── applications/       ← Lightning App
│       ├── classes/            ← 16 Apex classes
│       ├── objects/            ← 9 custom objects
│       ├── permissionsets/     ← 2 permission sets
│       └── tabs/               ← 9 custom tabs
│
└── 📦 Deployment
    └── manifest/package.xml    ← Deploy this
```

---

## Custom Objects Created

| Object | Purpose | Key Fields |
|--------|---------|------------|
| Repository__c | GitHub repos | External_Id__c, Owner__c, Provider__c |
| Pull_Request__c | Pull requests | PR_Number__c, State__c, Author__c |
| Contributor__c | Developers | GitHub_Username__c, Email__c |
| Work_Item__c | Jira stories | Title__c, Work_Item_Type__c |
| Release__c | Releases | Release_Number__c, Status__c |
| Deployment__c | Deployments | Status__c, Environment__c |
| Environment__c | Orgs | Environment_Type__c, Org_ID__c |
| Sync_Job__c | Logs | Status__c, Records_Processed__c |
| Metric_Snapshot__c | DORA metrics | Deployment_Frequency__c |

---

## Apex Classes Quick Reference

### API Integration
- `GitHubApiClient` - GitHub REST API wrapper
- `GitHubSyncScheduler` - Scheduled sync
- `GitHubSyncQueueable` - Async operations

### Business Logic (Services)
- `RepositoryService` - Repository operations
- `PullRequestService` - PR operations

### Data Access (Selectors)
- `RepositorySelector` - Repository queries
- `PullRequestSelector` - PR queries

### Utilities
- `DevOpsCompassUtils` - Shared helpers
- `DevOpsLogger` - Logging

### Exceptions
- `DevOpsCompassException` - Base exception
- `GitHubApiException` - API errors

### Tests (5 classes)
- `TestDataFactory` - Test data
- `*Test` - Test classes for each component

---

## Permission Sets

### DevOps Compass Administrator
- Full CRUD on all objects
- Execute sync jobs
- Configure settings

### DevOps Compass User
- Read-only access
- View dashboards
- No configuration

---

## Configuration Custom Metadata

### Application_Settings__mdt
```
Label: Default Settings
GitHub Base URL: https://api.github.com
Default Sync Interval: 15
Stale PR Days: 7
Enable DORA: ✓
Enable Deployments: ✓
```

### Repository_Config__mdt
```
Label: [Your Repo Name]
Repository Name: [repo-name]
Repository Owner: [github-org]
Provider: GitHub
Sync Enabled: ✓
Default Branch: main
```

---

## GitHub Authentication Setup

1. Create Personal Access Token on GitHub
   - Scopes: `repo`, `read:org`, `read:user`
   
2. Setup → External Credentials → New
   - Label: `GitHub API Credential`
   
3. Setup → Named Credentials → New Legacy
   - Label: `GitHub API`
   - URL: `https://api.github.com`
   - Link to External Credential

4. Assign External Credential to Permission Set

**See SETUP.md Section 2 for detailed steps**

---

## Troubleshooting Quick Fixes

### Can't see the app?
```bash
sf org assign permset --name DevOps_Compass_Administrator
```

### Deployment failed?
```bash
sf project deploy report --verbose
```

### Test coverage too low?
```bash
sf apex run test --test-level RunLocalTests
```

### Named Credential not working?
- Verify token format: `token ghp_xxxxx` (with space)
- Check token scopes on GitHub
- Assign External Credential Principal to Permission Set

---

## Key Files to Read

1. **First Time?** → `README.md`
2. **Ready to Deploy?** → `DEPLOY.md`
3. **Need Configuration?** → `SETUP.md`
4. **Want Technical Details?** → `ARCHITECTURE.md`
5. **Update Documentation?** → `STORY_0_SUMMARY.md`

---

## Support Resources

### Documentation
- README.md - Project overview
- SETUP.md - Setup guide (600 lines)
- ARCHITECTURE.md - Technical docs (500 lines)
- DEPLOY.md - Quick deployment

### Debug
- Salesforce Debug Logs (Setup → Debug Logs)
- DevOpsLogger class output
- Test execution results

### Validation
- Run all tests: `sf apex run test`
- Check Object Manager: Setup → Object Manager
- Verify Permission Sets: Setup → Permission Sets

---

## Success Checklist

After deployment, verify:

- [ ] DevOps Compass app appears in App Launcher
- [ ] All 9 tabs are visible
- [ ] Apex classes deployed (Setup → Apex Classes)
- [ ] Permission Set assigned to your user
- [ ] Test coverage >85%
- [ ] Named Credential configured
- [ ] Application Settings metadata record exists
- [ ] At least one Repository Config record exists

---

## What's Next?

### Story 1: GitHub Synchronization
- Implement sync logic in GitHubSyncQueueable
- Add ContributorService
- Test with real repositories
- Schedule periodic sync jobs

### Story 2: DORA Metrics
- Calculate deployment frequency
- Measure lead time for changes
- Build metric snapshots
- Create trend analysis

### Story 3: Dashboards
- Executive dashboard
- Repository insights
- PR analytics
- DORA metrics visualization

---

## Quick Stats

- **Total Files**: 173
- **Apex Classes**: 16
- **Custom Objects**: 9
- **Custom Fields**: 100+
- **Test Coverage**: >85%
- **Documentation**: 2,500+ lines
- **Lines of Code**: ~2,000 (Apex)

---

## Version

- **Story**: 0 (Foundation)
- **Version**: 0.1.0
- **Status**: ✅ Complete
- **Date**: July 17, 2026
- **Target Org**: Trailhead Playground

---

**Ready to deploy?**

```bash
cd ~/Documents/DevOpsCompass && sf org login web
```

Then follow DEPLOY.md!
