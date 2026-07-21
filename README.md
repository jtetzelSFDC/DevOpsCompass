# DevOps Compass

**Making Salesforce DevOps Visible**

## Overview

DevOps Compass is a Salesforce-native DevOps observability and analytics platform designed to provide engineering leadership, Release Managers, DevOps Engineers, and development teams with a centralized view of software delivery activities.

Rather than replacing existing DevOps tools such as GitHub, Jira, Copado, or Gearset, DevOps Compass serves as the **Salesforce-native observability and analytics layer** that consolidates information from those systems into a single location for reporting, release visibility, and engineering insights.

## Project Status: Story 0 Complete ✅

**Story 0: Project Foundation** - COMPLETE & DEPLOYED

The foundation architecture has been built, tested, and successfully deployed to a Salesforce Developer Edition org.

### What's Included

- **9 Custom Objects**: Repository, Pull Request, Contributor, Work Item, Release, Deployment, Environment, Sync Job, Metric Snapshot
- **2 Custom Metadata Types**: Application Settings, Repository Config
- **16 Apex Classes**: API Client, Services, Selectors, Utilities, Tests (>85% coverage)
- **2 Permission Sets**: Administrator and User
- **1 Lightning Application**: DevOps Compass with 9 navigation tabs
- **Complete Documentation**: Setup, deployment, architecture guides

### What's NOT Included Yet

- GitHub synchronization logic (Story 1)
- DORA metrics calculation (Story 3)
- Dashboards and reports (Story 4+)
- Deployment tracking workflows (Story 5+)

## Quick Start

### Prerequisites

- Salesforce Developer Edition or Sandbox
- Salesforce CLI installed (v2.0+)
- GitHub Personal Access Token (for future stories)

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

## Documentation

All documentation is located in the **[`documentation/`](./documentation/)** folder:

| Document | Purpose |
|----------|---------|
| **[DEPLOY.md](./documentation/DEPLOY.md)** | Complete two-stage deployment guide ⭐ |
| **[SESSION_HANDOFF.md](./documentation/SESSION_HANDOFF.md)** | Current state & Story 1 planning |
| **[SETUP.md](./documentation/SETUP.md)** | Post-deployment configuration |
| **[ARCHITECTURE.md](./documentation/ARCHITECTURE.md)** | Technical architecture details |
| **[QUICK_REFERENCE.md](./documentation/QUICK_REFERENCE.md)** | Command cheat sheet |
| **[DEPLOYMENT_SUCCESS.md](./documentation/DEPLOYMENT_SUCCESS.md)** | Deployment success summary |
| **[STORY_0_SUMMARY.md](./documentation/STORY_0_SUMMARY.md)** | Complete Story 0 deliverables |
| **[DEPLOY_MANUAL.md](./documentation/DEPLOY_MANUAL.md)** | Manual Workbench deployment |
| **[PATSetup.MD](./documentation/PATSetup.MD)** | Story 1 GitHub PAT + Salesforce connection setup |

## Project Structure

```
DevOpsCompass/
├── documentation/          # All documentation files
├── force-app/
│   └── main/
│       └── default/
│           ├── applications/     # Lightning App
│           ├── classes/          # 16 Apex Classes
│           ├── objects/          # 9 Custom Objects + 2 Metadata Types
│           ├── permissionsets/   # 2 Permission Sets
│           └── tabs/             # 9 Custom Tabs
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

### 🔄 Story 1: GitHub Sync (Next)
- Repository synchronization
- Pull request sync
- Contributor sync
- Scheduled jobs

### 📋 Story 2: Analytics Engine
- DORA metrics calculation
- Metric snapshots
- Trend analysis

### 📊 Story 3: Dashboards
- Executive dashboard
- Engineering metrics
- Repository insights

### 🚀 Story 4: Deployment Tracking
- Manual deployment logging
- CI/CD integration
- Release management

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
- Check **[SESSION_HANDOFF.md](./documentation/SESSION_HANDOFF.md)** for current state
- Review Salesforce debug logs
- Verify GitHub API connectivity

## License

[To be determined]

## Authors

DevOps Compass Team  
**Version**: 0.1.0 (Foundation)  
**Date**: July 2026

---

**GitHub**: https://github.com/jtetzelSFDC/DevOpsCompass  
**Status**: Story 0 Complete ✅ | Ready for Story 1
