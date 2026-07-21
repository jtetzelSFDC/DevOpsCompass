/**
 * @description Mock HTTP callout class for GitHub API testing
 * @author DevOps Compass Team
 * @date 2026
 */
@isTest
public class GitHubApiMock {

    /**
     * @description Mock for repository endpoint
     */
    public class RepositoryMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '{' +
                '"id": 123456,' +
                '"name": "test-repo",' +
                '"full_name": "test-owner/test-repo",' +
                '"owner": {"login": "test-owner"},' +
                '"description": "Test repository",' +
                '"html_url": "https://github.com/test-owner/test-repo",' +
                '"default_branch": "main",' +
                '"private": false' +
            '}';

            res.setBody(body);
            return res;
        }
    }

    /**
     * @description Mock for pull requests list endpoint
     */
    public class PullRequestListMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '[{' +
                '"number": 1,' +
                '"title": "Test PR",' +
                '"state": "open",' +
                '"user": {"login": "testuser"},' +
                '"head": {"ref": "feature-branch"},' +
                '"base": {"ref": "main"},' +
                '"created_at": "2026-01-01T00:00:00Z",' +
                '"merged_at": null,' +
                '"closed_at": null' +
            '}]';

            res.setBody(body);
            return res;
        }
    }

    /**
     * @description Mock for contributors list endpoint
     */
    public class ContributorListMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String body = '[{' +
                '"login": "contributor1",' +
                '"contributions": 50,' +
                '"html_url": "https://github.com/contributor1",' +
                '"avatar_url": "https://avatars.githubusercontent.com/u/123"' +
            '},{' +
                '"login": "contributor2",' +
                '"contributions": 25,' +
                '"html_url": "https://github.com/contributor2",' +
                '"avatar_url": "https://avatars.githubusercontent.com/u/456"' +
            '}]';

            res.setBody(body);
            return res;
        }
    }

    /**
     * @description Mock for error responses
     */
    public class ErrorMock implements HttpCalloutMock {
        private Integer statusCode;
        private String errorMessage;

        public ErrorMock(Integer statusCode, String errorMessage) {
            this.statusCode = statusCode;
            this.errorMessage = errorMessage;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setBody('{"message": "' + errorMessage + '"}');
            return res;
        }
    }
}
