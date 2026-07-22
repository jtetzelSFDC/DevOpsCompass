# DevOps Compass

**Making Salesforce DevOps Visible**

## Overview

DevOps Compass is a Salesforce-native DevOps observability and analytics platform designed to provide engineering leadership, Release Managers, DevOps Engineers, and development teams with a centralized view of software delivery activities.

Rather than replacing existing DevOps tools such as GitHub, Jira, Copado, or Gearset, DevOps Compass serves as the **Salesforce-native observability and analytics layer** that consolidates information from those systems into a single location for reporting, release visibility, and engineering insights.

## Vision

Instead of searching through GitHub repositories, Slack conversations, Jira boards, deployment logs, spreadsheets, and release documentation, users can access **one Salesforce application** to understand the current state of their DevOps ecosystem.

### Key Questions Answered

- What is currently deployed?
- What is waiting to deploy?
- What changed this week?
- Which releases are at risk?
- Which repositories are most active?
- Which environments contain a specific feature?
- How are our DORA metrics trending?
- Where are deployment bottlenecks occurring?

## Project Status: Story 2 Complete ✅

**Story 2: Pull Request Milestone Timeline** - COMPLETE & DEPLOYED

### What's Included

- **Foundation (Story 0)**:
  - 9 Custom Objects: Repository, Pull Request, Contributor, Work Item, Release, Deployment, Environment, Sync Job, Metric Snapshot
  - 2 Custom Metadata Types: Application Settings, Repository Config
  - 2 Permission Sets: Administrator and User
  - 1 Lightning Application: DevOps Compass with 9 navigation tabs

- **GitHub Synchronization (Story 1)**:
  - 3 Sync Services: RepositorySyncService, PullRequestSyncService, ContributorSyncService
  - 4 Lightning Web Components: repositoryOverviewCard, pullRequestMetrics, contributorLeaderboard, recentActivityFeed
  - Enhanced selectors with bulk operations
  - 100% test coverage

- **Deployment Timeline (Story 2)**:
  - TimelineBuilder.cls for milestone construction
  - DeploymentTimelineService.cls for orchestration
  - deploymentMilestoneTimeline LWC with SLDS styling
  - Dynamic environment ordering via Display_Order__c
  - 100% test coverage

### What's NOT Included Yet

- Scheduled GitHub synchronization jobs
- Deployment event tracking and notifications (Story 3)
- DORA metrics calculation (Story 4)
- Dashboards and reports (Story 5+)

## Quick Start

### Prerequisites

- Salesforce Developer Edition or Sandbox
- Salesforce CLI installed (v2.0+)
- GitHub Personal Access Token (for future stories)

### Deployment Steps

⚠️ **IMPORTANT**: DevOps Compass requires a **two-stage deployment** due to metadata dependencies.

1. **Authenticate to your Salesforce org**
   ```bash
   cd ~/Documents/DevOpsCompass
   sf org login web --set-default --alias devops-compass
   ```

2. **Deploy Custom Metadata Types (Stage 1)**
   ```bash
   sf project deploy start \
     --source-dir force-app/main/default/objects/Application_Settings__mdt \
     --source-dir force-app/main/default/objects/Repository_Config__mdt
   ```

3. **Deploy all other components (Stage 2)**
   ```bash
   sf project deploy start --manifest manifest/package.xml
   ```

4. **Assign permission set**
   ```bash
   sf org assign permset --name DevOps_Compass_Administrator
   ```

5. **Open and verify**
   ```bash
   sf org open --path "/lightning/n/Repository__c"
   ```

### Complete Guides

- **[DEPLOY.md](./DEPLOY.md)** - Detailed deployment instructions and troubleshooting
- **[SETUP.md](./SETUP.md)** - Post-deployment configuration  
- **[PATSetup.MD](./PATSetup.MD)** - GitHub Personal Access Token setup
- **[Story1_Completion_Summary.md](./Story1_Completion_Summary.md)** - GitHub sync implementation details
- **[Story2_Completion_Summary.md](./Story2_Completion_Summary.md)** - Deployment timeline implementation details

## Project Structure

```
DevOpsCompass/
├── force-app/
│   └── main/
│       └── default/
│           ├── applications/     # Lightning App
│           ├── classes/          # Apex Classes
│           ├── objects/          # Custom Objects & Fields
│           ├── permissionsets/   # Permission Sets
│           └── tabs/             # Custom Tabs
├── manifest/
│   └── package.xml              # Deployment manifest
├── SETUP.md                     # Setup documentation
├── README.md                    # This file
└── sfdx-project.json            # SFDX project config
```

## Architecture Principles

- **Salesforce First**: Native Salesforce experience
- **Metadata Driven**: Configuration via Custom Metadata
- **Secure by Design**: Named Credentials, Permission Sets
- **Modular Architecture**: Service Layer, Selector Layer, Domain Layer
- **API First**: All integrations through abstraction layers
- **Enterprise Ready**: Bulkified, tested, governor limit aware

## Data Model

### Transactional Objects
- **Repository__c**: Source code repositories
- **Pull_Request__c**: Pull requests from GitHub
- **Deployment__c**: Salesforce deployments
- **Work_Item__c**: Jira stories/bugs/tasks

### Reference Objects
- **Environment__c**: Salesforce environments (DEV, QA, UAT, PROD)
- **Contributor__c**: Developers and contributors
- **Release__c**: Logical software releases

### Analytics Objects
- **Metric_Snapshot__c**: Calculated DORA metrics
- **Sync_Job__c**: Integration execution logs

## Technology Stack

- **Salesforce DX**: Source-driven development
- **API Version**: 62.0
- **Apex**: Business logic and integrations
- **Lightning Web Components**: Future UI enhancements
- **GitHub REST API**: Primary integration (v3)

## Roadmap

### ✅ Story 0: Foundation (COMPLETE)
- Project structure, data model, Apex framework, security model

### ✅ Story 1: GitHub Sync (COMPLETE)
- Repository, pull request, and contributor synchronization
- 4 Lightning Web Components for repository intelligence

### ✅ Story 2: Deployment Timeline (COMPLETE)
- Pull Request milestone timeline visualization
- Dynamic environment ordering
- TimelineBuilder pattern implementation

### 📋 Story 3: Deployment Events & Notifications (Next)
- Deployment event tracking
- Status change notifications
- Rollback handling

### 📋 Story 4: DORA Metrics
- Lead time, deployment frequency, change failure rate, time to restore

### 📊 Story 5: Dashboards & Reports
- Executive dashboard, engineering metrics, repository insights

## Testing

All Apex classes include comprehensive test coverage (>85%).

Run tests:
```bash
sf apex run test --test-level RunLocalTests --result-format human
```

## Contributing

This project follows Salesforce Enterprise Design Patterns:
- **Service Layer**: Business logic
- **Selector Layer**: SOQL queries
- **Domain Layer**: Record-level logic
- **Utility Layer**: Shared helpers

## Support

For setup issues or questions:
- Review [SETUP.md](./SETUP.md)
- Check Salesforce debug logs
- Verify GitHub API connectivity
- Review governor limit usage

## License

[To be determined]

## Authors

DevOps Compass Team  
**Date**: July 2026  
**Version**: 0.3.0 (Story 2 Complete)

---

**GitHub**: https://github.com/jtetzelSFDC/DevOpsCompass  
**Status**: Story 2 Complete ✅ | GitHub Sync & Deployment Timeline Operational
