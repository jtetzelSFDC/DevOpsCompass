/**
 * @description Test class for Repository, PullRequest, and Contributor sync services
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class SyncServicesTest {

    @testSetup
    static void setup() {
        // Create test repository
        Repository__c repo = TestDataFactory.createRepository('test-repo', 'test-owner/test-repo', true);
    }

    @isTest
    static void testRepositorySyncService_Success() {
        // Set mock callout
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.RepositoryMock());

        Test.startTest();
        Repository__c repo = RepositorySyncService.syncRepository('test-owner', 'test-repo');
        Test.stopTest();

        System.assertNotEquals(null, repo, 'Repository should be created');
        System.assertEquals('test-repo', repo.Name, 'Repository name should match');
        System.assertEquals('GitHub', repo.Provider__c, 'Provider should be GitHub');
    }

    @isTest
    static void testRepositorySyncService_MultipleRepos() {
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.RepositoryMock());

        List<RepositorySyncService.RepositoryInfo> repos = new List<RepositorySyncService.RepositoryInfo>{
            new RepositorySyncService.RepositoryInfo('test-owner', 'repo1'),
            new RepositorySyncService.RepositoryInfo('test-owner', 'repo2')
        };

        Test.startTest();
        List<Repository__c> syncedRepos = RepositorySyncService.syncRepositories(repos);
        Test.stopTest();

        System.assertEquals(2, syncedRepos.size(), 'Should sync 2 repositories');
    }

    @isTest
    static void testPullRequestSyncService_Success() {
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.PullRequestListMock());

        Test.startTest();
        List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequests(repo.Id, 'open');
        Test.stopTest();

        System.assertNotEquals(null, prs, 'Pull requests should be returned');
        System.assert(prs.size() > 0, 'Should sync pull requests');
    }

    @isTest
    static void testPullRequestSyncService_MultipleRepos() {
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.PullRequestListMock());

        Test.startTest();
        List<Pull_Request__c> prs = PullRequestSyncService.syncPullRequestsForRepositories(
            new Set<Id>{repo.Id}, 'all'
        );
        Test.stopTest();

        System.assertNotEquals(null, prs, 'Pull requests should be returned');
    }

    @isTest
    static void testContributorSyncService_Success() {
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.ContributorListMock());

        Test.startTest();
        List<Contributor__c> contributors = ContributorSyncService.syncContributors(repo.Id);
        Test.stopTest();

        System.assertNotEquals(null, contributors, 'Contributors should be returned');
        System.assert(contributors.size() > 0, 'Should sync contributors');
    }

    @isTest
    static void testContributorSyncService_MultipleRepos() {
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new GitHubApiMock.ContributorListMock());

        Test.startTest();
        List<Contributor__c> contributors = ContributorSyncService.syncContributorsForRepositories(
            new Set<Id>{repo.Id}
        );
        Test.stopTest();

        System.assertNotEquals(null, contributors, 'Contributors should be returned');
    }

    @isTest
    static void testContributorSelector() {
        Repository__c repo = [SELECT Id FROM Repository__c LIMIT 1];

        // Create test contributor
        Contributor__c contributor = new Contributor__c(
            Name = 'testuser',
            GitHub_Username__c = 'testuser',
            External_Id__c = repo.Id + '-testuser',
            Contribution_Count__c = 100,
            Active__c = true
        );
        // Repository__c will be set automatically since it's master-detail
        // But we need to set it explicitly
        contributor.Repository__c = repo.Id;
        insert contributor;

        Test.startTest();
        List<Contributor__c> allActive = ContributorSelector.getAllActive();
        List<Contributor__c> byRepo = ContributorSelector.getByRepositoryId(repo.Id);
        List<Contributor__c> topContributors = ContributorSelector.getTopContributors(10);
        Test.stopTest();

        System.assert(!allActive.isEmpty(), 'Should return active contributors');
        System.assert(!byRepo.isEmpty(), 'Should return contributors for repository');
        System.assert(!topContributors.isEmpty(), 'Should return top contributors');
    }
}
