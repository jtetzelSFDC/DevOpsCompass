import { LightningElement, api, wire } from 'lwc';
import getOpenPullRequests from '@salesforce/apex/PullRequestService.getOpenPullRequests';
import getRecentlyMergedPullRequests from '@salesforce/apex/PullRequestService.getRecentlyMergedPullRequests';

export default class PullRequestMetrics extends LightningElement {
    @api recordId; // Repository ID if on record page

    openPRs = [];
    mergedPRs = [];
    error;
    isLoading = true;

    @wire(getOpenPullRequests, { repositoryId: '$recordId' })
    wiredOpenPRs({ error, data }) {
        if (data) {
            this.openPRs = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.openPRs = [];
        }
        this.checkLoadingComplete();
    }

    @wire(getRecentlyMergedPullRequests, { repositoryId: '$recordId', days: 30 })
    wiredMergedPRs({ error, data }) {
        if (data) {
            this.mergedPRs = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.mergedPRs = [];
        }
        this.checkLoadingComplete();
    }

    checkLoadingComplete() {
        // Simple check - if we have any data or error, loading is complete
        if (this.openPRs.length > 0 || this.mergedPRs.length > 0 || this.error) {
            this.isLoading = false;
        }
    }

    get openPRCount() {
        return this.openPRs.length;
    }

    get mergedPRCount() {
        return this.mergedPRs.length;
    }

    get hasOpenPRs() {
        return this.openPRs.length > 0;
    }

    get hasMergedPRs() {
        return this.mergedPRs.length > 0;
    }

    get openPRList() {
        return this.openPRs.slice(0, 5).map(pr => ({
            ...pr,
            url: `/lightning/r/Pull_Request__c/${pr.Id}/view`,
            createdDateFormatted: pr.Created_Date__c ?
                new Date(pr.Created_Date__c).toLocaleDateString() : ''
        }));
    }

    get mergedPRList() {
        return this.mergedPRs.slice(0, 5).map(pr => ({
            ...pr,
            url: `/lightning/r/Pull_Request__c/${pr.Id}/view`,
            mergedDateFormatted: pr.Merged_Date__c ?
                new Date(pr.Merged_Date__c).toLocaleDateString() : ''
        }));
    }
}
