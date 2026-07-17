# DevOps Compass - Setup Guide

## Story 0: Project Foundation

This document provides comprehensive setup instructions for deploying the DevOps Compass foundation into a Salesforce sandbox.

---

## 1. Pre-Build Information Needed

Before deployment, please provide the following information:

### Salesforce Environment
- **Sandbox Login URL**: `https://brave-hawk-86tr29-dev-ed.trailblaze.lightning.force.com/`
- **Org Type**: Trailhead Playground (Developer Edition)
- **Salesforce Edition**: Developer Edition
- **API Version**: 62.0

### GitHub Integration
- **GitHub Organization Name**: _[To be provided]_
- **Target Repositories**: _[List repositories to sync]_
- **Authentication Method**: Personal Access Token (recommended for V1)
- **GitHub Username**: _[To be provided]_

### Existing DevOps Tools
- **Copado Present**: Yes / No / Unknown
- **Gearset Present**: Yes / No / Unknown
- **Other CI/CD Tools**: _[List if known]_

---

## 2. Manual Credential Setup

### Step 1: Create GitHub Personal Access Token

1. Log into GitHub (github.com)
2. Click your profile picture (top-right) → **Settings**
3. Scroll down and click **Developer settings** (left sidebar, bottom)
4. Click **Personal access tokens** → **Tokens (classic)**
5. Click **Generate new token** → **Generate new token (classic)**
6. Give it a descriptive name: `DevOps Compass - Trailhead Sandbox`
7. Set expiration: **90 days** (or custom)
8. Select the following scopes (minimum required for V1):
   - ✅ `repo` (Full control of private repositories)
     - Includes: `repo:status`, `repo_deployment`, `public_repo`, `repo:invite`, `security_events`
   - ✅ `read:org` (Read org and team membership)
   - ✅ `read:user` (Read user profile data)
   - ✅ `user:email` (Access user email addresses)
9. Click **Generate token**
10. **IMPORTANT**: Copy the token immediately - you won't see it again
11. Store securely (password manager recommended)

**Example Token Format**: `ghp_abcdefghijklmnopqrstuvwxyz1234567890ABC`

---

### Step 2: Create External Credential in Salesforce

1. Log into your Salesforce sandbox
2. Navigate to **Setup** (gear icon, top-right)
3. In Quick Find, search for: **Named Credentials**
4. Click **Named Credentials** under Security
5. Click the **External Credentials** tab
6. Click **New**
7. Fill in the form:
   - **Label**: `GitHub API Credential`
   - **Name**: `GitHub_API_Credential` (auto-populated)
   - **Authentication Protocol**: Select **Custom**
8. Click **Save**

9. After saving, you'll see the External Credential detail page
10. Scroll down to **Principals** section
11. Click **New**
12. Fill in the Principal form:
   - **Parameter Name**: `Authorization`
   - **Sequence Number**: `1`
   - **Identity Type**: Select **Named Principal`
   - **Authentication Parameter**: In the dropdown select **Custom`
13. Click **Save**

14. Now you'll see the Principal created
15. Click **Edit** next to the Principal you just created
16. In the **Authentication Parameters** section:
   - **Parameter 1**: Enter your GitHub token in this format:
     ```
     token YOUR_GITHUB_TOKEN_HERE
     ```
     Example: `token ghp_abcdefghijklmnopqrstuvwxyz1234567890ABC`
17. Click **Save**

---

### Step 3: Create Named Credential in Salesforce

