import { LightningElement, api, wire } from 'lwc';
import getTimelineData from '@salesforce/apex/DeploymentTimelineService.getTimelineData';

export default class DeploymentMilestoneTimeline extends LightningElement {
    @api recordId; // Pull Request ID

    milestones;
    error;
    isLoading = true;

    @wire(getTimelineData, { pullRequestId: '$recordId' })
    wiredTimeline({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.milestones = this.processMilestones(data);
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.milestones = undefined;
            console.error('Error loading timeline:', error);
        }
    }

    /**
     * Process milestones to add computed styling properties
     */
    processMilestones(data) {
        if (!data || data.length === 0) {
            return data;
        }

        return data.map((milestone, index) => {
            // Determine icon class
            let iconClass = 'milestone-icon';
            if (milestone.completed) {
                iconClass += ' completed';
            }
            if (milestone.isCurrent) {
                iconClass += ' current';
            }

            // Determine content class
            let contentClass = 'milestone-content';
            if (milestone.isCurrent) {
                contentClass += ' current';
            }

            // Determine line class
            let lineClass = 'milestone-line';
            if (milestone.completed) {
                lineClass += ' completed';
            }
            if (milestone.isCurrent) {
                lineClass += ' current';
            }

            // Show line for all except last milestone
            const showLine = index < data.length - 1;

            return {
                ...milestone,
                iconClass,
                contentClass,
                lineClass,
                showLine
            };
        });
    }

    get hasData() {
        return this.milestones && this.milestones.length > 0;
    }

    get hasError() {
        return this.error !== undefined;
    }

    get errorMessage() {
        if (!this.error) {
            return '';
        }

        // Extract error message from various error formats
        if (this.error.body && this.error.body.message) {
            return this.error.body.message;
        } else if (this.error.message) {
            return this.error.message;
        }

        return 'An unexpected error occurred while loading the timeline.';
    }
}
