/**
 * @description Test class for RepositoryService
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class RepositoryServiceTest {

    @isTest
    static void testUpsertFromGitHub_NewRepository() {
        // Arrange
        Map<String, Object> githubData = TestDataFactory.createMockGitHubRepoData('test-repo', 12345);

        // Act
        Test.startTest();
        Repository__c repo = RepositoryService.upsertFromGitHub(githubData);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, repo.Id, 'Repository should be inserted');
        System.assertEquals('test-repo', repo.Name, 'Name should match');
        System.assertEquals('12345', repo.External_Id__c, 'External ID should match');
        System.assertEquals('GitHub', repo.Provider__c, 'Provider should be GitHub');
        System.assertEquals('test-owner', repo.Owner__c, 'Owner should match');
    }

    @isTest
    static void testUpsertFromGitHub_ExistingRepository() {
        // Arrange
        Repository__c existingRepo = TestDataFactory.createRepository('existing-repo', '12345', true);
        Map<String, Object> githubData = TestDataFactory.createMockGitHubRepoData('updated-repo', 12345);

        // Act
        Test.startTest();
        Repository__c updatedRepo = RepositoryService.upsertFromGitHub(githubData);
        Test.stopTest();

        // Assert
        System.assertEquals(existingRepo.Id, updatedRepo.Id, 'Should update existing record');
        System.assertEquals('updated-repo', updatedRepo.Name, 'Name should be updated');
    }

    @isTest
    static void testBulkUpsertFromGitHub() {
        // Arrange
        List<Map<String, Object>> githubDataList = new List<Map<String, Object>>();
        for (Integer i = 0; i < 200; i++) {
            githubDataList.add(TestDataFactory.createMockGitHubRepoData('repo-' + i, 10000 + i));
        }

        // Act
        Test.startTest();
        List<Repository__c> repos = RepositoryService.bulkUpsertFromGitHub(githubDataList);
        Test.stopTest();

        // Assert
        System.assertEquals(200, repos.size(), 'Should process all repositories');
        System.assertEquals(200, [SELECT COUNT() FROM Repository__c], 'All repositories should be inserted');
    }

    @isTest
    static void testUpdateSyncStatus() {
        // Arrange
        Repository__c repo = TestDataFactory.createRepository('test-repo', 'ext-123', true);

        // Act
        Test.startTest();
        RepositoryService.updateSyncStatus(repo.Id, 'Success', Datetime.now());
        Test.stopTest();

        // Assert
        Repository__c updatedRepo = [SELECT Last_Sync_Status__c FROM Repository__c WHERE Id = :repo.Id];
        System.assertEquals('Success', updatedRepo.Last_Sync_Status__c, 'Sync status should be updated');
    }
}
