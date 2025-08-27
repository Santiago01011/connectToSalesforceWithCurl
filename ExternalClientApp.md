# 🔑 Salesforce External Client App – OAuth Client Credentials Flow Setup

Guide to enable an external client (outside Salesforce) to authenticate via OAuth 2.0 Client Credentials Flow and make API calls against our Salesforce org without user interaction.

This approach is useful for server-to-server integrations, background jobs, or middleware services that need programmatic access.
---

## ⚙️ Salesforce Configuration (Admin Required)

## Prerequisites

* You have **My Domain** deployed (e.g., `https://your-org.my.salesforce.com`).
* An **integration user context** defined by the app (see “Run As” below).
* You can create/manage **External Client Apps** in Setup.

---

## Create the External Client App

1. **Setup → App Manager → New External Client App**
2. **Basics**
   * Name, Description, Contact Email, Distribution = **Local**.
   * Logo/Icon: optional (cosmetic).
3. **Enable OAuth**
   * ✅ **Enable OAuth**.
   * **Scopes**: include at least `api`.
   * **Callback URL**: **not required** for Client Credentials flow (used by auth-code/PKCE; safe to leave as https://).
4. **Flow Enablement**
   * ✅ **Enable Client Credentials Flow**.
5. **Security (for this use case)**
   * **PKCE**: not required.
   * **Require Secret for Web Server Flow**: irrelevant for client credentials.
   * **Require Secret for Refresh Token Flow**: irrelevant for client credentials.
6. **Click Create**
---

## Enable **Client Credentials Flow** + “Run As”
In Setup -> External Client App Manager -> [your app] -> Policies
   * **Click Edit**
   * **Inside OAuth Policies, under OAuth Flows and External Client App Enhancements**
   * ✅ **Enable Client Credentials Flow**.
   * **Run As (Username)**: pick your **integration user** (or the required one).

  * This user’s **profile/perm sets** control data visibility and API permissions (ensure **API Enabled** and object/field access you need).

## Save and Capture Credentials

* Copy the **Client ID (Consumer Key)** and **Client Secret** from the app.
* You’ll use your **My Domain** as the token endpoint host (see next).

---

## 💻 Developer Implementation

### Environment Setup

Set your credentials as environment variables:

```bash
# Production
export CLIENT_ID_EXTERNAL="3MVG9..." (Consumer Key in Salesforce)
export CLIENT_SECRET_EXTERNAL="1234..." (Consumer Secret in Salesforce)
export EXTERNAL_CLIENT_TOKEN_URL="https://login.salesforce.com/services/oauth2/token"

# Sandbox
export EXTERNAL_CLIENT_TOKEN_URL="https://test.salesforce.com/services/oauth2/token"
```

### Authentication Script

#### Use `connectOAuth_ExternalClientApp.sh`

### Usage Example

```bash
# Make it executable
chmod +x connectOAuth_ExternalClientApp.sh

# Run the script
./connectOAuth_ExternalClientApp.sh

# Use the returned token for API calls
# Token is stored in TOKEN_FILE (default to sf_tokens_ext_client.json, you can change file name in the script)
curl -H "Authorization: Bearer $ACCESS_TOKEN" \
     "$INSTANCE_URL/services/data/v64.0/sobjects/Account" \
     | jq '.recentItems[0]'
```

---

## 🔧 API Integration Examples

### Query Records (SOQL)

```bash
# Query first 5 Accounts
SOQL="SELECT Id, Name FROM Account LIMIT 5"
curl -G -H "Authorization: Bearer $ACCESS_TOKEN" \
     --data-urlencode "q=$SOQL" \
     "$INSTANCE_URL/services/data/v64.0/query/"
```

### Create Record

```bash
curl -X POST \
     -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"Name":"Test Account","Type":"Customer"}' \
     "$INSTANCE_URL/services/data/v64.0/sobjects/Account/"
```

### Update Record (Not allowed by default)

```bash
curl -X PATCH \
     -H "Authorization: Bearer $ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"Name":"Updated Account Name"}' \
     "$INSTANCE_URL/services/data/v64.0/sobjects/Account/$RECORD_ID"
```