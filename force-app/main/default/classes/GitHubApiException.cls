/**
 * @description Exception class for GitHub API errors
 * @author DevOps Compass Team
 * @date 2026
 */
public class GitHubApiException extends DevOpsCompassException {
    public Integer statusCode { get; set; }
    public String responseBody { get; set; }

    public GitHubApiException(String message, Integer statusCode, String responseBody) {
        this.setMessage(message);
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }
}
