/**
 * @description Test class for GitHubSyncOrchestrator
 * @author DevOps Compass Team
 * @date 2026
 */
@IsTest
private class GitHubSyncOrchestratorTest {

    @TestSetup
    static void setup() {
        // Create test repository
        Repository__c repo = TestDataFactory.createRepository('TestOrg', 'TestRepo', true);
        insert repo;
    }

    @IsTest
    static void testSyncAllRepositories() {
        // Set mock for API calls
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock());

        Test.startTest();
        List<GitHubSyncOrchestrator.SyncResult> results = GitHubSyncOrchestrator.syncAllRepositories();
        Test.stopTest();

        // Verify results
        System.assertEquals(1, results.size(), 'Should return one result');
        GitHubSyncOrchestrator.SyncResult result = results[0];

        System.assert(result.success, 'Sync should succeed');
        System.assertEquals(1, result.repositoriesSynced, 'Should sync 1 repository');
        System.assert(result.pullRequestsSynced > 0, 'Should sync pull requests');
        System.assert(result.contributorsSynced > 0, 'Should sync contributors');

        // Verify sync job was created
        List<Sync_Job__c> syncJobs = [SELECT Id, Status__c, Job_Type__c FROM Sync_Job__c];
        System.assertEquals(1, syncJobs.size(), 'Should create one sync job');
        System.assertEquals('Completed', syncJobs[0].Status__c, 'Job should be completed');
        System.assertEquals('Full Sync', syncJobs[0].Job_Type__c, 'Job type should be Full Sync');
    }

    @IsTest
    static void testSyncAllRepositoriesNoActiveRepos() {
        // Deactivate the test repository
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];
        repo.Active__c = false;
        update repo;

        Test.startTest();
        List<GitHubSyncOrchestrator.SyncResult> results = GitHubSyncOrchestrator.syncAllRepositories();
        Test.stopTest();

        // Verify results
        GitHubSyncOrchestrator.SyncResult result = results[0];
        System.assert(result.success, 'Should succeed even with no active repos');
        System.assertEquals(0, result.repositoriesSynced, 'Should sync 0 repositories');
        System.assert(result.errorMessage.contains('No active repositories'), 'Should have error message');
    }

    @IsTest
    static void testDeleteOldSyncJobs() {
        // Create old sync jobs
        List<Sync_Job__c> oldJobs = new List<Sync_Job__c>();
        for (Integer i = 0; i < 5; i++) {
            oldJobs.add(new Sync_Job__c(
                Job_Type__c = 'Full Sync',
                Status__c = 'Completed',
                Start_Time__c = System.now().addDays(-15),
                End_Time__c = System.now().addDays(-15)
            ));
        }
        insert oldJobs;

        // Create recent sync jobs
        List<Sync_Job__c> recentJobs = new List<Sync_Job__c>();
        for (Integer i = 0; i < 3; i++) {
            recentJobs.add(new Sync_Job__c(
                Job_Type__c = 'Full Sync',
                Status__c = 'Completed',
                Start_Time__c = System.now().addDays(-5),
                End_Time__c = System.now().addDays(-5)
            ));
        }
        insert recentJobs;

        Test.startTest();
        GitHubSyncOrchestrator.deleteOldSyncJobs(10);
        Test.stopTest();

        // Verify old jobs deleted, recent jobs remain
        List<Sync_Job__c> remainingJobs = [SELECT Id FROM Sync_Job__c];
        System.assertEquals(3, remainingJobs.size(), 'Should keep only recent jobs');
    }

    @IsTest
    static void testSyncResultClass() {
        GitHubSyncOrchestrator.SyncResult result = new GitHubSyncOrchestrator.SyncResult();

        // Verify default values
        System.assert(result.success, 'Success should default to true');
        System.assertEquals(0, result.repositoriesSynced, 'Repos should default to 0');
        System.assertEquals(0, result.pullRequestsSynced, 'PRs should default to 0');
        System.assertEquals(0, result.contributorsSynced, 'Contributors should default to 0');
        System.assertEquals('', result.errorMessage, 'Error message should be empty');
    }
}
