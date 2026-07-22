# DevOps Compass

**Making Salesforce DevOps Visible**

## Overview

DevOps Compass is a Salesforce-native DevOps observability and analytics platform designed to provide engineering leadership, Release Managers, DevOps Engineers, and development teams with a centralized view of software delivery activities.

Rather than replacing existing DevOps tools such as GitHub, Jira, Copado, or Gearset, DevOps Compass serves as the **Salesforce-native observability and analytics layer** that consolidates information from those systems into a single location for reporting, release visibility, and engineering insights.

## Project Status: Story 2 Complete ✅

**Story 2: Pull Request Milestone Timeline** - COMPLETE & DEPLOYED

Story 2 adds deployment pipeline visualization with a reusable Lightning Web Component that tracks PR lifecycle progression.

### What's Included

- **Foundation (Story 0)**:
  - 9 Custom Objects: Repository, Pull Request, Contributor, Work Item, Release, Deployment, Environment, Sync Job, Metric Snapshot
  - 2 Custom Metadata Types: Application Settings, Repository Config
  - 2 Permission Sets: Administrator and User
  - 1 Lightning Application: DevOps Compass with 9 navigation tabs

- **GitHub Synchronization (Story 1)**:
  - **3 Sync Services**: RepositorySyncService, PullRequestSyncService, ContributorSyncService
  - **3 Service Classes**: PullRequestService, ContributorService, ActivityService
  - **2 Enhanced Selectors**: ContributorSelector, updated RepositorySelector & PullRequestSelector with bulk methods
  - **4 Lightning Web Components**: repositoryOverviewCard, pullRequestMetrics, contributorLeaderboard, recentActivityFeed
  - **Master-Detail Relationship**: Contributor to Repository with ControlledByParent sharing
  - **External ID Fields**: For upsert operations across all synced objects
  - **22 Apex Classes Total**: >85% test coverage

- **Deployment Timeline (Story 2)**:
  - **TimelineBuilder.cls**: Milestone construction logic with fluent API
  - **DeploymentTimelineService.cls**: Orchestration layer with 3 SOQL queries
  - **deploymentMilestoneTimeline LWC**: Vertical timeline component with SLDS styling
  - **Display_Order__c field**: Dynamic environment ordering on Environment__c
  - **100% test coverage**: TimelineBuilderTest and DeploymentTimelineServiceTest
  - **Dynamic milestone tracking**: Created, Merged, and environment deployments
  - **Current milestone highlighting**: Highest completed milestone logic

### What's NOT Included Yet

- Scheduled GitHub synchronization jobs (Story 1 continuation)
- Deployment event tracking and notifications (Story 3)
- DORA metrics calculation (Story 4)
- Dashboards and reports (Story 5+)

## Quick Start

### Prerequisites

- Salesforce Developer Edition or Sandbox
- Salesforce CLI installed (v2.0+)
- GitHub Personal Access Token (for GitHub sync - see [PATSetup.MD](./documentation/PATSetup.MD))

### Deployment (Two-Stage Required)

⚠️ **IMPORTANT**: DevOps Compass requires a **two-stage deployment** due to metadata dependencies.

```bash
cd ~/Documents/DevOpsCompass

# 1. Authenticate
sf org login web --set-default --alias devops-compass

# 2. Stage 1: Deploy Custom Metadata Types
sf project deploy start \
  --source-dir force-app/main/default/objects/Application_Settings__mdt \
  --source-dir force-app/main/default/objects/Repository_Config__mdt

# 3. Stage 2: Deploy all other components
sf project deploy start --manifest manifest/package.xml

# 4. Assign permission set
sf org assign permset --name DevOps_Compass_Administrator

# 5. Open and verify
sf org open --path "/lightning/n/Repository__c"
```

### Testing GitHub Sync (Story 1)

After deploying and setting up your GitHub Personal Access Token (see [PATSetup.MD](./documentation/PATSetup.MD)), test the sync:

```apex
// Execute Anonymous Apex
RepositorySyncService.syncRepository('jtetzelSFDC', 'DevOpsCompass');
```

Navigate to the Repository record page and add the Story 1 Lightning Web Components to see your synced data.

### Testing Deployment Timeline (Story 2)

1. Create Environment records with Display_Order__c values (QA=10, UAT=20, Production=30)
2. Create Deployment records linked to Pull Requests
3. Add the `deploymentMilestoneTimeline` component to Pull Request record pages
4. Verify milestone progression from Created → Merged → Environment deployments

