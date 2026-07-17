/**
 * @description Test data factory for creating test records
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
public class TestDataFactory {

    /**
     * @description Create test repository
     */
    public static Repository__c createRepository(String name, String externalId, Boolean doInsert) {
        Repository__c repo = new Repository__c(
            Name = name,
            External_Id__c = externalId,
            Provider__c = 'GitHub',
            Owner__c = 'test-owner',
            Default_Branch__c = 'main',
            Repository_URL__c = 'https://github.com/test-owner/' + name,
            Description__c = 'Test repository',
            Active__c = true
        );

        if (doInsert) {
            insert repo;
        }

        return repo;
    }

    /**
     * @description Create multiple test repositories
     */
    public static List<Repository__c> createRepositories(Integer count, Boolean doInsert) {
        List<Repository__c> repos = new List<Repository__c>();

        for (Integer i = 0; i < count; i++) {
            repos.add(createRepository('TestRepo' + i, 'ext-repo-' + i, false));
        }

        if (doInsert) {
            insert repos;
        }

        return repos;
    }

    /**
     * @description Create test pull request
     */
    public static Pull_Request__c createPullRequest(Id repositoryId, Integer prNumber, String state, Boolean doInsert) {
        Pull_Request__c pr = new Pull_Request__c(
            PR_Number__c = prNumber,
            External_Id__c = 'ext-pr-' + prNumber,
            Repository__c = repositoryId,
            Title__c = 'Test PR ' + prNumber,
            Author__c = 'test-author',
            State__c = state,
            Source_Branch__c = 'feature/test',
            Target_Branch__c = 'main',
            Created_Date__c = Datetime.now().addDays(-5),
            URL__c = 'https://github.com/test/repo/pull/' + prNumber
        );

        if (state == 'Merged') {
            pr.Merged_Date__c = Datetime.now().addDays(-1);
        } else if (state == 'Closed') {
            pr.Closed_Date__c = Datetime.now().addDays(-1);
        }

        if (doInsert) {
            insert pr;
        }

        return pr;
    }

    /**
     * @description Create multiple test pull requests
     */
    public static List<Pull_Request__c> createPullRequests(Id repositoryId, Integer count, Boolean doInsert) {
        List<Pull_Request__c> prs = new List<Pull_Request__c>();

        for (Integer i = 0; i < count; i++) {
            String state = Math.mod(i, 3) == 0 ? 'Open' : (Math.mod(i, 3) == 1 ? 'Merged' : 'Closed');
            prs.add(createPullRequest(repositoryId, i + 1, state, false));
        }

        if (doInsert) {
            insert prs;
        }

        return prs;
    }

    /**
     * @description Create test environment
     */
    public static Environment__c createEnvironment(String name, String envType, Boolean doInsert) {
        Environment__c env = new Environment__c(
            Name = name,
            Environment_Type__c = envType,
            Active__c = true
        );

        if (doInsert) {
            insert env;
        }

        return env;
    }

    /**
     * @description Create test deployment
     */
    public static Deployment__c createDeployment(Id prId, Id envId, String status, Boolean doInsert) {
        Deployment__c dep = new Deployment__c(
            Pull_Request__c = prId,
            Environment__c = envId,
            Status__c = status,
            Deployment_Type__c = 'Manual',
            Start_Time__c = Datetime.now().addHours(-1),
            End_Time__c = Datetime.now()
        );

        if (doInsert) {
            insert dep;
        }

        return dep;
    }

    /**
     * @description Create test contributor
     */
    public static Contributor__c createContributor(String username, String externalId, Boolean doInsert) {
        Contributor__c contrib = new Contributor__c(
            Name = username,
            External_Id__c = externalId,
            GitHub_Username__c = username,
            Email__c = username + '@test.com',
            Active__c = true
        );

        if (doInsert) {
            insert contrib;
        }

        return contrib;
    }

    /**
     * @description Create mock GitHub repository data
     */
    public static Map<String, Object> createMockGitHubRepoData(String name, Integer id) {
        Map<String, Object> repoData = new Map<String, Object>{
            'id' => id,
            'name' => name,
            'full_name' => 'test-owner/' + name,
            'default_branch' => 'main',
            'html_url' => 'https://github.com/test-owner/' + name,
            'description' => 'Test repository',
            'owner' => new Map<String, Object>{
                'login' => 'test-owner',
                'id' => 12345
            }
        };

        return repoData;
    }

    /**
     * @description Create mock GitHub PR data
     */
    public static Map<String, Object> createMockGitHubPRData(Integer prNumber, Integer id, String state) {
        Map<String, Object> prData = new Map<String, Object>{
            'id' => id,
            'number' => prNumber,
            'title' => 'Test PR ' + prNumber,
            'state' => state.toLowerCase(),
            'html_url' => 'https://github.com/test/repo/pull/' + prNumber,
            'created_at' => '2026-01-01T10:00:00Z',
            'user' => new Map<String, Object>{
                'login' => 'test-author',
                'id' => 54321
            },
            'head' => new Map<String, Object>{
                'ref' => 'feature/test'
            },
            'base' => new Map<String, Object>{
                'ref' => 'main'
            },
            'commits' => 5,
            'changed_files' => 3,
            'additions' => 100,
            'deletions' => 20
        };

        if (state.toLowerCase() == 'merged') {
            prData.put('merged_at', '2026-01-05T10:00:00Z');
        } else if (state.toLowerCase() == 'closed') {
            prData.put('closed_at', '2026-01-05T10:00:00Z');
        }

        return prData;
    }
}
