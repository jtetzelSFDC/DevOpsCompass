/**
 * @description Logging utility for DevOps Compass operations
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class DevOpsLogger {

    public enum LogLevel { DEBUG, INFO, WARNING, ERROR }

    /**
     * @description Log debug message
     * @param message Log message
     */
    public static void debug(String message) {
        log(LogLevel.DEBUG, message, null);
    }

    /**
     * @description Log info message
     * @param message Log message
     */
    public static void info(String message) {
        log(LogLevel.INFO, message, null);
    }

    /**
     * @description Log warning message
     * @param message Log message
     */
    public static void warn(String message) {
        log(LogLevel.WARNING, message, null);
    }

    /**
     * @description Log error message
     * @param message Log message
     * @param ex Exception (optional)
     */
    public static void error(String message, Exception ex) {
        log(LogLevel.ERROR, message, ex);
    }

    /**
     * @description Core logging method
     * @param level Log level
     * @param message Log message
     * @param ex Exception (optional)
     */
    private static void log(LogLevel level, String message, Exception ex) {
        String logMessage = '[DevOps Compass] [' + level.name() + '] ' + message;

        if (ex != null) {
            logMessage += '\nException: ' + ex.getMessage();
            logMessage += '\nStack Trace: ' + ex.getStackTraceString();
        }

        // Use System.debug for now; can be extended to custom object logging
        System.debug(logMessage);
    }

    /**
     * @description Log integration execution details
     * @param operation Operation name
     * @param status Status (Success/Warning/Failed)
     * @param details Execution details
     * @param recordsProcessed Number of records processed
     * @param errors Error messages
     */
    public static void logIntegration(
        String operation,
        String status,
        String details,
        Integer recordsProcessed,
        String errors
    ) {
        String logMessage = String.format(
            'Integration: {0}\nStatus: {1}\nDetails: {2}\nRecords: {3}',
            new List<String>{
                operation,
                status,
                details,
                String.valueOf(recordsProcessed)
            }
        );

        if (String.isNotBlank(errors)) {
            logMessage += '\nErrors: ' + errors;
        }

        System.debug(logMessage);
    }
}
