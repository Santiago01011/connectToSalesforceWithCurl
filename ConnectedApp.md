# Salesforce Authentication with Connected App (Auth Code + Refresh Token Flow)

## Goal

Enable an external script or service to authenticate with Salesforce **on behalf of a user**, using **OAuth 2.0 Authorization Code Flow** with refresh tokens.

* First run requires a **manual login + copy-paste of the authorization code**.
* After that, the script uses the stored refresh token to get new access tokens automatically.

---

## 🛠️ Steps

### 1. Create a Connected App in Salesforce

From **Setup → Apps -> External Client Apps -> Settings**:
   * **Click: Switch creation of connected apps to On**
   * **Click: Enable**
   * **Click: New Connected App**
* **Basic Information**
   Fill the required fields:
  * Name
  * API Name: auto-filled
  * Contact Email

* **Enable OAuth Settings** ✅

  * **Callback URL**:

    ```
    https://login.salesforce.com/services/oauth2/success
    ```
    Or
    ```
    https://test.salesforce.com/services/oauth2/success
    ```
    if you are using a sandbox org.

    (used only for browser redirect, the script extracts the `code` manually).
* **Selected OAuth Scopes**:

   * `Access Interaction API resources (interaction_api)`
   * `Access the Salesforce API Platform (sfap_api)`
   * `Access the identity URL service (id, profile, email, address, phone)`
   * `Manage user data via APIs (api)`
   * `Perform requests at any time (refresh_token, offline_access)`

   **Disable PKCE**
   * **Enable OAuth Flows**:
      * **Authorization Code Flow**: Check "Require Secret for Web Server Flow".
      * **Client Credentials Flow**: Check "Enable Client Credentials Flow".

* Save → wait a few minutes (5-10) for propagation.

---

### 2. Gather OAuth Details

You’ll need:

* **Consumer Key** → `$CLIENT_ID`
* **Consumer Secret** → `$CLIENT_SECRET`
* **Login URL** →

  * Prod: `https://login.salesforce.com`
  * Sandbox: `https://test.salesforce.com`
* **Redirect URI** → must match the one defined in the Connected App

---

### 3. Run the Script

The script (`connectOAuth_ConnectedApp.sh`) follows this logic:

#### 🔑 First Run (manual login required):

1. Script prints an **Authorization URL**, e.g.:

   ```
   https://login.salesforce.com/services/oauth2/authorize?response_type=code&client_id=...&redirect_uri=https://login.salesforce.com/services/oauth2/success&scope=refresh_token%20api
   ```
2. Open the URL in a browser, login, and Salesforce redirects to:

   ```
   https://login.salesforce.com/services/oauth2/success?code=AUTH_CODE_HERE
   ```
3. Copy the `code` value and paste it back into the script.
4. Script exchanges it for:

   * **Access Token**
   * **Refresh Token** (saved in `sf_tokens_conn_app.json`)

#### 🔄 Subsequent Runs (automatic refresh):

* If `sf_tokens_conn_app.json` exists, the script uses the **refresh token** to request a new access token without requiring login.

---

### 5. Test API Call

The script also runs a **sample SOQL query**:

```sql
SELECT Id FROM Contact LIMIT 5
```

It uses the obtained `access_token` against the org’s `instance_url`, confirming everything works.

---