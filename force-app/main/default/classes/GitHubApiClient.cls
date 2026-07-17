/**
 * @description GitHub API client for making authenticated HTTP requests
 * @author DevOps Compass Team
 * @date 2026
 */
public with sharing class GitHubApiClient {

    private static final String NAMED_CREDENTIAL = 'callout:GitHub_API';
    private static final String API_VERSION = 'application/vnd.github.v3+json';

    /**
     * @description Make GET request to GitHub API
     * @param endpoint API endpoint (e.g., '/repos/owner/repo')
     * @return HttpResponse
     */
    public static HttpResponse get(String endpoint) {
        return makeRequest('GET', endpoint, null);
    }

    /**
     * @description Make POST request to GitHub API
     * @param endpoint API endpoint
     * @param body Request body as JSON string
     * @return HttpResponse
     */
    public static HttpResponse post(String endpoint, String body) {
        return makeRequest('POST', endpoint, body);
    }

    /**
     * @description Make PATCH request to GitHub API
     * @param endpoint API endpoint
     * @param body Request body as JSON string
     * @return HttpResponse
     */
    public static HttpResponse patch(String endpoint, String body) {
        return makeRequest('PATCH', endpoint, body);
    }

    /**
     * @description Make HTTP request to GitHub API
     * @param method HTTP method (GET, POST, PATCH, etc.)
     * @param endpoint API endpoint
     * @param body Request body (can be null)
     * @return HttpResponse
     */
    private static HttpResponse makeRequest(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(NAMED_CREDENTIAL + endpoint);
        req.setHeader('Accept', API_VERSION);
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(120000); // 2 minutes

        if (String.isNotBlank(body)) {
            req.setBody(body);
        }

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() >= 400) {
            throw new GitHubApiException(
                'GitHub API returned error: ' + res.getStatus(),
                res.getStatusCode(),
                res.getBody()
            );
        }

        return res;
    }

    /**
     * @description Parse JSON response to Map
     * @param response HttpResponse
     * @return Map<String, Object>
     */
    public static Map<String, Object> parseResponse(HttpResponse response) {
        String responseBody = response.getBody();
        if (String.isBlank(responseBody)) {
            return new Map<String, Object>();
        }
        return (Map<String, Object>) JSON.deserializeUntyped(responseBody);
    }

    /**
     * @description Parse JSON response to List
     * @param response HttpResponse
     * @return List<Object>
     */
    public static List<Object> parseResponseList(HttpResponse response) {
        String responseBody = response.getBody();
        if (String.isBlank(responseBody)) {
            return new List<Object>();
        }
        return (List<Object>) JSON.deserializeUntyped(responseBody);
    }

    /**
     * @description Get repository information
     * @param owner Repository owner
     * @param repoName Repository name
     * @return Map<String, Object> Repository data
     */
    public static Map<String, Object> getRepository(String owner, String repoName) {
        String endpoint = '/repos/' + owner + '/' + repoName;
        HttpResponse response = get(endpoint);
        return parseResponse(response);
    }

    /**
     * @description Get pull requests for a repository
     * @param owner Repository owner
     * @param repoName Repository name
     * @param state PR state (open, closed, all)
     * @param perPage Results per page (max 100)
     * @param page Page number
     * @return List<Object> Pull requests
     */
    public static List<Object> getPullRequests(String owner, String repoName, String state, Integer perPage, Integer page) {
        String endpoint = '/repos/' + owner + '/' + repoName + '/pulls';
        endpoint += '?state=' + state;
        endpoint += '&per_page=' + perPage;
        endpoint += '&page=' + page;

        HttpResponse response = get(endpoint);
        return parseResponseList(response);
    }

    /**
     * @description Get single pull request details
     * @param owner Repository owner
     * @param repoName Repository name
     * @param prNumber PR number
     * @return Map<String, Object> Pull request data
     */
    public static Map<String, Object> getPullRequest(String owner, String repoName, Integer prNumber) {
        String endpoint = '/repos/' + owner + '/' + repoName + '/pulls/' + prNumber;
        HttpResponse response = get(endpoint);
        return parseResponse(response);
    }

    /**
     * @description Get commits for a repository
     * @param owner Repository owner
     * @param repoName Repository name
     * @param since ISO 8601 date to filter commits
     * @param perPage Results per page
     * @param page Page number
     * @return List<Object> Commits
     */
    public static List<Object> getCommits(String owner, String repoName, String since, Integer perPage, Integer page) {
        String endpoint = '/repos/' + owner + '/' + repoName + '/commits';
        endpoint += '?per_page=' + perPage;
        endpoint += '&page=' + page;

        if (String.isNotBlank(since)) {
            endpoint += '&since=' + since;
        }

        HttpResponse response = get(endpoint);
        return parseResponseList(response);
    }

    /**
     * @description Get contributors for a repository
     * @param owner Repository owner
     * @param repoName Repository name
     * @param perPage Results per page
     * @param page Page number
     * @return List<Object> Contributors
     */
    public static List<Object> getContributors(String owner, String repoName, Integer perPage, Integer page) {
        String endpoint = '/repos/' + owner + '/' + repoName + '/contributors';
        endpoint += '?per_page=' + perPage;
        endpoint += '&page=' + page;

        HttpResponse response = get(endpoint);
        return parseResponseList(response);
    }

    /**
     * @description Check rate limit status
     * @return Map<String, Object> Rate limit info
     */
    public static Map<String, Object> getRateLimit() {
        HttpResponse response = get('/rate_limit');
        return parseResponse(response);
    }
}
