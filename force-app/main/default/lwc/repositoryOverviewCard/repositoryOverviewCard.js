import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Repository__c.Name',
    'Repository__c.Description__c',
    'Repository__c.Repository_URL__c',
    'Repository__c.Default_Branch__c',
    'Repository__c.Last_Sync_Date__c',
    'Repository__c.Last_Sync_Status__c',
    'Repository__c.Provider__c'
];

export default class RepositoryOverviewCard extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    repository;

    get repositoryName() {
        return this.repository.data?.fields?.Name?.value;
    }

    get description() {
        return this.repository.data?.fields?.Description__c?.value || 'No description available';
    }

    get repositoryUrl() {
        return this.repository.data?.fields?.Repository_URL__c?.value;
    }

    get defaultBranch() {
        return this.repository.data?.fields?.Default_Branch__c?.value || 'main';
    }

    get lastSyncDate() {
        const syncDate = this.repository.data?.fields?.Last_Sync_Date__c?.value;
        return syncDate ? new Date(syncDate).toLocaleString() : 'Never synced';
    }

    get syncStatus() {
        return this.repository.data?.fields?.Last_Sync_Status__c?.value || 'Unknown';
    }

    get syncStatusClass() {
        const status = this.syncStatus;
        if (status === 'Success') return 'slds-badge slds-badge_success';
        if (status === 'Failed') return 'slds-badge slds-badge_error';
        return 'slds-badge';
    }

    get provider() {
        return this.repository.data?.fields?.Provider__c?.value || 'GitHub';
    }

    get hasRepositoryUrl() {
        return !!this.repositoryUrl;
    }

    handleViewInGitHub() {
        if (this.repositoryUrl) {
            window.open(this.repositoryUrl, '_blank');
        }
    }
}
