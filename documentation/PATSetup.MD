# DevOps Compass - GitHub PAT and Salesforce Connection Setup (Story 1)

This guide captures the manual steps to connect GitHub to your Salesforce sandbox using a Personal Access Token (PAT), External Credential, and Named Credential.

## Prerequisites

- You can log in to GitHub.
- You can log in to the target Salesforce sandbox.
- Story 0 metadata is already deployed (including `GitHubApiClient`).

---

## 1) Create a GitHub Personal Access Token

### GitHub Navigation

1. Go to [https://github.com](https://github.com) and sign in.
2. Click your profile photo (top-right) -> **Settings**.
3. In the left sidebar (near bottom), click **Developer settings**.
4. Click **Personal access tokens** -> **Tokens (classic)**.
5. Click **Generate new token** -> **Generate new token (classic)**.

### Token Configuration

1. **Note**: `DevOps Compass - Salesforce Sandbox`
2. **Expiration**: choose your preferred duration (example: 90 days).
3. Select these scopes:
   - `repo`
   - `read:org`
   - `read:user`
   - `user:email`
4. Click **Generate token**.
5. Copy the token immediately and store it securely.

Note: You will paste this value into Salesforce in Step 3.

---

## 2) Create External Credential in Salesforce

### Salesforce Navigation

1. Log in to your Salesforce sandbox.
2. Click the gear icon (top-right) -> **Setup**.
3. In **Quick Find**, search: `Named Credentials`.
4. Click **Named Credentials** (under Security).
5. Open the **External Credentials** tab.
6. Click **New**.

### External Credential Values

- **Label**: `GitHub API Credential`
- **Name**: auto-populated (leave default unless needed)
- **Authentication Protocol**: `Custom`

Click **Save**.

---

## 3) Add Principal and PAT to External Credential

### Salesforce Navigation

1. Open the `GitHub API Credential` record you just created.
2. Scroll to the **Principals** section.
3. Click **New**.

### Principal Values

- **Parameter Name**: `Authorization`
- **Sequence Number**: `1`
- **Identity Type**: `Named Principal`
- **Authentication Parameter Type** (or similarly named field): `Custom`

Click **Save**.

### Add PAT Value

1. Open/edit the new principal.
2. In authentication parameter value, enter:

`token YOUR_GITHUB_TOKEN_HERE`

3. Click **Save**.

Important: include the word `token` followed by one space, then your PAT.

---

## 4) Create Named Credential for GitHub API

### Salesforce Navigation

1. Go to **Setup** -> **Named Credentials**.
2. Open the **Named Credentials** tab.
3. Click **New** (or **New Legacy** if that is what your org/project expects).

### Named Credential Values

- **Label**: `GitHub API`
- **Name**: `GitHub_API` (or default auto-populated value)
- **URL**: `https://api.github.com`
- **Identity Type**: `Named Principal`
- **Authentication Protocol**: `Custom`
- **External Credential**: `GitHub API Credential`
- **Generate Authorization Header**: checked
- **Allow Merge Fields in HTTP Header**: checked
- **Allow Merge Fields in HTTP Body**: checked

Click **Save**.

---

## 5) Grant External Credential Access in Permission Set

### Salesforce Navigation

1. In Setup **Quick Find**, search `Permission Sets`.
2. Click **Permission Sets**.
3. Open **DevOps Compass Administrator**.
4. Scroll to **External Credential Principal Access**.
5. Click **Edit**.
6. Move `GitHub_API_Credential` (or `GitHub API Credential`) from Available to Enabled.
7. Click **Save**.

---

## 6) Assign Permission Set to Your User (If Needed)

### Salesforce Navigation

1. In Setup **Quick Find**, search `Users`.
2. Click **Users**.
3. Open your user record.
4. Scroll to **Permission Set Assignments**.
5. Click **Edit Assignments**.
6. Add **DevOps Compass Administrator**.
7. Click **Save**.

---

## 7) Create Repository Configuration Records

### Salesforce Navigation

1. In Setup **Quick Find**, search `Custom Metadata Types`.
2. Click **Custom Metadata Types**.
3. Find **Repository Config**.
4. Click **Manage Records**.
5. Click **New**.

### Repository Config Values (Minimum)

- **Label**: friendly display name
- **Repository Config Name**: API-safe name (no spaces)
- **Repository Name**: exact GitHub repository name
- **Provider**: `GitHub`
- **Repository Owner**: GitHub org or username
- **Sync Enabled**: checked
- **Default Branch**: typically `main`

Click **Save**. Repeat for each repository.

---

## 8) Validate the Connection with Execute Anonymous

### Salesforce Navigation

1. Click gear icon -> **Developer Console**.
2. In Developer Console, click **Debug** -> **Open Execute Anonymous Window**.
3. Paste the script below.
4. Ensure **Open Log** is checked.
5. Click **Execute**.

### Debug Script

```apex
try {
    // Uses Named Credential callout:GitHub_API behind GitHubApiClient
    HttpResponse res = GitHubApiClient.get('/rate_limit');

    System.debug('=== GitHub Connectivity Test ===');
    System.debug('Status Code: ' + res.getStatusCode());
    System.debug('Status: ' + res.getStatus());
    System.debug('Body: ' + res.getBody());

    if (res.getStatusCode() == 200) {
        System.debug('SUCCESS: GitHub connection is working.');
    } else {
        System.debug('WARNING: Unexpected status code returned.');
    }
} catch (Exception e) {
    System.debug('ERROR TYPE: ' + e.getTypeName());
    System.debug('ERROR MESSAGE: ' + e.getMessage());
    System.debug('STACK TRACE: ' + e.getStackTraceString());
}
```

### Expected Success Result

- `Status Code: 200`
- Response body contains GitHub rate limit JSON
- Debug line includes: `SUCCESS: GitHub connection is working.`

---

## Troubleshooting Quick Notes

- 401 Unauthorized: verify PAT scopes and token format (`token <PAT>`).
- Named Credential errors: confirm URL is `https://api.github.com` and External Credential is linked.
- Permission/access errors: confirm principal access is enabled in `DevOps Compass Administrator`.

---

## Story Tracking

- Story: **Story 1 - GitHub Integration Setup**
- Status: **PAT setup and connectivity test documented**
