/**
 * @description Utility class for common DevOps Compass operations
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class DevOpsCompassUtils {

    /**
     * @description Calculate duration in minutes between two datetimes
     * @param startTime Start datetime
     * @param endTime End datetime
     * @return Decimal Duration in minutes
     */
    public static Decimal calculateDurationMinutes(Datetime startTime, Datetime endTime) {
        if (startTime == null || endTime == null) {
            return null;
        }

        Long milliseconds = endTime.getTime() - startTime.getTime();
        return Decimal.valueOf(milliseconds) / (1000 * 60);
    }

    /**
     * @description Calculate PR cycle time (created to merged) in hours
     * @param createdDate PR created date
     * @param mergedDate PR merged date
     * @return Decimal Hours
     */
    public static Decimal calculatePRCycleTime(Datetime createdDate, Datetime mergedDate) {
        if (createdDate == null || mergedDate == null) {
            return null;
        }

        Long milliseconds = mergedDate.getTime() - createdDate.getTime();
        return Decimal.valueOf(milliseconds) / (1000 * 60 * 60);
    }

    /**
     * @description Check if PR is stale
     * @param createdDate PR created date
     * @param state PR state
     * @param thresholdDays Number of days to consider stale
     * @return Boolean True if stale
     */
    public static Boolean isPRStale(Datetime createdDate, String state, Integer thresholdDays) {
        if (createdDate == null || state != 'Open') {
            return false;
        }

        Datetime thresholdDate = Datetime.now().addDays(-thresholdDays);
        return createdDate < thresholdDate;
    }

    /**
     * @description Format datetime for GitHub API (ISO 8601)
     * @param dt Datetime
     * @return String Formatted datetime
     */
    public static String formatDateTimeForGitHub(Datetime dt) {
        if (dt == null) {
            return null;
        }
        return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    }

    /**
     * @description Get application settings from custom metadata
     * @return Application_Settings__mdt
     */
    public static Application_Settings__mdt getApplicationSettings() {
        List<Application_Settings__mdt> settings = [
            SELECT GitHub_Base_URL__c, Default_Sync_Interval__c,
                   Dashboard_Refresh__c, Default_Date_Range__c,
                   Stale_PR_Days__c, Enable_DORA__c, Enable_Deployments__c
            FROM Application_Settings__mdt
            LIMIT 1
        ];

        return settings.isEmpty() ? null : settings[0];
    }

    /**
     * @description Get active repository configurations
     * @return List<Repository_Config__mdt>
     */
    public static List<Repository_Config__mdt> getRepositoryConfigs() {
        return [
            SELECT Repository_Name__c, Repository_Owner__c, Provider__c,
                   Sync_Enabled__c, Polling_Interval__c, Default_Branch__c
            FROM Repository_Config__mdt
            WHERE Sync_Enabled__c = true
        ];
    }

    /**
     * @description Sanitize string for Salesforce field limits
     * @param str String to sanitize
     * @param maxLength Maximum length
     * @return String Sanitized string
     */
    public static String sanitizeString(String str, Integer maxLength) {
        if (String.isBlank(str)) {
            return str;
        }

        String sanitized = str.trim();
        return sanitized.length() > maxLength ? sanitized.substring(0, maxLength) : sanitized;
    }
}
