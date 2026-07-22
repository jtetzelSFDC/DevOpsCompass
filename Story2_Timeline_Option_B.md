# Story 2 Timeline - Option B: Vertical Timeline (Custom Design)

## Visual Style
Custom vertical timeline with deployment cards and status indicators.

## Appearance
```
┌────────────────────────────────────────────────────────┐
│  Deployment Timeline                                   │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ✓  Created                           Jul 14, 2026    │
│  │  Pull request opened by jtetzelSFDC   10:32 AM     │
│  │                                                     │
│  ✓  Approved                          Jul 15, 2026    │
│  │  Reviewed and approved                 2:14 PM     │
│  │                                                     │
│  ✓  Merged                            Jul 16, 2026    │
│  │  Merged to main branch                11:05 AM     │
│  │                                                     │
│  ✓  Deployed to QA                    Jul 17, 2026    │
│  ┃  Status: Successful                    8:45 AM     │
│  ┃  Environment: QA Sandbox                           │
│  │                                                     │
│  ◉  Deployed to UAT                   In Progress     │
│  ┃  Deployment scheduled for Jul 18                   │
│  │                                                     │
│  ○  Deployed to PROD                  Pending         │
│     Awaiting UAT validation                           │
│                                                        │
└────────────────────────────────────────────────────────┘
```

**Legend:**
- `✓` Completed (green)
- `◉` In Progress (blue, pulsing)
- `○` Pending (gray)
- `│` Connecting line (gray for pending, colored for complete)
- `┃` Thick line for current stage

## Implementation

### Component Structure
```javascript
// deploymentTimeline.js
import { LightningElement, api, wire } from 'lwc';
import getTimelineData from '@salesforce/apex/DeploymentTimelineService.getTimelineData';

export default class DeploymentTimeline extends LightningElement {
    @api recordId; // Pull Request ID
    
    timelineStages;
    error;
    
    @wire(getTimelineData, { pullRequestId: '$recordId' })
    wiredTimeline({ data, error }) {
        if (data) {
            this.timelineStages = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.timelineStages = undefined;
        }
    }
    
    get hasData() {
        return this.timelineStages && this.timelineStages.length > 0;
    }
}
```

### Template
```html
<!-- deploymentTimeline.html -->
<template>
    <lightning-card title="Deployment Timeline" icon-name="standard:stage">
        
        <template if:true={hasData}>
            <div class="timeline-container">
                <template for:each={timelineStages} for:item="stage">
                    <div key={stage.key} class={stage.containerClass}>
                        
                        <!-- Timeline Icon -->
                        <div class={stage.iconClass}>
                            <lightning-icon 
                                icon-name={stage.icon}
                                size="x-small"
                                variant={stage.iconVariant}>
                            </lightning-icon>
                        </div>
                        
                        <!-- Timeline Content Card -->
                        <div class="timeline-content">
                            <div class="timeline-header">
                                <h3 class="timeline-title">{stage.label}</h3>
                                <span class="timeline-date">{stage.dateFormatted}</span>
                            </div>
                            
                            <template if:true={stage.description}>
                                <p class="timeline-description">{stage.description}</p>
                            </template>
                            
                            <!-- Deployment-specific details -->
                            <template if:true={stage.isDeployment}>
                                <div class="deployment-details">
                                    <template if:true={stage.deploymentStatus}>
                                        <div class="detail-row">
                                            <span class="detail-label">Status:</span>
                                            <lightning-badge 
                                                label={stage.deploymentStatus}
                                                variant={stage.statusVariant}>
                                            </lightning-badge>
                                        </div>
                                    </template>
                                    
                                    <template if:true={stage.environment}>
                                        <div class="detail-row">
                                            <span class="detail-label">Environment:</span>
                                            <span>{stage.environment}</span>
                                        </div>
                                    </template>
                                    
                                    <template if:true={stage.deploymentUrl}>
                                        <div class="detail-row">
                                            <a href={stage.deploymentUrl} target="_blank">
                                                View Deployment →
                                            </a>
                                        </div>
                                    </template>
                                </div>
                            </template>
                        </div>
                        
                        <!-- Vertical connecting line -->
                        <template if:false={stage.isLast}>
                            <div class={stage.lineClass}></div>
                        </template>
                    </div>
                </template>
            </div>
        </template>
        
        <template if:true={error}>
            <div class="slds-text-color_error slds-p-around_medium">
                Error loading timeline data
            </div>
        </template>
        
    </lightning-card>
</template>
```

