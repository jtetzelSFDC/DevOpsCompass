/**
 * @description Test class for RepositorySelector
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class RepositorySelectorTest {

    @isTest
    static void testGetAllActive() {
        // Arrange
        TestDataFactory.createRepositories(5, true);

        // Act
        Test.startTest();
        List<Repository__c> repos = RepositorySelector.getAllActive();
        Test.stopTest();

        // Assert
        System.assertEquals(5, repos.size(), 'Should return all active repositories');
    }

    @isTest
    static void testGetByExternalId() {
        // Arrange
        TestDataFactory.createRepository('test-repo', 'ext-123', true);

        // Act
        Test.startTest();
        Repository__c repo = RepositorySelector.getByExternalId('ext-123');
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, repo, 'Should find repository');
        System.assertEquals('ext-123', repo.External_Id__c, 'External ID should match');
    }

    @isTest
    static void testGetRepositoriesNeedingSync() {
        // Arrange
        Repository__c oldRepo = TestDataFactory.createRepository('old-repo', 'ext-old', false);
        oldRepo.Last_Sync_Date__c = Datetime.now().addHours(-2);
        insert oldRepo;

        Repository__c newRepo = TestDataFactory.createRepository('new-repo', 'ext-new', true);

        // Act
        Test.startTest();
        List<Repository__c> repos = RepositorySelector.getRepositoriesNeedingSync(60);
        Test.stopTest();

        // Assert
        System.assert(repos.size() >= 1, 'Should return repositories needing sync');
    }
}
