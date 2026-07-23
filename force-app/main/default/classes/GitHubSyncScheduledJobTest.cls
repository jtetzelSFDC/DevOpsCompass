/**
 * @description Test class for GitHubSyncScheduledJob
 * @author DevOps Compass Team
 * @date 2026
 */
@IsTest
private class GitHubSyncScheduledJobTest {

    @TestSetup
    static void setup() {
        // Create test repository
        Repository__c repo = TestDataFactory.createRepository('TestOrg', 'TestRepo', true);
        insert repo;

        // Create test user with admin permission set
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'Admin',
            Email = 'testadmin@devopscompass.test',
            Username = 'testadmin@devopscompass.test.unique' + System.currentTimeMillis(),
            Alias = 'tadmin',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = p.Id,
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert testUser;

        // Assign permission set
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'DevOps_Compass_Administrator' LIMIT 1];
        insert new PermissionSetAssignment(
            AssigneeId = testUser.Id,
            PermissionSetId = ps.Id
        );
    }

    @IsTest
    static void testScheduledJobExecution() {
        // Set mock for API calls
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock());

        Test.startTest();
        // Execute the scheduled job
        GitHubSyncScheduledJob job = new GitHubSyncScheduledJob();
        String cronExp = '0 0 2 * * ?';
        String jobId = System.schedule('Test Sync Job', cronExp, job);
        Test.stopTest();

        // Verify job was scheduled
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExp, ct.CronExpression, 'Cron expression should match');

        // Verify sync job was created
        List<Sync_Job__c> syncJobs = [SELECT Id, Status__c FROM Sync_Job__c];
        System.assert(syncJobs.size() > 0, 'Should create sync job records');
    }

    @IsTest
    static void testScheduleNightlySync() {
        Test.startTest();
        String jobId = GitHubSyncScheduledJob.scheduleNightlySync();
        Test.stopTest();

        // Verify job was scheduled
        CronTrigger ct = [SELECT Id, CronJobDetail.Name, CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('DevOps Compass Nightly Sync', ct.CronJobDetail.Name, 'Job name should match');
        System.assertEquals('0 0 2 * * ?', ct.CronExpression, 'Should run at 2 AM daily');
    }

    @IsTest
    static void testEmailNotification() {
        // Set mock for API calls
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock());

        // Reset email invocations
        Integer emailsBefore = Limits.getEmailInvocations();

        Test.startTest();
        GitHubSyncScheduledJob job = new GitHubSyncScheduledJob();
        job.execute(null);
        Test.stopTest();

        // Verify email was sent (we can't check content in test, but can verify it was called)
        Integer emailsAfter = Limits.getEmailInvocations();
        System.assert(emailsAfter > emailsBefore, 'Should send email notification');
    }
}
