# Manual Deployment via Workbench

Since CLI authentication is proving difficult with the Trailhead Playground, here's how to deploy manually using Workbench (which uses your existing browser session):

## Step 1: Create Deployment ZIP

```bash
cd ~/Documents/DevOpsCompass
zip -r devops-compass-deploy.zip manifest/ force-app/
```

## Step 2: Deploy via Workbench

1. **Open Workbench**: https://workbench.developerforce.com/

2. **Login**:
   - Select Environment: **Production/Developer Edition**
   - Click **Login with Salesforce**
   - You should be automatically logged in (already authenticated in browser)

3. **Deploy**:
   - Go to **migration** → **Deploy**
   - Click **Choose File** → select `devops-compass-deploy.zip`
   - Check these options:
     - ✅ **Single Package**
     - ✅ **Rollback On Error**
     - ✅ **Run All Tests** (optional, will take longer)
   - Click **Next**
   - Click **Deploy**

4. **Monitor**:
   - Wait for deployment (typically 2-5 minutes)
   - Watch the progress bar
   - Check for any errors

## Step 3: Verify Deployment

Once complete, go back to your Salesforce org and verify:

1. **Check Objects**: Setup → Object Manager → Search "Repository"
2. **Check Apex**: Setup → Apex Classes → Look for "GitHubApiClient"
3. **Check App**: App Launcher → "DevOps Compass"

## Step 4: Assign Permission Set

In your Salesforce org:
1. Setup → Users → Users
2. Click your name
3. Scroll to **Permission Set Assignments**
4. Click **Edit Assignments**
5. Add: **DevOps Compass Administrator**
6. Click **Save**

## Alternative: Deploy Smaller Packages

If the full ZIP fails, deploy in stages:

### Stage 1: Objects
```bash
cd ~/Documents/DevOpsCompass
zip -r objects-only.zip force-app/main/default/objects/ manifest/
```

### Stage 2: Apex Classes
```bash
zip -r apex-only.zip force-app/main/default/classes/ manifest/
```

### Stage 3: UI Components
```bash
zip -r ui-only.zip force-app/main/default/applications/ force-app/main/default/tabs/ force-app/main/default/permissionsets/ manifest/
```

Deploy each ZIP separately through Workbench.

---

## Troubleshooting

### "Invalid File" Error
- Make sure you're including the manifest/ folder
- ZIP should contain: manifest/package.xml and force-app/ directory

### "Component Failures"
- Note which components failed
- Try deploying in stages (objects first, then Apex, then UI)

### "Test Failures"
- Uncheck "Run All Tests" option
- Deploy without running tests
- Run tests manually later: Setup → Apex Test Execution

---

**Need the ZIP file?** Run:
```bash
cd ~/Documents/DevOpsCompass && zip -r ~/Desktop/devops-compass-deploy.zip manifest/ force-app/
```

The ZIP will be on your Desktop ready to upload!
