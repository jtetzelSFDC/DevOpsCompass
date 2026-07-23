# Manual Setup Steps for Feature 2.1: Auto Sync

✅ **Deployment Status**: Successfully deployed to `devops-compass` sandbox

---

## 🎯 Required Manual Setup Steps

You need to complete **1 manual step** to fully activate the auto sync feature:

### Step 1: Schedule the Nightly Sync Job (REQUIRED)

**Option A: Via Developer Console (Recommended)**

1. In your sandbox, open **Developer Console**
2. Click **Debug** → **Open Execute Anonymous Window**
3. Paste this code:
   ```apex
   GitHubSyncScheduledJob.scheduleNightlySync();
   ```
4. Click **Execute**
5. You should see "Success" in the results

**Option B: Via SF CLI**

```bash
sf apex run --target-org devops-compass <<EOF
GitHubSyncScheduledJob.scheduleNightlySync();
EOF
```

**Verify it worked:**
1. Go to **Setup** → Type "Apex Jobs" in Quick Find
2. Click **Scheduled Jobs**
3. Look for **"DevOps Compass Nightly Sync"**
4. Verify:
   - Status: **Scheduled**
   - Next Run Time: **2:00 AM tomorrow**
   - Frequency: **Daily**

---

### Step 2: Test the Manual Sync (RECOMMENDED)

Let's test that everything works!

**Prerequisites:**
- You have at least one Repository record with `Active__c = true`
- Your GitHub_API Named Credential is configured with a valid token

**Steps:**

1. In your DevOps Compass app, click the **GitHub Sync** tab (second tab after Home)
2. You'll see the sync component with a big blue **"Sync All Repositories"** button
3. Click the button
4. Wait 30-60 seconds (you'll see a loading spinner)
5. Review the results displayed inline:
   - ✅ Repositories Synced: [count]
   - ✅ Pull Requests Synced: [count]
   - ✅ Contributors Synced: [count]
   - ✅ Success message (or error details if something failed)

**Verify sync worked:**
1. Click the **Sync Jobs** tab
2. You should see a new **Sync_Job__c** record at the top:
   - Job Type: **Full Sync**
   - Status: **Completed** (or "Completed with Errors")
   - Records Processed: [total count]
   - End Time: Just now

---

## 📧 Email Notification Setup (Optional Verification)

The nightly sync will send emails to all users with the **DevOps Compass Administrator** permission set.

**To verify you'll receive emails:**

1. Go to **Setup** → **Users** → **Permission Sets**
2. Click **DevOps Compass Administrator**
3. Click **Manage Assignments**
4. Verify your user is in the list
5. Check that your user record has a valid email address

**Sample Email You'll Receive:**

```
Subject: DevOps Compass: Nightly Sync Completed Successfully

DevOps Compass Nightly Sync Results
=====================================

Repositories Synced: 1
Pull Requests Synced: 47
Contributors Synced: 12

No errors.

Sync completed at: 2026-07-23 02:00:15
```

---

## 🧪 Optional: Test the Scheduled Job Manually

If you don't want to wait until 2 AM tomorrow, you can manually trigger the scheduled job:

**Via Developer Console:**

```apex
// Create an instance and execute
GitHubSyncScheduledJob job = new GitHubSyncScheduledJob();
job.execute(null);
```

This will:
- Run a full sync
- Send you an email
- Clean up old Sync_Job__c records (>10 days)

**Note:** This runs synchronously, so it may take 30-60 seconds to complete.

---

## ✅ Verification Checklist

Use this checklist to confirm everything is set up correctly:

- [ ] Nightly sync job is scheduled (visible in Setup → Scheduled Jobs)
- [ ] Scheduled job shows "DevOps Compass Nightly Sync" name
- [ ] Next run time is 2:00 AM
- [ ] **GitHub Sync** tab appears in DevOps Compass app (second tab)
- [ ] Sync component with blue button is visible on GitHub Sync tab
- [ ] Manual sync button works when clicked
- [ ] Manual sync creates a Sync_Job__c record
- [ ] Your user has DevOps Compass Administrator permission set
- [ ] Your user has a valid email address
- [ ] At least one Repository__c record has Active__c = true

---

## 🐛 Troubleshooting

### GitHub Sync Tab Not Visible
**Problem:** Can't see "GitHub Sync" tab in DevOps Compass app

**Solution:**
1. Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)
2. Check that you have the DevOps_Compass_Administrator permission set
3. Verify the tab deployed successfully (check deployment logs)
4. Try logging out and back in

---

### Scheduled Job Not Listed
**Problem:** Don't see "DevOps Compass Nightly Sync" in Scheduled Jobs

**Solution:**
1. Re-run the schedule command from Step 1
2. If you see an error about an existing job, run this to remove it first:
   ```apex
   List<CronTrigger> jobs = [SELECT Id FROM CronTrigger 
                             WHERE CronJobDetail.Name = 'DevOps Compass Nightly Sync'];
   for (CronTrigger job : jobs) {
       System.abortJob(job.Id);
   }
   ```
3. Then re-run the schedule command

---

### Sync Button Errors When Clicked
**Problem:** Error when clicking "Sync All Repositories"

**Possible Causes:**
1. **No Active Repositories**: Make sure at least one Repository__c has Active__c = true
2. **GitHub Credential Not Configured**: Verify GitHub_API Named Credential exists and has a valid PAT
3. **API Rate Limit**: GitHub rate limit exceeded (5,000/hour)

**Check the Error:**
- Look at the error message in the Flow results screen
- Check Debug Logs: Setup → Debug Logs → Generate Logs for your user
- Review the Sync_Job__c record's Error_Log__c field

---

### No Email Received After Manual Test
**Problem:** Manually ran the scheduled job but didn't get an email

**Solutions:**
1. Check your **Junk/Spam** folder
2. Verify your user has DevOps_Compass_Administrator permission set
3. Check **Setup** → **Email Logs** to see if email was sent
4. Verify your User record has a valid email address
5. Note: Manual sync (via button) does NOT send emails - only the scheduled job does

---

## 📊 Expected Behavior

### Manual Sync (Button)
- Triggered by clicking button on Sync Jobs tab
- Shows progress screen
- Creates Sync_Job__c record
- **Does NOT send email**
- Available anytime to admins

### Nightly Scheduled Sync
- Runs automatically at 2:00 AM daily
- Creates Sync_Job__c record
- **Sends email to all admins**
- Deletes Sync_Job__c records older than 10 days
- No user interaction required

---

## 📖 Additional Resources

- **Full Documentation**: `/documentation/Story2.1_Auto_Sync_Summary.md`
- **Setup Guide**: `/SYNC_SETUP.md`
- **Quick Reference**: `/.test-data/feature-2.1-summary.txt`

---

## 🎉 You're Done!

Once you complete the 3 required setup steps above, your auto sync feature is fully operational!

**What happens next:**
- Every night at 2 AM, all active repositories will sync automatically
- You'll receive an email summary each morning
- Sync_Job__c records track all sync history
- Records auto-delete after 10 days to keep data lean

**Questions or Issues?**
Review the troubleshooting section above or check the full documentation.

---

**Last Updated**: July 23, 2026  
**Deployed To**: devops-compass sandbox  
**Status**: ✅ Deployment Complete - Manual Setup Required