### Styling (CSS)
```css
/* deploymentTimeline.css */

.timeline-container {
    padding: 1rem 1.5rem;
}

.timeline-stage {
    position: relative;
    display: flex;
    padding-bottom: 2rem;
}

.timeline-stage:last-child {
    padding-bottom: 0;
}

/* Icon circle */
.timeline-icon {
    position: relative;
    flex-shrink: 0;
    width: 2rem;
    height: 2rem;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: var(--lwc-colorBackground);
    z-index: 2;
}

.timeline-icon.complete {
    background-color: var(--lwc-colorBackgroundSuccess);
}

.timeline-icon.current {
    background-color: var(--lwc-brandPrimary);
    animation: pulse 2s infinite;
}

.timeline-icon.pending {
    background-color: var(--lwc-colorBackgroundRowHover);
    border: 2px dashed var(--lwc-colorBorder);
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
}

/* Content card */
.timeline-content {
    flex-grow: 1;
    margin-left: 1rem;
    padding: 0.75rem 1rem;
    background-color: var(--lwc-colorBackground);
    border: 1px solid var(--lwc-colorBorder);
    border-radius: 0.25rem;
}

.timeline-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 0.5rem;
}

.timeline-title {
    font-size: 1rem;
    font-weight: 600;
    margin: 0;
}

.timeline-date {
    font-size: 0.875rem;
    color: var(--lwc-colorTextWeak);
}

.timeline-description {
    font-size: 0.875rem;
    color: var(--lwc-colorTextDefault);
    margin: 0.25rem 0 0 0;
}

/* Deployment details */
.deployment-details {
    margin-top: 0.75rem;
    padding-top: 0.75rem;
    border-top: 1px solid var(--lwc-colorBorder);
}

.detail-row {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    margin-bottom: 0.5rem;
}

.detail-row:last-child {
    margin-bottom: 0;
}

.detail-label {
    font-weight: 600;
    font-size: 0.875rem;
}

/* Vertical connecting line */
.timeline-line {
    position: absolute;
    left: 0.9375rem; /* Center of icon circle */
    top: 2rem;
    bottom: -2rem;
    width: 2px;
    z-index: 1;
}

.timeline-line.complete {
    background-color: var(--lwc-colorBackgroundSuccess);
}

.timeline-line.current {
    background: linear-gradient(
        to bottom,
        var(--lwc-brandPrimary) 0%,
        var(--lwc-colorBorder) 100%
    );
}

.timeline-line.pending {
    background-color: var(--lwc-colorBorder);
    border-left: 2px dashed var(--lwc-colorBorder);
}
```

## Apex Service

