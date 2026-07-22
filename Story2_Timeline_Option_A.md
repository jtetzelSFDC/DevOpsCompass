# Story 2 Timeline - Option A: SLDS Path Component

## Visual Style
Uses Salesforce Lightning Design System's native **Path** component.

## Appearance
```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  ●━━━━━━━━●━━━━━━━━●━━━━━━━━●━━━━━━━━○━━━━━━━━○━━━━━━━━○      │
│  Created  Approved  Merged    QA      UAT      PROD             │
│  7/14     7/15      7/16      7/17    —         —               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

- **Filled circles (●)**: Completed stages
- **Empty circles (○)**: Upcoming stages
- **Current stage**: Highlighted with pulsing animation
- **Lines**: Connect stages, filled for completed sections

## Implementation

### Component Structure
```javascript
// deploymentTimeline.js
import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getTimelineData from '@salesforce/apex/DeploymentTimelineService.getTimelineData';

export default class DeploymentTimeline extends LightningElement {
    @api recordId; // Pull Request ID
    
    stages = [
        { key: 'created', label: 'Created', field: 'Created_Date__c' },
        { key: 'approved', label: 'Approved', field: 'Approved_Date__c' },
        { key: 'merged', label: 'Merged', field: 'Merged_Date__c' },
        { key: 'qa', label: 'QA', environment: 'QA' },
        { key: 'uat', label: 'UAT', environment: 'UAT' },
        { key: 'prod', label: 'PROD', environment: 'Production' }
    ];
    
    timelineData;
    
    @wire(getTimelineData, { pullRequestId: '$recordId' })
    wiredTimeline({ data, error }) {
        if (data) {
            this.timelineData = this.processStages(data);
        }
    }
    
    processStages(data) {
        // Transform into path format
        // Mark stages as complete/current/incomplete
        // Add date stamps
    }
}
```

### Template
```html
<!-- deploymentTimeline.html -->
<template>
    <lightning-card title="Deployment Pipeline">
        <div class="slds-path">
            <div class="slds-path__track">
                <template for:each={timelineData} for:item="stage">
                    <div key={stage.key} 
                         class={stage.className}
                         data-stage={stage.key}>
                        <span class="slds-path__stage-name">{stage.label}</span>
                        <span class="slds-path__stage-date">{stage.date}</span>
                    </div>
                </template>
            </div>
        </div>
    </lightning-card>
</template>
```

### Styling
Uses standard SLDS classes:
- `slds-path`
- `slds-path__item--complete`
- `slds-path__item--current`
- `slds-path__item--incomplete`

Minimal custom CSS needed.

## Apex Service

```apex
public class DeploymentTimelineService {
    
    public class TimelineStage {
        @AuraEnabled public String key;
        @AuraEnabled public String label;
        @AuraEnabled public String status; // complete, current, incomplete
        @AuraEnabled public DateTime stageDate;
        @AuraEnabled public String dateFormatted;
        @AuraEnabled public String environment;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TimelineStage> getTimelineData(Id pullRequestId) {
        // 1. Get PR record (Created, Approved, Merged dates)
        Pull_Request__c pr = [
            SELECT Created_Date__c, Approved_Date__c, Merged_Date__c
            FROM Pull_Request__c 
            WHERE Id = :pullRequestId
        ];
        
        // 2. Get deployment records for this PR
        List<Deployment__c> deployments = [
            SELECT Environment__r.Name, Deployed_Date__c, Status__c
            FROM Deployment__c
            WHERE Pull_Request__c = :pullRequestId
            ORDER BY Deployed_Date__c ASC
        ];
        
        // 3. Build timeline stages
        List<TimelineStage> stages = new List<TimelineStage>();
        
        // PR stages
        stages.add(createStage('created', 'Created', pr.Created_Date__c));
        stages.add(createStage('approved', 'Approved', pr.Approved_Date__c));
        stages.add(createStage('merged', 'Merged', pr.Merged_Date__c));
        
        // Deployment stages
        Map<String, Deployment__c> deploymentsByEnv = mapDeploymentsByEnvironment(deployments);
        stages.add(createDeploymentStage('qa', 'QA', deploymentsByEnv.get('QA')));
        stages.add(createDeploymentStage('uat', 'UAT', deploymentsByEnv.get('UAT')));
        stages.add(createDeploymentStage('prod', 'PROD', deploymentsByEnv.get('Production')));
        
        return stages;
    }
    
    private static TimelineStage createStage(String key, String label, DateTime stageDate) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.stageDate = stageDate;
        stage.status = stageDate != null ? 'complete' : 'incomplete';
        stage.dateFormatted = stageDate != null ? stageDate.format('MM/dd/yyyy') : '—';
        return stage;
    }
    
    private static TimelineStage createDeploymentStage(String key, String label, Deployment__c deployment) {
        TimelineStage stage = new TimelineStage();
        stage.key = key;
        stage.label = label;
        stage.environment = label;
        
        if (deployment != null) {
            stage.stageDate = deployment.Deployed_Date__c;
            stage.status = 'complete';
            stage.dateFormatted = deployment.Deployed_Date__c.format('MM/dd/yyyy');
        } else {
            stage.status = 'incomplete';
            stage.dateFormatted = '—';
        }
        
        return stage;
    }
    
    private static Map<String, Deployment__c> mapDeploymentsByEnvironment(List<Deployment__c> deployments) {
        Map<String, Deployment__c> result = new Map<String, Deployment__c>();
        for (Deployment__c dep : deployments) {
            // Keep most recent deployment per environment
            String envName = dep.Environment__r.Name;
            if (!result.containsKey(envName) || 
                dep.Deployed_Date__c > result.get(envName).Deployed_Date__c) {
                result.put(envName, dep);
            }
        }
        return result;
    }
}
```

## Pros
✅ Native Salesforce look and feel  
✅ Familiar to Salesforce users  
✅ SLDS automatically handles accessibility  
✅ Responsive out of the box  
✅ Minimal CSS maintenance  
✅ Fast to implement (~4 hours)  

## Cons
❌ Less visually distinctive  
❌ Limited customization options  
❌ Can't show rich deployment details (status, errors) inline  
❌ Horizontal space constrained on narrow screens  

## LOE
- **Schema changes**: 1 hour (add Pull_Request__c to Deployment, Approved fields to PR)
- **Apex service**: 2 hours (DeploymentTimelineService + test)
- **LWC component**: 3 hours (JS, HTML, CSS)
- **Page layout**: 0.5 hours (add to flexipage)
- **Testing**: 1.5 hours (Story2_Testing_Guide)

**Total: ~8 hours**
