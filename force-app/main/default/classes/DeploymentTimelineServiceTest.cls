/**
 * @description Test class for DeploymentTimelineService
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class DeploymentTimelineServiceTest {

    @testSetup
    static void setup() {
        // Create repository
        Repository__c repo = TestDataFactory.createRepository('testOwner/testRepo', true);

        // Create pull request
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 123, true);
        pr.Merged_Date__c = System.now().addDays(-2);
        update pr;

        // Create environments
        Environment__c qa = TestDataFactory.createEnvironment('QA', 'QA', 1, true);
        Environment__c uat = TestDataFactory.createEnvironment('UAT', 'UAT', 2, true);
        Environment__c prod = TestDataFactory.createEnvironment('Production', 'Production', 3, true);

        // Create deployments
        TestDataFactory.createDeployment(pr.Id, qa.Id, 'Successful', true);
        TestDataFactory.createDeployment(pr.Id, uat.Id, 'Successful', true);
    }

    @isTest
    static void testGetTimelineData() {
        Pull_Request__c pr = [SELECT Id FROM Pull_Request__c LIMIT 1];

        Test.startTest();
        List<TimelineBuilder.Milestone> milestones = DeploymentTimelineService.getTimelineData(pr.Id);
        Test.stopTest();

        System.assertNotEquals(null, milestones, 'Milestones should not be null');
        System.assertEquals(5, milestones.size(), 'Should have 5 milestones (Created, Merged, QA, UAT, Prod)');

        // Verify Created
        System.assertEquals('Created', milestones[0].label);
        System.assertEquals(true, milestones[0].completed);
        System.assertEquals('CREATED', milestones[0].milestoneType);

        // Verify Merged
        System.assertEquals('Merged', milestones[1].label);
        System.assertEquals(true, milestones[1].completed);
        System.assertEquals('MERGED', milestones[1].milestoneType);

        // Verify QA (deployed)
        System.assertEquals('QA', milestones[2].label);
        System.assertEquals(true, milestones[2].completed);
        System.assertEquals('ENVIRONMENT', milestones[2].milestoneType);

        // Verify UAT (deployed)
        System.assertEquals('UAT', milestones[3].label);
        System.assertEquals(true, milestones[3].completed);

        // Verify Production (not deployed)
        System.assertEquals('Production', milestones[4].label);
        System.assertEquals(false, milestones[4].completed);

        // Verify current milestone is UAT (highest completed)
        System.assertEquals(true, milestones[3].isCurrent, 'UAT should be current milestone');
    }

    @isTest
    static void testGetTimelineDataWithNoDeployments() {
        Repository__c repo = TestDataFactory.createRepository('newRepo/test', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 999, true);

        Test.startTest();
        List<TimelineBuilder.Milestone> milestones = DeploymentTimelineService.getTimelineData(pr.Id);
        Test.stopTest();

        System.assertNotEquals(null, milestones);

        // Should have Created, Merged, and 3 environments
        System.assertEquals(5, milestones.size());

        // Only Created should be completed
        System.assertEquals(true, milestones[0].completed);
        System.assertEquals(false, milestones[1].completed);
        System.assertEquals(false, milestones[2].completed);
        System.assertEquals(false, milestones[3].completed);
        System.assertEquals(false, milestones[4].completed);

        // Created should be current
        System.assertEquals(true, milestones[0].isCurrent);
    }

    @isTest
    static void testGetTimelineDataWithMultipleDeploymentsPerEnvironment() {
        Pull_Request__c pr = [SELECT Id FROM Pull_Request__c LIMIT 1];
        Environment__c qa = [SELECT Id FROM Environment__c WHERE Name = 'QA' LIMIT 1];

        // Create multiple deployments to QA
        Deployment__c oldDep = new Deployment__c(
            Pull_Request__c = pr.Id,
            Environment__c = qa.Id,
            Status__c = 'Successful',
            Start_Time__c = System.now().addDays(-5).addHours(-1),
            End_Time__c = System.now().addDays(-5)
        );
        insert oldDep;

        Deployment__c newDep = new Deployment__c(
            Pull_Request__c = pr.Id,
            Environment__c = qa.Id,
            Status__c = 'Successful',
            Start_Time__c = System.now().addDays(-1).addHours(-1),
            End_Time__c = System.now().addDays(-1)
        );
        insert newDep;

        Test.startTest();
        List<TimelineBuilder.Milestone> milestones = DeploymentTimelineService.getTimelineData(pr.Id);
        Test.stopTest();

        // Find QA milestone
        TimelineBuilder.Milestone qaMilestone;
        for (TimelineBuilder.Milestone m : milestones) {
            if (m.label == 'QA') {
                qaMilestone = m;
                break;
            }
        }

        System.assertNotEquals(null, qaMilestone, 'QA milestone should exist');
        System.assertEquals(true, qaMilestone.completed);

        // Should use the latest deployment date
        System.assertNotEquals(null, qaMilestone.completedDate);
        System.assertEquals(newDep.End_Time__c.date(), qaMilestone.completedDate.date());
    }

    @isTest
    static void testGetTimelineDataIgnoresFailedDeployments() {
        Pull_Request__c pr = [SELECT Id FROM Pull_Request__c LIMIT 1];
        Environment__c prod = [SELECT Id FROM Environment__c WHERE Name = 'Production' LIMIT 1];

        // Create a failed deployment to Production
        Deployment__c failedDep = new Deployment__c(
            Pull_Request__c = pr.Id,
            Environment__c = prod.Id,
            Status__c = 'Failed',
            Start_Time__c = System.now().addHours(-1),
            End_Time__c = System.now()
        );
        insert failedDep;

        Test.startTest();
        List<TimelineBuilder.Milestone> milestones = DeploymentTimelineService.getTimelineData(pr.Id);
        Test.stopTest();

        // Find Production milestone
        TimelineBuilder.Milestone prodMilestone;
        for (TimelineBuilder.Milestone m : milestones) {
            if (m.label == 'Production') {
                prodMilestone = m;
                break;
            }
        }

        System.assertNotEquals(null, prodMilestone);
        System.assertEquals(false, prodMilestone.completed, 'Failed deployment should not mark milestone as complete');
    }

    @isTest
    static void testGetTimelineDataWithInvalidPullRequestId() {
        // Create a valid 18-char Salesforce ID that doesn't exist
        Id fakePrId = TestDataFactory.generateFakeId(Pull_Request__c.SObjectType);

        Test.startTest();
        try {
            DeploymentTimelineService.getTimelineData(fakePrId);
            System.assert(false, 'Should have thrown an exception');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException || e instanceof QueryException,
                'Should throw AuraHandledException or QueryException');
        }
        Test.stopTest();
    }

    @isTest
    static void testSOQLQueryCount() {
        Pull_Request__c pr = [SELECT Id FROM Pull_Request__c LIMIT 1];

        Test.startTest();
        Integer queriesBeforeBefore = Limits.getQueries();
        DeploymentTimelineService.getTimelineData(pr.Id);
        Integer queriesAfter = Limits.getQueries();
        Test.stopTest();

        Integer queriesUsed = queriesAfter - queriesBeforeBefore;
        System.assert(queriesUsed <= 3, 'Should use 3 or fewer SOQL queries, used: ' + queriesUsed);
    }

    @isTest
    static void testEnvironmentOrdering() {
        Repository__c repo = TestDataFactory.createRepository('orderTest/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 777, true);

        // Create environments with specific display order
        Environment__c env1 = TestDataFactory.createEnvironment('Dev', 'Dev', 5, true);
        Environment__c env2 = TestDataFactory.createEnvironment('Stage', 'Stage', 10, true);
        Environment__c env3 = TestDataFactory.createEnvironment('PreProd', 'PreProd', 15, true);

        Test.startTest();
        List<TimelineBuilder.Milestone> milestones = DeploymentTimelineService.getTimelineData(pr.Id);
        Test.stopTest();

        // Verify environments appear in Display_Order sequence
        // Milestones: Created(1), Merged(2), then environments in order
        System.assert(milestones.size() >= 5);

        // Find environment milestones
        List<TimelineBuilder.Milestone> envMilestones = new List<TimelineBuilder.Milestone>();
        for (TimelineBuilder.Milestone m : milestones) {
            if (m.milestoneType == 'ENVIRONMENT') {
                envMilestones.add(m);
            }
        }

        System.assert(envMilestones.size() >= 3);
        // Orders should be sequential starting from 3
        System.assert(envMilestones[0].order < envMilestones[1].order);
        System.assert(envMilestones[1].order < envMilestones[2].order);
    }
}
