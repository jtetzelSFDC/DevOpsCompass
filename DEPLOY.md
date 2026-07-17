# Quick Deployment Guide - DevOps Compass

## Ready to Deploy

All Story 0 foundation components are complete and ready for deployment to your Trailhead sandbox.

---

## Option 1: Deploy via Salesforce CLI (Recommended)

### Step 1: Authenticate to your Trailhead sandbox

```bash
cd ~/Documents/DevOpsCompass
sf org login web --set-default --alias devops-compass
```

This will open your browser. Log in with your Trailhead playground credentials:
- **URL**: https://brave-hawk-86tr29-dev-ed.trailblaze.lightning.force.com/

### Step 2: Deploy all metadata

```bash
sf project deploy start --manifest manifest/package.xml
```

### Step 3: Monitor deployment

```bash
sf project deploy report
```

### Step 4: Verify deployment success

```bash
sf org open --target-org devops-compass
```

Navigate to **Setup** → **Apex Classes** to verify classes are deployed.

---

## Option 2: Deploy via VS Code

1. Open the `DevOpsCompass` folder in VS Code
2. Open Command Palette (Cmd+Shift+P)
3. Type: `SFDX: Authorize an Org`
4. Select **Project Default**
5. Log in to your Trailhead sandbox
6. Right-click on `manifest/package.xml`
7. Select `SFDX: Deploy Source in Manifest to Org`

---

## Option 3: Deploy via Workbench

1. Create a ZIP file:
   ```bash
   cd ~/Documents/DevOpsCompass
   zip -r devops-compass.zip force-app/
   ```

2. Go to https://workbench.developerforce.com
3. Log in with Trailhead credentials
4. Navigate to **migration** → **Deploy**
5. Upload `devops-compass.zip`
6. Check **Single Package**
7. Check **Rollback On Error**
8. Click **Deploy**

---

## Post-Deployment Steps

### 1. Assign Permission Set

```bash
# Get your username
sf org display --target-org devops-compass

# Assign permission set
sf org assign permset --name DevOps_Compass_Administrator
```

### 2. Verify the App

```bash
sf org open
```

- Click App Launcher (waffle icon)
- Search for "DevOps Compass"
- Verify all tabs appear

### 3. Configure Custom Metadata

See [SETUP.md](./SETUP.md) Section 4 for:
- Application Settings configuration
- Repository Config setup
- GitHub authentication

---

## Troubleshooting

### Authentication Issues

If `sf org login web` fails:
```bash
# Try specifying the instance URL explicitly
sf org login web --instance-url https://login.salesforce.com

# Or use device flow
sf org login device --set-default --alias devops-compass
```

### Deployment Failures

```bash
# Check for errors
sf project deploy report --verbose

# Validate before deploying
sf project deploy validate --manifest manifest/package.xml
```

### Test Failures

```bash
# Run all tests
sf apex run test --test-level RunLocalTests --result-format human
```

---

## What Gets Deployed

- ✅ 9 Custom Objects with all fields
- ✅ 2 Custom Metadata Types
- ✅ 16 Apex Classes (including 5 test classes)
- ✅ 2 Permission Sets
- ✅ 1 Lightning Application
- ✅ 9 Custom Tabs

**Total Components**: ~100 metadata components

---

## Next Steps After Deployment

1. Follow [SETUP.md](./SETUP.md) for complete configuration
2. Create GitHub Personal Access Token
3. Configure Named Credential
4. Set up External Credential
5. Configure Application Settings
6. Add Repository Configurations

---

## Quick Verification Checklist

After deployment, verify:

- [ ] Apex classes appear in Setup → Apex Classes
- [ ] Custom objects appear in Setup → Object Manager
- [ ] DevOps Compass app appears in App Launcher
- [ ] Permission Sets exist (Setup → Permission Sets)
- [ ] All 9 tabs are visible in the app
- [ ] No compilation errors in debug logs

---

## Estimated Deployment Time

- **Metadata Deployment**: 2-5 minutes
- **Test Execution**: 1-2 minutes
- **Total**: ~5-7 minutes

---

## Need Help?

- Review [SETUP.md](./SETUP.md) for detailed instructions
- Check [ARCHITECTURE.md](./ARCHITECTURE.md) for technical details
- Review Salesforce debug logs for errors
- Verify API version compatibility (62.0)

---

**Ready to deploy?** Start with Option 1 above!
