/**
 * @description Test class for PullRequestService
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class PullRequestServiceTest {

    @isTest
    static void testUpsertFromGitHub_NewPR() {
        // Arrange
        Repository__c repo = TestDataFactory.createRepository('test-repo', 'ext-repo-1', true);
        Map<String, Object> prData = TestDataFactory.createMockGitHubPRData(101, 54321, 'Open');

        // Act
        Test.startTest();
        Pull_Request__c pr = PullRequestService.upsertFromGitHub(prData, repo.Id);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, pr.Id, 'PR should be inserted');
        System.assertEquals(101, pr.PR_Number__c, 'PR number should match');
        System.assertEquals('54321', pr.External_Id__c, 'External ID should match');
        System.assertEquals('Open', pr.State__c, 'State should be Open');
    }

    @isTest
    static void testUpsertFromGitHub_MergedPR() {
        // Arrange
        Repository__c repo = TestDataFactory.createRepository('test-repo', 'ext-repo-1', true);
        Map<String, Object> prData = TestDataFactory.createMockGitHubPRData(102, 54322, 'Merged');

        // Act
        Test.startTest();
        Pull_Request__c pr = PullRequestService.upsertFromGitHub(prData, repo.Id);
        Test.stopTest();

        // Assert
        System.assertEquals('Merged', pr.State__c, 'State should be Merged');
        System.assertNotEquals(null, pr.Merged_Date__c, 'Merged date should be populated');
    }

    @isTest
    static void testBulkUpsertFromGitHub() {
        // Arrange
        Repository__c repo = TestDataFactory.createRepository('test-repo', 'ext-repo-1', true);
        List<Object> prDataList = new List<Object>();
        for (Integer i = 0; i < 150; i++) {
            prDataList.add(TestDataFactory.createMockGitHubPRData(i + 1, 50000 + i, 'Open'));
        }

        // Act
        Test.startTest();
        List<Pull_Request__c> prs = PullRequestService.bulkUpsertFromGitHub(prDataList, repo.Id);
        Test.stopTest();

        // Assert
        System.assertEquals(150, prs.size(), 'Should process all PRs');
        System.assertEquals(150, [SELECT COUNT() FROM Pull_Request__c], 'All PRs should be inserted');
    }
}
