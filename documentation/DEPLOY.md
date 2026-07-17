# Deployment Guide - DevOps Compass

## ⚠️ IMPORTANT: Two-Stage Deployment Required

DevOps Compass **must** be deployed in two stages due to metadata dependencies. Custom Metadata Types must deploy before Apex classes that reference them.

---

## Prerequisites

1. **Salesforce CLI** installed (v2.0+)
   ```bash
   sf --version
   ```

2. **Developer org or sandbox** with deployment rights

3. **Working directory** at project root:
   ```bash
   cd ~/Documents/DevOpsCompass
   ```

---

## Deployment Process (CLI - Recommended)

### Step 1: Authenticate to Your Org

```bash
sf org login web --set-default --alias devops-compass
```

**For Developer Orgs**: Browser will open automatically - log in with your credentials

**For Trailhead Playgrounds**: Use a Developer Edition org instead (authentication is simpler)

**Verify Authentication**:
```bash
sf org display --target-org devops-compass
```

---

### Step 2: Deploy Custom Metadata Types (Stage 1)

Deploy the custom metadata type definitions first:

```bash
sf project deploy start \
  --source-dir force-app/main/default/objects/Application_Settings__mdt \
  --source-dir force-app/main/default/objects/Repository_Config__mdt \
  --target-org devops-compass
```

**Expected Output**:
```
Status: Succeeded
Components: 2 deployed
```

---

### Step 3: Deploy All Other Components (Stage 2)

Deploy the remaining metadata (Apex classes, custom objects, tabs, etc.):

```bash
sf project deploy start \
  --manifest manifest/package.xml \
  --target-org devops-compass
```

**Expected Output**:
```
Status: Succeeded
Components: 128 deployed
Test Errors: 0
```

**This deploys**:
- ✅ 16 Apex Classes (11 production + 5 test)
- ✅ 9 Custom Objects with 100+ fields
- ✅ 9 Custom Tabs
- ✅ 2 Permission Sets
- ✅ 1 Lightning Application

---

### Step 4: Assign Permission Set

```bash
sf org assign permset \
  --name DevOps_Compass_Administrator \
  --target-org devops-compass
```

---

### Step 5: Open and Verify

```bash
sf org open --target-org devops-compass --path "/lightning/n/Repository__c"
```

**Verify in the org**:
- App Launcher → "DevOps Compass" app appears
- All 9 tabs are visible (Repository, Pull Request, etc.)
- Setup → Apex Classes → All 16 classes present
- Setup → Object Manager → All 9 custom objects exist

---

## Alternative: Deploy via VS Code

### Step 1: Authorize Org

1. Open `DevOpsCompass` folder in VS Code
2. Command Palette (Cmd+Shift+P or Ctrl+Shift+P)
3. Type: `SFDX: Authorize an Org`
4. Select **Production** for Developer orgs
5. Log in via browser

### Step 2: Deploy Custom Metadata Types

1. Right-click `force-app/main/default/objects/Application_Settings__mdt`
2. Select `SFDX: Deploy Source to Org`
3. Repeat for `Repository_Config__mdt`

### Step 3: Deploy Remaining Components

1. Right-click `manifest/package.xml`
2. Select `SFDX: Deploy Source in Manifest to Org`
3. Wait for completion

### Step 4: Assign Permission Set

Use Command Palette:
```
SFDX: Assign Permission Set to User
```
Select: `DevOps_Compass_Administrator`

---

## Troubleshooting

### ❌ "Invalid type: Application_Settings__mdt"

**Problem**: You tried to deploy everything at once  
**Solution**: Deploy custom metadata types FIRST (see Step 2 above)

### ❌ "Non-virtual type cannot be extended"

**Problem**: Old codebase, already fixed in current version  
**Solution**: Make sure you're deploying from the latest git commit:
```bash
git log --oneline -n 5
# Should show: "Fix: Make DevOpsCompassException virtual..."
```

### ❌ "Identifier name is reserved: number"

**Problem**: Old codebase, already fixed  
**Solution**: Same as above - deploy from latest commit

### ❌ Authentication timeout or password prompt

**Problem**: Trailhead Playgrounds have limited auth options  
**Solution**: Use a Developer Edition org instead:
1. Sign up at: https://developer.salesforce.com/signup
2. Use the org URL provided in welcome email
3. Authenticate with `sf org login web`

### ❌ "CustomMetadata was named in package.xml but not found"

**Problem**: Custom metadata types already deployed in Stage 1  
**Solution**: This is normal - ignore this warning, or remove CustomMetadata section from package.xml (already done in current version)

### Check Deployment Status

```bash
# View most recent deployment
sf project deploy report --use-most-recent --target-org devops-compass

# View detailed errors
sf project deploy report --use-most-recent --target-org devops-compass --verbose
```

### Validate Before Deploying

```bash
# Dry-run deployment (no actual changes)
sf project deploy validate --manifest manifest/package.xml --target-org devops-compass
```