1. Still in **Setup** → **Named Credentials**
2. Click the **Named Credentials** tab
3. Click **New Legacy** (we're using Legacy for callout simplicity)
4. Fill in the form:
   - **Label**: `GitHub API`
   - **Name**: `GitHub_API` (auto-populated)
   - **URL**: `https://api.github.com`
   - **Identity Type**: Select **Named Principal**
   - **Authentication Protocol**: Select **Custom**
   - **External Credential**: Select `GitHub_API_Credential` (the one you just created)
   - **Generate Authorization Header**: ✅ **Checked**
   - **Allow Merge Fields in HTTP Header**: ✅ **Checked**
   - **Allow Merge Fields in HTTP Body**: ✅ **Checked**
5. Click **Save**

---

### Step 4: Assign External Credential Principal to Permission Set

1. Navigate to **Setup** → **Permission Sets**
2. Find and click **DevOps Compass Administrator**
3. Scroll to **External Credential Principal Access**
4. Click **Edit**
5. Find `GitHub_API_Credential` in the Available list
6. Move it to the **Enabled** list
7. Click **Save**

---

## 3. Deployment Steps

### Option A: Deploy via Salesforce CLI

1. Authenticate to your sandbox:
   ```bash
   sf org login web --alias devops-compass-sandbox
   ```

2. Navigate to the project directory:
   ```bash
   cd ~/Documents/DevOpsCompass
   ```

3. Deploy the metadata:
   ```bash
   sf project deploy start --manifest manifest/package.xml --target-org devops-compass-sandbox
   ```

4. Wait for deployment to complete (typically 2-5 minutes)

5. Check deployment status:
   ```bash
   sf project deploy report --target-org devops-compass-sandbox
   ```

### Option B: Deploy via Workbench

1. Open Workbench: https://workbench.developerforce.com
2. Log in with your Salesforce sandbox credentials
3. Select **Environment**: Production/Developer Edition
4. Click **Login with Salesforce**
5. Go to **migration** → **Deploy**
6. Create a ZIP file of the `force-app/main/default` directory
7. Upload the ZIP file
8. Check **Single Package**
9. Check **Rollback On Error**
10. Click **Next** → **Deploy**

---

## 4. Post-Deployment Configuration

### Step 1: Assign Permission Set to Your User

1. Navigate to **Setup** → **Users** → **Users**
2. Click on your name
3. Scroll to **Permission Set Assignments**
4. Click **Edit Assignments**
5. Add: `DevOps Compass Administrator`
6. Click **Save**

### Step 2: Configure Application Settings (Custom Metadata)

1. Navigate to **Setup** → **Custom Metadata Types**
2. Click **Manage Records** next to **Application Settings**
3. Click **New**
4. Fill in:
   - **Label**: `Default Settings`
   - **Application Settings Name**: `Default_Settings`
   - **GitHub Base URL**: `https://api.github.com`
   - **Default Sync Interval**: `15` (minutes)
   - **Dashboard Refresh**: `5` (minutes)
   - **Default Date Range**: `30` (days)
   - **Stale PR Days**: `7` (days)
   - **Enable DORA**: ✅ Checked
   - **Enable Deployments**: ✅ Checked
5. Click **Save**

### Step 3: Configure Repository Settings (Custom Metadata)

1. Still in **Custom Metadata Types**
2. Click **Manage Records** next to **Repository Config**
3. Click **New** for each repository you want to sync
4. Fill in:
   - **Label**: `[Repository Display Name]`
   - **Repository Config Name**: `[Repository_Name]` (no spaces)
   - **Repository Name**: `[actual-repo-name]`
   - **Provider**: `GitHub`
   - **Repository Owner**: `[github-org-or-username]`
   - **Sync Enabled**: ✅ Checked
   - **Polling Interval**: `15` (or leave blank to use default)
   - **Default Branch**: `main` (or `master`)
5. Click **Save**
6. Repeat for each repository

---

## 5. Salesforce Governor Limits Reference

| Limit Type | Developer Edition | Enterprise Edition | Notes |
|------------|-------------------|-------------------|--------|
| **Scheduled Apex Jobs** | 5 concurrent | 100 concurrent | Org-wide limit |
| **HTTP Callouts per Transaction** | 100 | 100 | Same across editions |
| **Apex CPU Time** | 10,000 ms | 10,000 ms | Per transaction |
| **Apex Heap Size** | 6 MB | 6 MB | Per transaction |
| **SOQL Queries per Transaction** | 100 | 100 | Synchronous context |
| **DML Statements per Transaction** | 150 | 150 | INSERT/UPDATE/DELETE |
| **Daily API Request Limit** | 15,000 | 1,000 + (1,000 × licenses) | Includes REST/SOAP |
| **Platform Cache** | Not available | Available (varies) | Check org limits |
| **Batch Apex** | 5 concurrent | 5 concurrent | Per org |
| **Future Methods** | 50 per transaction | 50 per transaction | Queueable preferred |

### Check Your Org Limits
```apex
// Run in Developer Console Anonymous Apex
Map<String, System.OrgLimit> limits = OrgLimits.getMap();
System.debug('API Requests: ' + limits.get('DailyApiRequests'));
System.debug('Async Apex Jobs: ' + limits.get('DailyAsyncApexExecutions'));
```

---

## 6. GitHub API Limits Reference

| Limit Type | Authenticated | Unauthenticated | Notes |
|------------|---------------|-----------------|--------|
| **REST API Rate Limit** | 5,000 requests/hour | 60 requests/hour | Per user token |
| **Search API** | 30 requests/minute | 10 requests/minute | Separate limit |
| **GraphQL API** | 5,000 points/hour | N/A | Query complexity-based |
| **Concurrent Requests** | ~100 concurrent | Variable | Secondary rate limit |
| **Abuse Detection** | Triggered by patterns | Triggered by patterns | Auto-throttling |

### Checking Rate Limit via API

GitHub returns rate limit info in response headers:
- `X-RateLimit-Limit`: Maximum requests allowed
- `X-RateLimit-Remaining`: Requests remaining
- `X-RateLimit-Reset`: Unix timestamp when limit resets

**View Current Rate Limit**:
```bash
curl -H "Authorization: token YOUR_TOKEN" https://api.github.com/rate_limit
```

**Example Response**:
```json
{
  "resources": {
    "core": {
      "limit": 5000,
      "remaining": 4999,
      "reset": 1640000000
    }
  }
}
```

---

## 7. Recommended Monitoring Checklist

After deploying Story 0, verify the following:

### ✅ Authentication & Connectivity
- [ ] Named Credential appears in Setup → Named Credentials
- [ ] External Credential Principal is assigned to Permission Set
- [ ] Test API connectivity (run test script below)

```apex
// Run in Developer Console → Debug → Open Execute Anonymous Window
try {
    HttpResponse res = GitHubApiClient.get('/rate_limit');
    System.debug('GitHub API Status: ' + res.getStatusCode());
    System.debug('Response: ' + res.getBody());
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
```

**Expected Output**: Status `200` with JSON showing rate limit info

---

### ✅ Custom Objects
- [ ] Repository__c object exists
- [ ] Pull_Request__c object exists
- [ ] All 9 custom objects are deployed
- [ ] Object permissions are visible in Permission Sets

**Verify**:
1. Setup → Object Manager
2. Search for `Repository`
3. Click on `Repository` custom object
4. Verify fields exist (External_Id__c, Provider__c, etc.)

---

### ✅ Apex Classes
- [ ] 16 Apex classes deployed successfully
- [ ] Test classes achieve >85% coverage
- [ ] No compilation errors

**Verify**:
1. Setup → Apex Classes
2. Search for `GitHubApiClient`
3. Click **Run All Tests** button (in Developer Console)

---

### ✅ Permission Sets
- [ ] DevOps Compass Administrator exists
- [ ] DevOps Compass User exists
- [ ] Administrator permission set assigned to your user
- [ ] External Credential Principal access granted

**Verify**:
1. Setup → Permission Sets
2. Click `DevOps Compass Administrator`
3. Review Object Permissions and Apex Class Access

---

### ✅ Lightning Application
- [ ] DevOps Compass app appears in App Launcher
- [ ] All tabs are visible in navigation
- [ ] App opens without errors

**Verify**:
1. Click App Launcher (waffle icon, top-left)
2. Search for `DevOps`
3. Click `DevOps Compass`
4. Verify tabs: Repositories, Pull Requests, Deployments, etc.

---

### ✅ Custom Metadata
- [ ] Application Settings metadata type exists
- [ ] Repository Config metadata type exists
- [ ] At least one Application Settings record created
- [ ] At least one Repository Config record created

**Verify**:
1. Setup → Custom Metadata Types
2. Click Manage Records next to Application Settings
3. Verify `Default Settings` record exists

---

### ✅ Scheduled Jobs (Future)
- [ ] GitHubSyncScheduler class is deployable
- [ ] Can schedule via Developer Console (test only, don't schedule yet)

**Test**:
```apex
// DO NOT RUN YET - Just verify it compiles
String cron = '0 0 * * * ?'; // Every hour
System.schedule('GitHub Sync Test', cron, new GitHubSyncScheduler());
```

---

## 8. Troubleshooting Common Issues

### Issue: Named Credential Test Fails

**Symptoms**: HTTP 401 Unauthorized when calling GitHub API

**Solutions**:
1. Verify GitHub token is still valid (check on GitHub.com)
2. Ensure token has `repo` scope enabled
3. Check External Credential Principal format: `token YOUR_TOKEN` (note the space)
4. Verify External Credential is assigned to Permission Set

---

### Issue: Deployment Fails with Field Errors

**Symptoms**: "Field does not exist" or "Invalid field" errors

**Solutions**:
1. Ensure you're deploying to the correct org
2. Check API version (should be 62.0)
3. Try deploying objects first, then classes
4. Use `--ignore-warnings` flag if warnings block deployment

---

### Issue: Test Classes Fail

**Symptoms**: Test coverage below 75%

**Solutions**:
1. Run tests individually to identify failures
2. Check for @isTest annotation on all test classes
3. Verify TestDataFactory class is deployed
4. Clear test data between runs

---

### Issue: Permission Denied Errors

**Symptoms**: Users can't access objects or classes

**Solutions**:
1. Assign `DevOps Compass Administrator` permission set to admin users
2. Assign `DevOps Compass User` permission set to read-only users
3. Check FLS (Field-Level Security) on custom objects
4. Verify External Credential Principal access

---

## 9. Next Steps After Story 0

Once the foundation is deployed and verified, the following stories will extend functionality:

- **Story 1**: GitHub Repository Synchronization
- **Story 2**: Pull Request Synchronization
- **Story 3**: DORA Metrics Calculation
- **Story 4**: Executive Dashboard
- **Story 5**: Deployment Tracking

**For now, Story 0 provides the platform architecture. No data will sync automatically yet.**

---

## 10. Architecture Summary

### What Was Built in Story 0

#### Custom Objects (9)
- Repository__c
- Pull_Request__c
- Contributor__c
- Work_Item__c
- Release__c
- Deployment__c
- Environment__c
- Sync_Job__c
- Metric_Snapshot__c

#### Custom Metadata Types (2)
- Application_Settings__mdt
- Repository_Config__mdt

#### Apex Classes (16)
- **Exceptions**: DevOpsCompassException, GitHubApiException
- **API Client**: GitHubApiClient
- **Services**: RepositoryService, PullRequestService
- **Selectors**: RepositorySelector, PullRequestSelector
- **Utilities**: DevOpsCompassUtils, DevOpsLogger
- **Async**: GitHubSyncQueueable, GitHubSyncScheduler
- **Tests**: TestDataFactory + 4 test classes

#### Permission Sets (2)
- DevOps Compass Administrator (Full Access)
- DevOps Compass User (Read Only)

#### Lightning App (1)
- DevOps Compass (with 9 custom tabs)

---

## 11. Contact & Support

For issues or questions:
- Refer to project documentation
- Check GitHub Issues (if using GitHub for project management)
- Contact DevOps Compass team

---

**Document Version**: 1.0  
**Last Updated**: July 17, 2026  
**Story**: Story 0 - Project Foundation
