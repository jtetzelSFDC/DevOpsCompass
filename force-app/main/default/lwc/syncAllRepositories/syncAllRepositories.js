import { LightningElement, track } from 'lwc';
import syncAllRepositories from '@salesforce/apex/GitHubSyncOrchestrator.syncAllRepositories';

export default class SyncAllRepositories extends LightningElement {
    @track isLoading = false;
    @track showResults = false;
    @track repositoriesSynced = 0;
    @track pullRequestsSynced = 0;
    @track contributorsSynced = 0;
    @track errorMessage = '';
    @track hasError = false;

    handleSync() {
        this.isLoading = true;
        this.showResults = false;
        this.hasError = false;
        this.errorMessage = '';

        syncAllRepositories()
            .then(result => {
                this.repositoriesSynced = result.repositoriesSynced;
                this.pullRequestsSynced = result.pullRequestsSynced;
                this.contributorsSynced = result.contributorsSynced;
                this.errorMessage = result.errorMessage;
                this.hasError = result.errorMessage && result.errorMessage.length > 0;
                this.showResults = true;
                this.isLoading = false;
            })
            .catch(error => {
                this.errorMessage = error.body ? error.body.message : 'Unknown error occurred';
                this.hasError = true;
                this.showResults = true;
                this.isLoading = false;
            });
    }

    get successMessage() {
        return !this.hasError;
    }

    get totalSynced() {
        return this.repositoriesSynced + this.pullRequestsSynced + this.contributorsSynced;
    }
}