## Documentation

All documentation is located in the **[`documentation/`](./documentation/)** folder:

### Core Guides
| Document | Purpose |
|----------|---------|
| **[DEPLOY.md](./documentation/DEPLOY.md)** | Complete two-stage deployment guide ⭐ |
| **[SETUP.md](./documentation/SETUP.md)** | Post-deployment configuration |
| **[ARCHITECTURE.md](./documentation/ARCHITECTURE.md)** | Technical architecture details |
| **[PATSetup.MD](./documentation/PATSetup.MD)** | GitHub PAT + Salesforce connection setup ⭐ |

### Story Summaries
| Document | Purpose |
|----------|---------|
| **[STORY_0_SUMMARY.md](./documentation/STORY_0_SUMMARY.md)** | Foundation deliverables |
| **[Story1_Completion_Summary.md](./documentation/Story1_Completion_Summary.md)** | GitHub sync implementation |
| **[Story2_Completion_Summary.md](./documentation/Story2_Completion_Summary.md)** | Deployment timeline implementation ⭐ |

### Reference
| Document | Purpose |
|----------|---------|
| **[QUICK_REFERENCE.md](./documentation/QUICK_REFERENCE.md)** | Command cheat sheet |
| **[DEPLOY_MANUAL.md](./documentation/DEPLOY_MANUAL.md)** | Manual Workbench deployment fallback |

## Project Structure

```
DevOpsCompass/
├── documentation/          # All documentation files
├── force-app/
│   └── main/
│       └── default/
│           ├── applications/     # Lightning App
│           ├── classes/          # 28 Apex Classes (Story 0-2)
│           ├── lwc/              # 5 Lightning Web Components (Story 1-2)
│           ├── objects/          # 9 Custom Objects + 2 Metadata Types
│           ├── permissionsets/   # 2 Permission Sets
│           └── tabs/             # 9 Custom Tabs
├── testScripts/           # Testing scripts and guides
├── manifest/
│   └── package.xml              # Deployment manifest
└── sfdx-project.json            # SFDX project config
```

## Architecture Principles

- **Salesforce First**: Native Salesforce experience
- **Metadata Driven**: Configuration via Custom Metadata
- **Secure by Design**: Named Credentials, Permission Sets
- **Modular Architecture**: Service Layer, Selector Layer, Domain Layer
- **API First**: All integrations through abstraction layers
- **Enterprise Ready**: Bulkified, tested, governor limit aware

## Roadmap

### ✅ Story 0: Foundation (COMPLETE)
- Project structure
- Data model (9 objects, 100+ fields)
- Apex framework (16 classes)
- Security model
- **Status**: Deployed & verified

### ✅ Story 1: GitHub Sync (COMPLETE)
- Repository synchronization ✅
- Pull request sync ✅
- Contributor sync ✅
- Lightning Web Components ✅
- Scheduled jobs (Future)
- **Status**: Deployed & tested

### ✅ Story 2: Deployment Timeline (COMPLETE)
- Pull Request milestone timeline ✅
- Dynamic environment ordering ✅
- TimelineBuilder pattern ✅
- SLDS-native component ✅
- 100% test coverage ✅
- **Status**: Deployed & merged to main

### 📋 Story 3: Deployment Events & Notifications
- Deployment event tracking
- Status change notifications
- Rollback handling
- Deployment logs

### 📋 Story 4: DORA Metrics
- Lead time calculation
- Deployment frequency
- Change failure rate
- Time to restore

### 📊 Story 5: Dashboards & Reports
- Executive dashboard
- Engineering metrics
- Repository insights
- Custom reports

## Technology Stack

- **Salesforce DX**: Source-driven development
- **API Version**: 62.0
- **Apex**: Business logic and integrations
- **Lightning**: Native UI framework
- **GitHub REST API**: Primary integration (v3)

## Testing

All Apex classes include comprehensive test coverage (>85%).

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
- Review **[documentation/](./documentation/)** folder
- Check **[DEPLOY.md](./documentation/DEPLOY.md)** for deployment help
- Check story completion summaries for implementation details
- Review Salesforce debug logs
- Verify GitHub API connectivity

## License

[To be determined]

## Authors

DevOps Compass Team  
**Version**: 0.3.0 (Story 2 Complete)  
**Date**: July 2026

---

**GitHub**: https://github.com/jtetzelSFDC/DevOpsCompass  
**Status**: Story 2 Complete ✅ | GitHub Sync & Deployment Timeline Operational
