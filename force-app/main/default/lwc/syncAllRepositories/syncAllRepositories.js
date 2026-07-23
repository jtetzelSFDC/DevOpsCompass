import { LightningElement, track } from 'lwc';
import syncAllRepositoriesScheduled from '@salesforce/apex/GitHubSyncOrchestrator.syncAllRepositoriesScheduled';
import getSyncJobStatus from '@salesforce/apex/GitHubSyncOrchestrator.getSyncJobStatus';

export default class SyncAllRepositories extends LightningElement {
    @track isLoading = false;
    @track showResults = false;
    @track syncJobId = '';
    @track errorMessage = '';
    @track hasError = false;
    @track repositoriesSynced = 0;
    @track pullRequestsSynced = 0;
    @track openPullRequests = 0;
    @track contributorsSynced = 0;
    @track isPolling = false;
    pollInterval;

    handleSync() {
        this.isLoading = true;
        this.showResults = false;
        this.hasError = false;
        this.errorMessage = '';

        syncAllRepositoriesScheduled()
            .then(result => {
                console.log('Sync result:', JSON.stringify(result));
                if (result && result.syncJobId) {
                    this.syncJobId = result.syncJobId;
                    this.isPolling = true;
                    // Start polling for job status
                    this.startPolling();
                } else {
                    // Debug what we actually received
                    console.error('Invalid result:', result);
                    this.errorMessage = 'Failed to start sync job. Result: ' + JSON.stringify(result);
                    this.hasError = true;
                    this.showResults = true;
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('Sync error:', error);
                this.errorMessage = error.body ? error.body.message : (error.message || 'Unknown error occurred');
                this.hasError = true;
                this.showResults = true;
                this.isLoading = false;
            });
    }

    get successMessage() {
        return !this.hasError;
    }

    startPolling() {
        // Poll every 2 seconds
        this.pollInterval = setInterval(() => {
            this.checkSyncJobStatus();
        }, 2000);
    }

    checkSyncJobStatus() {
        getSyncJobStatus({ syncJobId: this.syncJobId })
            .then(job => {
                if (job) {
                    // Check if job is complete
                    if (job.Status__c === 'Completed' || job.Status__c === 'Completed with Errors' || job.Status__c === 'Failed') {
                        // Stop polling
                        clearInterval(this.pollInterval);
                        this.isPolling = false;
                        this.isLoading = false;
                        this.showResults = true;

                        // Parse the records processed from individual count fields
                        this.repositoriesSynced = job.Repositories_Synced__c || 0;
                        this.pullRequestsSynced = job.Pull_Requests_Synced__c || 0;
                        this.openPullRequests = job.Open_Pull_Requests__c || 0;
                        this.contributorsSynced = job.Contributors_Synced__c || 0;

                        // Set error info
                        this.hasError = job.Status__c !== 'Completed';
                        this.errorMessage = job.Error_Log__c || '';
                    }
                }
            })
            .catch(error => {
                clearInterval(this.pollInterval);
                this.isPolling = false;
                this.isLoading = false;
                this.showResults = true;
                this.hasError = true;
                this.errorMessage = 'Failed to check sync status: ' + (error.body ? error.body.message : error.message);
            });
    }

    disconnectedCallback() {
        // Clean up polling when component is destroyed
        if (this.pollInterval) {
            clearInterval(this.pollInterval);
        }
    }

    viewSyncJob() {
        if (this.syncJobId) {
            window.location.href = `/lightning/r/Sync_Job__c/${this.syncJobId}/view`;
        }
    }
}
