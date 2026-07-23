# GitHub Sync Setup Guide

This guide explains how to set up automated and manual GitHub synchronization in DevOps Compass.

## Components Created

### Apex Classes
- **GitHubSyncOrchestrator** - Main orchestration class for syncing repositories
- **GitHubSyncScheduledJob** - Scheduled job for nightly sync at 2 AM
- Test classes for both

### Flow
- **GitHub Sync All Repositories** - Screen flow for manual sync with results display

### Quick Action
- **Sync All Repositories** - Button on Sync Job object to launch the flow

---

## Setup Instructions

### 1. Deploy the Code
Deploy all components to your org:
```bash
sf project deploy start --target-org YOUR_ORG_ALIAS
```

### 2. Schedule the Nightly Sync Job

Option A: **Via Developer Console** (Recommended)
1. Open Developer Console
2. Go to **Debug** → **Open Execute Anonymous Window**
3. Paste and execute:
```apex
GitHubSyncScheduledJob.scheduleNightlySync();
```

Option B: **Via SF CLI**
```bash
sf apex run --target-org YOUR_ORG_ALIAS <<EOF
GitHubSyncScheduledJob.scheduleNightlySync();
EOF
```

This schedules the job to run daily at 2:00 AM.

### 3. Add the Sync Button to the Sync Jobs List View

1. Go to **Setup** → **Object Manager** → **Sync Job**
2. Click **Buttons, Links, and Actions**
3. Click **New Action**
4. Select the **Sync All Repositories** action
5. Go to **List View Button Layout**
6. Drag **Sync All Repositories** to the button bar
7. Save

Alternatively, add it to the page layout:
1. Go to **Lightning App Builder**
2. Edit the Sync Jobs list view page
3. Add the **Quick Action** component
4. Select **Sync All Repositories**
5. Save and activate

---

## Usage

### Manual Sync

1. Navigate to the **Sync Jobs** tab
2. Click **Sync All Repositories** button
3. Click **Next** on the intro screen
4. Wait for sync to complete (may take 30-60 seconds)
5. Review results:
   - Repositories synced
   - Pull requests synced
   - Contributors synced
   - Any errors

### Nightly Sync

- Runs automatically at 2:00 AM daily
- Syncs all active repositories
- Sends email to all DevOps Compass Administrators with:
  - Summary of synced records
  - Any errors encountered
- Creates a Sync_Job__c record for tracking
- Auto-deletes Sync_Job__c records older than 10 days

### Verify Scheduled Job

To verify the nightly sync is scheduled:
1. Go to **Setup** → **Apex Jobs** → **Scheduled Jobs**
2. Look for **DevOps Compass Nightly Sync**
3. Verify it's set to run at 2:00 AM daily

---

## Sync Job Records

Every sync (manual or scheduled) creates a **Sync_Job__c** record with:
- **Job Type**: Full Sync
- **Status**: In Progress → Completed / Completed with Errors / Failed
- **Start Time** and **End Time**
- **Records Processed**: Total count
- **Error Count** and **Error Log**

Records are automatically deleted after 10 days to keep data lean.

---

## Email Notifications

Admins receive simple text emails after each nightly sync:

**Subject**: 
- Success: "DevOps Compass: Nightly Sync Completed Successfully"
- Errors: "DevOps Compass: Nightly Sync Completed with Errors"

**Body**:
```
DevOps Compass Nightly Sync Results
=====================================

Repositories Synced: 1
Pull Requests Synced: 47
Contributors Synced: 12

No errors.

Sync completed at: 2026-07-23 02:00:15
```

If errors occur, they are included in the email body.

---

## Troubleshooting

### Sync Button Not Visible
- Ensure you have the **DevOps Compass Administrator** permission set
- Verify the button is added to the list view layout

### No Email Received
- Check spam/junk folder
- Verify your user has the **DevOps Compass Administrator** permission set
- Check **Setup** → **Email Logs** for delivery issues

### Sync Fails
- Check the **Sync_Job__c** record for error details
- Verify **GitHub_API** Named Credential is configured
- Check API rate limits (GitHub: 5,000 requests/hour for authenticated)
- Review **Debug Logs** in Setup

### Scheduled Job Not Running
- Verify job is active in **Setup** → **Scheduled Jobs**
- Re-run `GitHubSyncScheduledJob.scheduleNightlySync()` to reschedule

---

## API Considerations

- GitHub API rate limit: 5,000 requests/hour
- Each repository sync uses ~3 API calls (repo, PRs, contributors)
- Default: 100 PRs and 100 contributors per repository
- For large repos with 1000+ PRs, consider pagination limits

---

## Future Enhancements

- Incremental sync (only changed data)
- Webhook-based real-time sync
- Configurable sync schedule
- Per-repository sync controls
- Slack notifications
