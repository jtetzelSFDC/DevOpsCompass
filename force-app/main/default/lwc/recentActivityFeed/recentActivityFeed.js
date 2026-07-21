import { LightningElement, api, wire } from 'lwc';
import getRecentActivity from '@salesforce/apex/ActivityService.getRecentActivity';

export default class RecentActivityFeed extends LightningElement {
    @api recordId;
    @api numberOfDays = 7;

    activities = [];
    error;

    @wire(getRecentActivity, { repositoryId: '$recordId', days: '$numberOfDays' })
    wiredActivities({ error, data }) {
        if (data) {
            this.activities = data.map(activity => ({
                ...activity,
                icon: this.getActivityIcon(activity.type),
                formattedDate: new Date(activity.activityDate).toLocaleString(),
                activityUrl: activity.recordId ? `/lightning/r/${activity.sObjectType}/${activity.recordId}/view` : null
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.activities = [];
        }
    }

    getActivityIcon(type) {
        const iconMap = {
            'PR_CREATED': 'utility:opened_folder',
            'PR_MERGED': 'utility:merge',
            'PR_CLOSED': 'utility:close',
            'COMMIT': 'utility:connected_apps'
        };
        return iconMap[type] || 'utility:activity';
    }

    get hasActivities() {
        return this.activities.length > 0;
    }
}
