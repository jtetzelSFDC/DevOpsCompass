/**
 * @description Test class for TimelineBuilder
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
private class TimelineBuilderTest {

    @isTest
    static void testBuildTimelineWithAllMilestones() {
        // Create test data
        Repository__c repo = TestDataFactory.createRepository('test/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 1, true);
        pr.Merged_Date__c = System.now().addHours(-48);
        update pr;

        Environment__c qa = TestDataFactory.createEnvironment('QA', 'QA', 1, true);
        Environment__c uat = TestDataFactory.createEnvironment('UAT', 'UAT', 2, true);
        Environment__c prod = TestDataFactory.createEnvironment('Production', 'Production', 3, true);

        Deployment__c qaDep = TestDataFactory.createDeployment(pr.Id, qa.Id, 'Successful', true);
        Deployment__c uatDep = TestDataFactory.createDeployment(pr.Id, uat.Id, 'Successful', true);

        List<Environment__c> environments = new List<Environment__c>{ qa, uat, prod };
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>{
            qa.Id => qaDep,
            uat.Id => uatDep
        };

        Test.startTest();
        TimelineBuilder builder = new TimelineBuilder()
            .withPullRequest(pr)
            .withEnvironments(environments)
            .withDeployments(deploymentMap);

        List<TimelineBuilder.Milestone> milestones = builder.build();
        Test.stopTest();

        // Assertions
        System.assertEquals(5, milestones.size(), 'Should have 5 milestones');

        // Created
        System.assertEquals('Created', milestones[0].label);
        System.assertEquals(true, milestones[0].completed);
        System.assertEquals(1, milestones[0].order);
        System.assertEquals('CREATED', milestones[0].milestoneType);

        // Merged
        System.assertEquals('Merged', milestones[1].label);
        System.assertEquals(true, milestones[1].completed);
        System.assertEquals(2, milestones[1].order);
        System.assertEquals('MERGED', milestones[1].milestoneType);

        // QA
        System.assertEquals('QA', milestones[2].label);
        System.assertEquals(true, milestones[2].completed);
        System.assertEquals(3, milestones[2].order);
        System.assertEquals('ENVIRONMENT', milestones[2].milestoneType);

        // UAT
        System.assertEquals('UAT', milestones[3].label);
        System.assertEquals(true, milestones[3].completed);
        System.assertEquals(4, milestones[3].order);

        // Production (incomplete)
        System.assertEquals('Production', milestones[4].label);
        System.assertEquals(false, milestones[4].completed);
        System.assertEquals(5, milestones[4].order);

        // Current milestone should be UAT (highest completed)
        System.assertEquals(false, milestones[0].isCurrent);
        System.assertEquals(false, milestones[1].isCurrent);
        System.assertEquals(false, milestones[2].isCurrent);
        System.assertEquals(true, milestones[3].isCurrent, 'UAT should be current');
        System.assertEquals(false, milestones[4].isCurrent);
    }

    @isTest
    static void testBuildTimelineWithNoMerge() {
        Repository__c repo = TestDataFactory.createRepository('test/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 1, true);
        // No merge date

        Environment__c qa = TestDataFactory.createEnvironment('QA', 'QA', 1, true);

        List<Environment__c> environments = new List<Environment__c>{ qa };
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>();

        Test.startTest();
        TimelineBuilder builder = new TimelineBuilder()
            .withPullRequest(pr)
            .withEnvironments(environments)
            .withDeployments(deploymentMap);

        List<TimelineBuilder.Milestone> milestones = builder.build();
        Test.stopTest();

        System.assertEquals(3, milestones.size());
        System.assertEquals(true, milestones[0].completed, 'Created should be complete');
        System.assertEquals(false, milestones[1].completed, 'Merged should be incomplete');
        System.assertEquals(false, milestones[2].completed, 'QA should be incomplete');

        // Current milestone should be Created
        System.assertEquals(true, milestones[0].isCurrent, 'Created should be current');
    }

    @isTest
    static void testBuildTimelineWithNoEnvironments() {
        Repository__c repo = TestDataFactory.createRepository('test/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 1, true);
        pr.Merged_Date__c = System.now().addHours(-24);
        update pr;

        List<Environment__c> environments = new List<Environment__c>();
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>();

        Test.startTest();
        TimelineBuilder builder = new TimelineBuilder()
            .withPullRequest(pr)
            .withEnvironments(environments)
            .withDeployments(deploymentMap);

        List<TimelineBuilder.Milestone> milestones = builder.build();
        Test.stopTest();

        System.assertEquals(2, milestones.size(), 'Should only have Created and Merged');
        System.assertEquals('Created', milestones[0].label);
        System.assertEquals('Merged', milestones[1].label);

        // Current should be Merged (highest completed)
        System.assertEquals(false, milestones[0].isCurrent);
        System.assertEquals(true, milestones[1].isCurrent);
    }

    @isTest
    static void testBuildTimelineWithAllCompleted() {
        Repository__c repo = TestDataFactory.createRepository('test/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 1, true);
        pr.Merged_Date__c = System.now().addDays(-3);
        update pr;

        Environment__c qa = TestDataFactory.createEnvironment('QA', 'QA', 1, true);
        Environment__c prod = TestDataFactory.createEnvironment('Production', 'Production', 2, true);

        Deployment__c qaDep = TestDataFactory.createDeployment(pr.Id, qa.Id, 'Successful', true);
        Deployment__c prodDep = TestDataFactory.createDeployment(pr.Id, prod.Id, 'Successful', true);

        List<Environment__c> environments = new List<Environment__c>{ qa, prod };
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>{
            qa.Id => qaDep,
            prod.Id => prodDep
        };

        Test.startTest();
        TimelineBuilder builder = new TimelineBuilder()
            .withPullRequest(pr)
            .withEnvironments(environments)
            .withDeployments(deploymentMap);

        List<TimelineBuilder.Milestone> milestones = builder.build();
        Test.stopTest();

        // All 4 milestones should be complete
        for (TimelineBuilder.Milestone m : milestones) {
            System.assertEquals(true, m.completed, m.label + ' should be complete');
        }

        // Production should be current (last completed)
        System.assertEquals(true, milestones[3].isCurrent, 'Production should be current');
    }

    @isTest
    static void testMilestoneOrdering() {
        Repository__c repo = TestDataFactory.createRepository('test/repo', true);
        Pull_Request__c pr = TestDataFactory.createPullRequest(repo.Id, 1, true);

        // Create environments with specific display order
        Environment__c env1 = TestDataFactory.createEnvironment('Dev', 'Development', 1, true);
        Environment__c env2 = TestDataFactory.createEnvironment('QA', 'QA', 2, true);
        Environment__c env3 = TestDataFactory.createEnvironment('Stage', 'Staging', 3, true);
        Environment__c env4 = TestDataFactory.createEnvironment('Prod', 'Production', 4, true);

        List<Environment__c> environments = new List<Environment__c>{ env1, env2, env3, env4 };
        Map<Id, Deployment__c> deploymentMap = new Map<Id, Deployment__c>();

        Test.startTest();
        TimelineBuilder builder = new TimelineBuilder()
            .withPullRequest(pr)
            .withEnvironments(environments)
            .withDeployments(deploymentMap);

        List<TimelineBuilder.Milestone> milestones = builder.build();
        Test.stopTest();

        // Verify ordering
        System.assertEquals(6, milestones.size());
        System.assertEquals(1, milestones[0].order, 'Created should be order 1');
        System.assertEquals(2, milestones[1].order, 'Merged should be order 2');
        System.assertEquals(3, milestones[2].order, 'Dev should be order 3');
        System.assertEquals(4, milestones[3].order, 'QA should be order 4');
        System.assertEquals(5, milestones[4].order, 'Stage should be order 5');
        System.assertEquals(6, milestones[5].order, 'Prod should be order 6');
    }
}