```apex
public class DeploymentTimelineService {
    
    public class TimelineStage {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String status; // complete, current, pending
        @AuraEnabled public DateTime stageDate;
        @AuraEnabled public String dateFormatted;
        @AuraEnabled public String timeFormatted;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean isDeployment;
        @AuraEnabled public Boolean isLast;
        
        // Deployment-specific fields
        @AuraEnabled public String environment;
        @AuraEnabled public String deploymentStatus;
        @AuraEnabled public String statusVariant; // success, warning, error
        @AuraEnabled public String deploymentUrl;
        
        // Frontend computed properties
        @AuraEnabled public String containerClass;
        @AuraEnabled public String iconClass;
        @AuraEnabled public String icon;
        @AuraEnabled public String iconVariant;
        @AuraEnabled public String lineClass;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TimelineStage> getTimelineData(Id pullRequestId) {
        // 1. Get PR record
        Pull_Request__c pr = [
            SELECT Id, PR_Number__c, Author__c, 
                   Created_Date__c, Approved__c, Approved_Date__c, 
                   Merged_Date__c, State__c
            FROM Pull_Request__c 
            WHERE Id = :pullRequestId
        ];
        
        // 2. Get deployments for this PR
        List<Deployment__c> deployments = [
            SELECT Id, Environment__r.Name, Environment__r.Type__c,
                   Deployed_Date__c, Status__c, Deployment_URL__c
            FROM Deployment__c
            WHERE Pull_Request__c = :pullRequestId
            ORDER BY Deployed_Date__c ASC
        ];
        
        // 3. Build timeline stages
        List<TimelineStage> stages = new List<TimelineStage>();
        
        // PR Created
        stages.add(createPRStage(
            'created', 
            'Created', 
            pr.Created_Date__c,
            'Pull request opened by ' + pr.Author__c,
            'utility:add'
        ));
        
        // PR Approved
        if (pr.Approved__c) {
            stages.add(createPRStage(
                'approved',
                'Approved',
                pr.Approved_Date__c,
                'Reviewed and approved',
                'utility:check'
            ));
        } else {
            stages.add(createPendingStage(
                'approved',
                'Approved',
                'Awaiting code review',
                'utility:priority'
            ));
        }
        
        // PR Merged
        if (pr.Merged_Date__c != null) {
            stages.add(createPRStage(
                'merged',
                'Merged',
                pr.Merged_Date__c,
                'Merged to main branch',
                'utility:merge'
            ));
        } else {
            stages.add(createPendingStage(
                'merged',
                'Merged',
                pr.State__c == 'Open' ? 'PR still open' : 'PR closed without merge',
                'utility:merge'
            ));
        }
        
        // Deployment stages
        Map<String, Deployment__c> deploymentsByEnv = mapDeploymentsByEnvironment(deployments);
        
        // QA
        Deployment__c qaDep = deploymentsByEnv.get('QA');
        if (qaDep != null) {
            stages.add(createDeploymentStage('qa', 'Deployed to QA', qaDep));
        } else if (pr.Merged_Date__c != null) {
            stages.add(createPendingDeploymentStage('qa', 'Deployed to QA', 'QA'));
        } else {
            stages.add(createPendingStage('qa', 'Deployed to QA', 'Awaiting merge', 'utility:frozen'));
        }
        
        // UAT
        Deployment__c uatDep = deploymentsByEnv.get('UAT');
        if (uatDep != null) {
            stages.add(createDeploymentStage('uat', 'Deployed to UAT', uatDep));
        } else if (qaDep != null && qaDep.Status__c == 'Successful') {
            stages.add(createPendingDeploymentStage('uat', 'Deployed to UAT', 'UAT'));
        } else {
            stages.add(createPendingStage('uat', 'Deployed to UAT', 'Awaiting QA validation', 'utility:frozen'));
        }
        
        // PROD
        Deployment__c prodDep = deploymentsByEnv.get('Production');
        if (prodDep != null) {
            stages.add(createDeploymentStage('prod', 'Deployed to PROD', prodDep));
        } else if (uatDep != null && uatDep.Status__c == 'Successful') {
            stages.add(createPendingDeploymentStage('prod', 'Deployed to PROD', 'Production'));
        } else {
            stages.add(createPendingStage('prod', 'Deployed to PROD', 'Awaiting UAT validation', 'utility:frozen'));
        }
        
        // Mark last stage
        if (!stages.isEmpty()) {
            stages[stages.size() - 1].isLast = true;
        }
        
        // Apply styling classes
        for (TimelineStage stage : stages) {
            applyStyleClasses(stage);
        }
        
        return stages;
    }
    
    private static TimelineStage createPRStage(String key, String label, DateTime stageDate, String description, String icon) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.stageDate = stageDate;
        stage.status = 'complete';
        stage.dateFormatted = formatDate(stageDate);
        stage.timeFormatted = formatTime(stageDate);
        stage.description = description;
        stage.isDeployment = false;
        stage.icon = icon;
        return stage;
    }
    
    private static TimelineStage createDeploymentStage(String key, String label, Deployment__c deployment) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.stageDate = deployment.Deployed_Date__c;
        stage.status = 'complete';
        stage.dateFormatted = formatDate(deployment.Deployed_Date__c);
        stage.timeFormatted = formatTime(deployment.Deployed_Date__c);
        stage.isDeployment = true;
        stage.environment = deployment.Environment__r.Name;
        stage.deploymentStatus = deployment.Status__c;
        stage.statusVariant = getStatusVariant(deployment.Status__c);
        stage.deploymentUrl = '/' + deployment.Id;
        stage.icon = 'utility:upload';
        stage.description = 'Deployed to ' + deployment.Environment__r.Name;
        return stage;
    }
    
    private static TimelineStage createPendingDeploymentStage(String key, String label, String envName) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.status = 'pending';
        stage.dateFormatted = 'Pending';
        stage.isDeployment = true;
        stage.environment = envName;
        stage.description = 'Deployment scheduled';
        stage.icon = 'utility:clock';
        return stage;
    }
    
    private static TimelineStage createPendingStage(String key, String label, String description, String icon) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.status = 'pending';
        stage.dateFormatted = 'Pending';
        stage.description = description;
        stage.isDeployment = false;
        stage.icon = icon;
        return stage;
    }
    
    private static void applyStyleClasses(TimelineStage stage) {
        stage.containerClass = 'timeline-stage';
        stage.iconClass = 'timeline-icon ' + stage.status;
        stage.lineClass = 'timeline-line ' + stage.status;
        stage.iconVariant = stage.status == 'complete' ? 'inverse' : 'default';
    }
    
    private static String formatDate(DateTime dt) {
        if (dt == null) return '—';
        return dt.format('MMM dd, yyyy');
    }
    
    private static String formatTime(DateTime dt) {
        if (dt == null) return '';
        return dt.format('h:mm a');
    }
    
    private static String getStatusVariant(String status) {
        if (status == 'Successful') return 'success';
        if (status == 'Failed') return 'error';
        if (status == 'In Progress') return 'warning';
        return 'default';
    }
    
    private static Map<String, Deployment__c> mapDeploymentsByEnvironment(List<Deployment__c> deployments) {
        Map<String, Deployment__c> result = new Map<String, Deployment__c>();
        for (Deployment__c dep : deployments) {
            String envType = dep.Environment__r.Type__c;
            if (!result.containsKey(envType) || 
                dep.Deployed_Date__c > result.get(envType).Deployed_Date__c) {
                result.put(envType, dep);
            }
        }
        return result;
    }
}
```

## Pros
✅ Visually distinctive and modern  
✅ Shows rich deployment details (status, environment, links)  
✅ Displays full descriptions and context  
✅ Better vertical space usage  
✅ Can show "in progress" state with animation  
✅ More informative for complex deployments  
✅ Expandable design (can add error logs, rollback buttons, etc.)  

## Cons
❌ More custom CSS to maintain  
❌ Longer implementation time  
❌ Need to test accessibility manually  
❌ Takes more vertical space on page  
❌ Custom animations may not match all Salesforce themes  

## LOE
- **Schema changes**: 1 hour (add Pull_Request__c to Deployment, Approved fields to PR)
- **Apex service**: 3 hours (more complex logic for status/descriptions)
- **LWC component**: 5 hours (more complex template + custom CSS)
- **Page layout**: 0.5 hours (add to flexipage)
- **Testing**: 2 hours (Story2_Testing_Guide)
- **Accessibility testing**: 0.5 hours

**Total: ~12 hours**
