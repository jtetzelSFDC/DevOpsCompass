# DevOps Compass - Architecture Documentation

## Story 0: Foundation Architecture

This document describes the technical architecture decisions, patterns, and rationale for the DevOps Compass platform foundation.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Design Principles](#design-principles)
3. [Layer Architecture](#layer-architecture)
4. [Data Model](#data-model)
5. [Integration Architecture](#integration-architecture)
6. [Security Model](#security-model)
7. [Apex Class Inventory](#apex-class-inventory)
8. [Metadata Inventory](#metadata-inventory)
9. [Future Extension Points](#future-extension-points)

---

## Architecture Overview

DevOps Compass follows **Salesforce Enterprise Design Patterns** with a clear separation of concerns across multiple layers:

```
┌─────────────────────────────────────────────────┐
│         User Interface Layer                    │
│    (Lightning App, Tabs, Future LWCs)           │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│         Service Layer (Business Logic)          │
│  RepositoryService, PullRequestService, etc.    │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│       Selector Layer (Data Access - SOQL)       │
│  RepositorySelector, PullRequestSelector, etc.  │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│          Data Model (Custom Objects)            │
│  Repository__c, Pull_Request__c, etc.           │
└─────────────────────────────────────────────────┘
                    ↕
┌─────────────────────────────────────────────────┐
│       Integration Layer (External APIs)         │
│       GitHubApiClient, Future Integrations      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│         External Systems (GitHub, etc.)         │
└─────────────────────────────────────────────────┘
```

---

## Design Principles

### 1. Salesforce First
- Native Salesforce user experience
- Leverage platform features (Reports, Dashboards, List Views)
- Standard Salesforce patterns and conventions

### 2. Metadata Driven
- Configuration via Custom Metadata Types
- No hardcoded values in Apex
- Enable/disable features via configuration
- Repository-specific settings

### 3. Secure by Design
- Named Credentials for external auth
- Permission Sets for access control
- Field-Level Security enabled
- External Credential Principals for sensitive data

### 4. Modular Architecture
- Clear layer separation
- Reusable components
- Each class has single responsibility
- Easy to test and maintain

### 5. API First
- All integrations through abstraction layers
- GitHub API client handles all HTTP
- Future providers (GitLab, Azure DevOps) can plug in
- Consistent error handling

### 6. Extensible by Design
- Provider-agnostic data model
- Pluggable integration framework
- Future webhook support
- Custom metadata for new repositories

### 7. Enterprise Ready
- Bulkified operations
- Governor limit aware
- Comprehensive test coverage (>85%)
- Proper exception handling
- Logging framework

---

## Layer Architecture

### Service Layer

**Purpose**: Contains business logic and orchestrates operations

**Classes**:
- `RepositoryService`: Repository upsert logic, GitHub data transformation
- `PullRequestService`: PR upsert logic, date parsing, state mapping

**Responsibilities**:
- Transform external data to Salesforce records
- Implement business rules
- Coordinate between layers
- Handle complex operations

**Example**:
```apex
// Transform GitHub data to Salesforce Repository
Repository__c repo = RepositoryService.upsertFromGitHub(githubData);
```

### Selector Layer

**Purpose**: Centralize all SOQL queries

**Classes**:
- `RepositorySelector`: All Repository__c queries
- `PullRequestSelector`: All Pull_Request__c queries

**Responsibilities**:
- Execute SOQL queries
- Return typed results
- Consistent field selection
- Query optimization

**Benefits**:
- Single source of truth for queries
- Easy to maintain and optimize
- Prevents query duplication
- Enables query mocking in tests

**Example**:
```apex
// Get all active repositories
List<Repository__c> repos = RepositorySelector.getAllActive();
```

### Domain Layer

**Purpose**: Record-level logic and utilities

**Classes**:
- `DevOpsCompassUtils`: Shared utility methods
- Future: `RepositoryDomain`, `PullRequestDomain` for record-level operations

**Responsibilities**:
- Calculation methods
- Data formatting
- String manipulation
- Date/time utilities

### Integration Layer

**Purpose**: External system communication

**Classes**:
- `GitHubApiClient`: GitHub REST API wrapper
- Future: `GitLabApiClient`, `AzureDevOpsClient`

**Responsibilities**:
- HTTP request/response handling
- Authentication management
- JSON parsing
- Rate limit awareness
- Error handling

### Operational Layer

**Purpose**: Logging, scheduling, async execution

**Classes**:
- `DevOpsLogger`: Centralized logging
- `GitHubSyncScheduler`: Scheduled synchronization
- `GitHubSyncQueueable`: Async operations

**Responsibilities**:
- Debug logging
- Integration logging
- Scheduled job execution
- Queueable job processing

---

## Data Model

### Object Classification

#### Transactional Objects
Records that represent activities and events:
- `Repository__c`: Source code repositories
- `Pull_Request__c`: Pull requests
- `Deployment__c`: Salesforce deployments
- `Deployment_Event__c`: (Future) Deployment timeline

#### Reference Objects
Slowly-changing reference data:
- `Environment__c`: Salesforce org environments
- `Contributor__c`: Developers/contributors
- `Release__c`: Logical software releases
- `Work_Item__c`: Jira stories/bugs

#### Analytics Objects
Calculated metrics and snapshots:
- `Metric_Snapshot__c`: Daily DORA metrics
- (Future) Aggregated trend data

#### Operational Objects
System health and monitoring:
- `Sync_Job__c`: Integration execution logs

### Data Relationships

```
Repository__c (1) ──┬── (n) Pull_Request__c
                    ├── (n) Work_Item__c
                    └── (n) Metric_Snapshot__c

Pull_Request__c (1) ──┬── (n) Deployment__c
                      └── (1) Work_Item__c

Environment__c (1) ──┬── (n) Deployment__c
                     └── (n) Release__c

Contributor__c (1) ──┬── (n) Pull_Request__c (lookup)
                     └── (n) Work_Item__c

Release__c (1) ──┬── (n) Pull_Request__c
                 └── (n) Work_Item__c
```

### External ID Strategy

All objects that sync from external systems use `External_Id__c`:
- **Type**: Text(100), External ID, Unique
- **Purpose**: Upsert operations, prevent duplicates
- **Format**: Provider-specific ID (e.g., GitHub repo ID, PR ID)

**Benefits**:
- Idempotent upsert operations
- No duplicate records
- Easy to resync data
- Supports data refresh

---

## Integration Architecture

### Named Credentials

**GitHub API**:
- **Name**: `GitHub_API`
- **Type**: Legacy Named Credential
- **URL**: `https://api.github.com`
- **Auth**: Custom (External Credential)

**Benefits**:
- Credentials stored securely
- No hardcoded tokens
- Easy credential rotation
- Per-user auth support (future)

### HTTP Callout Pattern

```apex
// All HTTP calls go through GitHubApiClient
HttpResponse res = GitHubApiClient.get('/repos/owner/repo');
Map<String, Object> data = GitHubApiClient.parseResponse(res);
```

**Error Handling**:
```apex
try {
    HttpResponse res = GitHubApiClient.get('/endpoint');
} catch (GitHubApiException e) {
    DevOpsLogger.error('GitHub API failed', e);
    // Handle 401, 403, 404, 500 errors
}
```

### Rate Limit Management

GitHub limits:
- **5,000 requests/hour** (authenticated)
- **30 search API requests/minute**

**Strategy**:
- Check rate limit before large operations
- Use pagination (max 100 per page)
- Cache frequently accessed data
- Schedule sync jobs with appropriate intervals

---

## Security Model

### Permission Sets

**DevOps Compass Administrator**:
- Full CRUD on all objects
- Execute all Apex classes
- Modify sync configuration
- View operational logs

**DevOps Compass User**:
- Read-only access to all objects
- View dashboards and reports
- No configuration access
- No sync job execution

### Object-Level Security (OLS)

All custom objects:
- **Sharing Model**: Read/Write
- **Rationale**: Allows Permission Sets to control access
- **Future**: May change to Private with sharing rules

### Field-Level Security (FLS)

- Permission Sets grant field access
- No manual FLS configuration required
- All fields visible to assigned users

### Authentication

**GitHub Integration**:
- Personal Access Token (PAT) stored in External Credential
- Never exposed to Apex or logs
- Rotatable without code changes

---

## Apex Class Inventory

### Integration Classes (3)
| Class | Purpose | Callout? |
|-------|---------|----------|
| `GitHubApiClient` | GitHub REST API wrapper | ✅ Yes |
| `GitHubSyncScheduler` | Scheduled synchronization | ✅ Yes (via Queueable) |
| `GitHubSyncQueueable` | Async sync operations | ✅ Yes |

### Service Classes (2)
| Class | Purpose |
|-------|---------|
| `RepositoryService` | Repository business logic |
| `PullRequestService` | Pull request business logic |

### Selector Classes (2)
| Class | Purpose |
|-------|---------|
| `RepositorySelector` | Repository SOQL queries |
| `PullRequestSelector` | Pull request SOQL queries |

### Utility Classes (2)
| Class | Purpose |
|-------|---------|
| `DevOpsCompassUtils` | Shared utilities |
| `DevOpsLogger` | Logging framework |

### Exception Classes (2)
| Class | Purpose |
|-------|---------|
| `DevOpsCompassException` | Base exception |
| `GitHubApiException` | API-specific exception |

### Test Classes (5)
| Class | Coverage |
|-------|----------|
| `TestDataFactory` | Test data creation |
| `RepositoryServiceTest` | Service layer tests |
| `PullRequestServiceTest` | Service layer tests |
| `RepositorySelectorTest` | Selector tests |
| `DevOpsCompassUtilsTest` | Utility tests |

**Total**: 16 Apex Classes

---

## Metadata Inventory

### Custom Objects (9)
- Repository__c
- Pull_Request__c
- Contributor__c
- Work_Item__c
- Release__c
- Deployment__c
- Environment__c
- Sync_Job__c
- Metric_Snapshot__c

### Custom Metadata Types (2)
- Application_Settings__mdt (1 record expected)
- Repository_Config__mdt (1 record per repository)

### Permission Sets (2)
- DevOps_Compass_Administrator
- DevOps_Compass_User

### Lightning App (1)
- DevOps Compass

### Custom Tabs (9)
- One per custom object

### Named Credentials (1)
- GitHub_API (requires manual setup)

---

## Future Extension Points

### Story 1: GitHub Sync Logic
- Implement actual sync in `GitHubSyncQueueable`
- Add `ContributorService` and `ContributorSelector`
- Implement pagination logic
- Add incremental sync support

### Story 2: Additional Providers
- `GitLabApiClient`
- `AzureDevOpsClient`
- Provider factory pattern

### Story 3: DORA Metrics
- `MetricsService` for calculations
- `MetricsScheduler` for nightly snapshots
- `MetricSnapshotSelector` for trend queries

### Story 4: Deployment Tracking
- `DeploymentService` for manual logging
- CI/CD webhook receivers
- `DeploymentEventService` for timeline

### Story 5: Webhooks
- Real-time PR updates
- Deployment notifications
- Custom webhook handlers

### Story 6: Advanced Analytics
- Time-series metrics
- Contributor velocity
- Repository health scores
- Deployment frequency trends

### Story 7: UI Enhancements
- Lightning Web Components
- Custom dashboards
- Interactive charts
- Drill-down views

---

## Design Decisions & Rationale

### Why Not Mirror GitHub Entirely?

**Decision**: Store only operational data, not full GitHub mirror

**Rationale**:
- Reduces Salesforce storage usage
- Minimizes GitHub API calls
- Improves query performance
- GitHub remains source of truth for details

**Example**: We store PR title, state, dates — but NOT individual commits, file diffs, or comments

---

### Why External ID on Every Object?

**Decision**: Use `External_Id__c` for upsert operations

**Rationale**:
- Enables idempotent sync operations
- Prevents duplicate records during re-sync
- Allows data refresh without data loss
- Standard Salesforce best practice

---

### Why Custom Metadata for Configuration?

**Decision**: Use Custom Metadata Types instead of Custom Settings

**Rationale**:
- Deployable across orgs
- Can be packaged
- Version controlled
- Better for CI/CD pipelines

---

### Why Selector Layer?

**Decision**: Centralize SOQL in dedicated classes

**Rationale**:
- Prevents query duplication
- Easy to optimize queries
- Single source of truth
- Enables consistent field selection
- Easier testing (mockable)

---

### Why Not Use Platform Events for Sync?

**Decision**: Use Scheduled Apex + Queueable

**Rationale**:
- Simpler for V1
- Platform Events add complexity
- Scheduled jobs easier to monitor
- Can add Platform Events later for real-time

---

## Testing Strategy

### Test Coverage Requirements

- **Minimum**: 85% per Story 0 requirements
- **Target**: 90%+ for production readiness

### Test Data Strategy

- `TestDataFactory` provides reusable test data
- Mock GitHub API responses
- Bulk test scenarios (200 records)
- Positive and negative test cases

### Test Isolation

- Each test class is independent
- No shared state between tests
- `@TestSetup` for common data
- Proper use of `Test.startTest()` and `Test.stopTest()`

---

## Monitoring & Observability

### Current Logging

- `DevOpsLogger` writes to debug logs
- Integration execution details captured
- Exception stack traces preserved

### Future Enhancements

- `Sync_Job__c` records for operational visibility
- Platform Events for real-time monitoring
- Custom notifications for failures
- Dashboard for sync health

---

## Governor Limit Considerations

### HTTP Callouts
- Max 100 per transaction
- Strategy: Use Queueable chaining for large syncs
- Paginate GitHub API calls (100 records max)

### SOQL Queries
- Max 100 per transaction
- Strategy: Selector layer optimizes queries
- Bulkify all operations

### DML Statements
- Max 150 per transaction
- Strategy: Batch upserts in service layer
- Use `Database.upsert()` for efficiency

### Apex CPU Time
- Max 10,000 ms per transaction
- Strategy: Offload to Queueable for long operations
- Use `@future` sparingly (Queueable preferred)

---

## Summary

Story 0 delivers a **production-ready foundation** with:
- ✅ Enterprise architecture patterns
- ✅ Modular, extensible design
- ✅ Comprehensive data model
- ✅ Secure authentication framework
- ✅ Governor limit awareness
- ✅ Test coverage >85%
- ✅ Complete documentation

**Next Steps**: Implement actual GitHub synchronization logic (Story 1)

---

**Document Version**: 1.0  
**Last Updated**: July 17, 2026  
**Authors**: DevOps Compass Team
