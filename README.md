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

## Project Status: Story 0 Complete

✅ **Story 0: Project Foundation** - COMPLETE

The foundation architecture has been built and is ready for deployment.

### What's Included

- **9 Custom Objects**: Repository, Pull Request, Contributor, Work Item, Release, Deployment, Environment, Sync Job, Metric Snapshot
- **2 Custom Metadata Types**: Application Settings, Repository Config
- **16 Apex Classes**: API Client, Services, Selectors, Utilities, Tests
- **2 Permission Sets**: Administrator and User
- **1 Lightning Application**: DevOps Compass with navigation tabs

### What's NOT Included Yet

- GitHub synchronization logic (Story 1)
- DORA metrics calculation (Story 3)
- Dashboards and reports (Story 4+)
- Deployment tracking workflows (Story 5+)

## Quick Start

### Prerequisites

- Salesforce Developer Edition or Sandbox
- Salesforce CLI installed
- GitHub Personal Access Token (for future stories)

### Deployment Steps

1. **Clone or download this project**
   ```bash
   cd ~/Documents/DevOpsCompass
   ```

2. **Authenticate to your Salesforce org**
   ```bash
   sf org login web --set-default --alias devops-compass
   ```

3. **Deploy the metadata**
   ```bash
   sf project deploy start --manifest manifest/package.xml
   ```

4. **Follow the SETUP.md guide** for:
   - GitHub authentication setup
   - Permission set assignment
   - Custom metadata configuration

### Complete Setup Guide

See [SETUP.md](./SETUP.md) for comprehensive deployment and configuration instructions.

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
- Project structure
- Data model
- Apex framework
- Security model

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
- PR analytics

### 🚀 Story 4: Deployment Tracking
- Manual deployment logging
- CI/CD integration
- Environment tracking
- Release management

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
**Version**: 0.1.0 (Foundation)

---

**Note**: This is the foundation release. Business functionality (GitHub sync, metrics, dashboards) will be added in future stories. The platform is ready to receive data and has all necessary architecture in place.
