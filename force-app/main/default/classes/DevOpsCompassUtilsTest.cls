/**
 * @description Test class for DevOpsCompassUtils
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class DevOpsCompassUtilsTest {

    @isTest
    static void testCalculateDurationMinutes() {
        // Arrange
        Datetime start = Datetime.now();
        Datetime endTime = start.addMinutes(30);

        // Act
        Decimal duration = DevOpsCompassUtils.calculateDurationMinutes(start, endTime);

        // Assert
        System.assertEquals(30, duration, 'Duration should be 30 minutes');
    }

    @isTest
    static void testCalculatePRCycleTime() {
        // Arrange
        Datetime created = Datetime.now().addDays(-2);
        Datetime merged = Datetime.now();

        // Act
        Decimal hours = DevOpsCompassUtils.calculatePRCycleTime(created, merged);

        // Assert
        System.assertEquals(48, hours, 'Cycle time should be 48 hours');
    }

    @isTest
    static void testIsPRStale() {
        // Arrange
        Datetime oldDate = Datetime.now().addDays(-10);

        // Act
        Boolean isStale = DevOpsCompassUtils.isPRStale(oldDate, 'Open', 7);

        // Assert
        System.assertEquals(true, isStale, 'PR should be stale');
    }

    @isTest
    static void testFormatDateTimeForGitHub() {
        // Arrange
        Datetime testDate = Datetime.newInstanceGmt(2026, 1, 15, 10, 30, 0);

        // Act
        String formatted = DevOpsCompassUtils.formatDateTimeForGitHub(testDate);

        // Assert
        System.assert(formatted.contains('2026-01-15'), 'Should contain date');
        System.assert(formatted.contains('10:30:00'), 'Should contain time');
    }

    @isTest
    static void testSanitizeString() {
        // Arrange
        String longString = 'This is a very long string that exceeds the maximum length limit';

        // Act
        String sanitized = DevOpsCompassUtils.sanitizeString(longString, 20);

        // Assert
        System.assertEquals(20, sanitized.length(), 'String should be truncated to 20 characters');
    }
}