### Run Tests Manually

```bash
# Run all local tests
sf apex run test --test-level RunLocalTests --target-org devops-compass --result-format human

# Run specific test class
sf apex run test --tests RepositoryServiceTest --target-org devops-compass --result-format human
```

---

## What Gets Deployed

### Stage 1: Custom Metadata Types (2 components)
- `Application_Settings__mdt` - 7 fields
- `Repository_Config__mdt` - 6 fields

### Stage 2: All Other Components (128 components)

**Apex Classes** (16):
- Services: `RepositoryService`, `PullRequestService`
- Selectors: `RepositorySelector`, `PullRequestSelector`
- Integration: `GitHubApiClient`, `GitHubSyncScheduler`, `GitHubSyncQueueable`
- Utilities: `DevOpsCompassUtils`, `DevOpsLogger`
- Exceptions: `DevOpsCompassException`, `GitHubApiException`
- Test Data: `TestDataFactory`
- Tests: `RepositoryServiceTest`, `PullRequestServiceTest`, `RepositorySelectorTest`, `DevOpsCompassUtilsTest`

**Custom Objects** (9):
- `Repository__c` - GitHub repositories
- `Pull_Request__c` - Pull requests
- `Contributor__c` - Developers
- `Work_Item__c` - Jira stories/bugs
- `Release__c` - Software releases
- `Deployment__c` - Salesforce deployments
- `Environment__c` - Org environments
- `Sync_Job__c` - Integration logs
- `Metric_Snapshot__c` - DORA metrics

**Lightning Components** (11):
- 9 Custom Tabs
- 1 Lightning Application
- 2 Permission Sets

**Total**: 130 components across both stages

---

## Post-Deployment Checklist

After successful deployment, verify:

- [ ] **Apex Classes**: Setup → Apex Classes → 16 classes visible
- [ ] **Custom Objects**: Setup → Object Manager → 9 custom objects exist
- [ ] **DevOps Compass App**: App Launcher → "DevOps Compass" appears
- [ ] **All Tabs Visible**: Click app → 9 tabs shown (Repository, Pull Request, etc.)
- [ ] **Permission Set**: Setup → Permission Sets → Both sets exist
- [ ] **Permission Assigned**: Your user has `DevOps_Compass_Administrator`
- [ ] **No Errors**: Debug logs show no compilation errors
- [ ] **Objects Accessible**: Try creating a test Repository record

---

## Next Steps After Deployment

### 1. Configure GitHub Integration

Follow [SETUP.md](./SETUP.md) Section 2:
- Create GitHub Personal Access Token
- Set up External Credential in Salesforce
- Configure Named Credential (`GitHub_API`)

### 2. Add Configuration Records

Create custom metadata records:
- **Application Settings**: Setup → Custom Metadata Types → Application Settings → Manage Records
- **Repository Config**: Add repos to sync

### 3. Test the Integration (Story 1)

Story 0 is foundation only - actual sync happens in Story 1.

---

## Deployment Timeline

Based on successful Story 0 deployment:

| Stage | Components | Time | Status |
|-------|-----------|------|--------|
| Auth | Login to org | ~30s | ✅ |
| Stage 1 | Custom Metadata Types (2) | ~30s | ✅ |
| Stage 2 | All other components (128) | ~2min | ✅ |
| Assign | Permission set | ~10s | ✅ |
| Verify | Open org and check | ~1min | ✅ |
| **Total** | **130 components** | **~4min** | ✅ |

---

## Common Questions

### Q: Why two stages?

**A**: Apex classes reference Custom Metadata Types. Salesforce requires the types to exist before classes that use them can compile.

### Q: Can I deploy via Change Sets?

**A**: Yes, but you'll need to manually select 130+ components in the correct order. CLI is much faster.

### Q: What if I already deployed everything together?

**A**: If it worked, great! If you got "Invalid type" errors, follow the two-stage process above.

### Q: Do I need to run tests during deployment?

**A**: No - tests run automatically. All 5 test classes execute during Stage 2 deployment.

### Q: Can I use this in production?

**A**: Yes, but deploy to a sandbox first. Story 0 is foundation only - no data sync happens yet (that's Story 1).

---

## Quick Reference: One-Line Deployment

```bash
# Complete deployment (requires auth first)
sf project deploy start --source-dir force-app/main/default/objects/Application_Settings__mdt --source-dir force-app/main/default/objects/Repository_Config__mdt && \
sf project deploy start --manifest manifest/package.xml && \
sf org assign permset --name DevOps_Compass_Administrator
```

---

## Need Help?

- **Setup Instructions**: [SETUP.md](./SETUP.md)
- **Technical Details**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Deployment Success Summary**: [DEPLOYMENT_SUCCESS.md](./DEPLOYMENT_SUCCESS.md)
- **Salesforce CLI Docs**: https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/

---

**Ready to deploy?** Follow Step 1 above!
