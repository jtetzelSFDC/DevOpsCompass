import { LightningElement, api, wire } from 'lwc';
import getTopContributors from '@salesforce/apex/ContributorService.getTopContributors';

export default class ContributorLeaderboard extends LightningElement {
    @api recordId;
    @api numberOfContributors = 10;

    contributors = [];
    error;

    @wire(getTopContributors, { repositoryId: '$recordId', limitCount: '$numberOfContributors' })
    wiredContributors({ error, data }) {
        if (data) {
            this.contributors = data.map((contributor, index) => ({
                ...contributor,
                rank: index + 1,
                profileUrl: `/lightning/r/Contributor__c/${contributor.Id}/view`,
                avatarInitials: contributor.GitHub_Username__c ?
                    contributor.GitHub_Username__c.substring(0, 2).toUpperCase() : 'UN'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contributors = [];
        }
    }

    get hasContributors() {
        return this.contributors.length > 0;
    }
}
