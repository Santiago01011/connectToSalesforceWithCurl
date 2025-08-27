#!/usr/bin/env bash

# === CONFIGURATION ===
CLIENT_ID=$CLIENT_ID
CLIENT_SECRET=$CLIENT_SECRET
LOGIN_URL="https://login.salesforce.com"
REDIRECT_URI="https://login.salesforce.com/services/oauth2/success"
TOKEN_FILE="sf_tokens_conn_app.json"

function show_tokens_and_test_api() {
    local access_token="$1"
    local refresh_token="$2"
    local instance_url="$3"

    echo "✅ Access token obtained!"
    echo "Access Token: $access_token"
    echo "Refresh Token: $refresh_token"
    echo "Instance URL: $instance_url"

    # === SAMPLE API CALL (e.g., query Contacts) === 
    SOQL="SELECT+Id+FROM+Contact+LIMIT+5"
    API_RESPONSE=$(curl -s \
      --request GET \
      --url "$instance_url/services/data/v64.0/query/?q=$SOQL" \
      --header "Authorization: Bearer $access_token")
    echo "📄 API Response:"
    echo "$API_RESPONSE"
}

# Check for existing refresh token
if [[ -f "$TOKEN_FILE" ]]; then
    REFRESH_TOKEN=$(grep -o '"refresh_token":"[^"]*"' "$TOKEN_FILE" | sed 's/.*:"//;s/"$//')
    if [[ -n "$REFRESH_TOKEN" && "$REFRESH_TOKEN" != "null" ]]; then
        echo "🔄 Found existing refresh token, attempting to get new access token..."
        RESPONSE=$(curl -s -X POST "$LOGIN_URL/services/oauth2/token" \
            -d "grant_type=refresh_token" \
            -d "client_id=$CLIENT_ID" \
            -d "client_secret=$CLIENT_SECRET" \
            -d "refresh_token=$REFRESH_TOKEN")

        ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/.*:"//;s/"$//')
        INSTANCE_URL=$(echo "$RESPONSE" | grep -o '"instance_url":"[^"]*"' | sed 's/.*:"//;s/"$//')

        if [[ -n "$ACCESS_TOKEN" && "$ACCESS_TOKEN" != "null" ]]; then
            echo "✅ Access token refreshed!"
            echo "Instance URL: $INSTANCE_URL"
            show_tokens_and_test_api "$ACCESS_TOKEN" "$REFRESH_TOKEN" "$INSTANCE_URL"
            exit 0
        else
            echo "⚠️ Refresh failed, proceeding with full login..."
        fi
    fi
fi

# Step 1: Authorization URL
AUTH_URL="$LOGIN_URL/services/oauth2/authorize?response_type=code&client_id=$CLIENT_ID&redirect_uri=$REDIRECT_URI&scope=refresh_token%20api"

echo
echo "🔐 OAuth 2.0 Authorization Code Flow"
echo "------------------------------------"
echo "1️⃣ Open this URL in your browser and log in:"
echo "$AUTH_URL"
echo
echo "2️⃣ After login, you will be redirected to:"
echo "$REDIRECT_URI?code=AUTH_CODE_HERE"
echo "Copy the 'code' parameter from the URL and paste it below."
echo

read -p "Enter the authorization code: " AUTH_CODE

if [[ -z "$AUTH_CODE" ]]; then
    echo "❌ No authorization code provided. Exiting."
    exit 1
fi

# Step 2: Exchange code for access token
RESPONSE=$(curl -s -X POST "$LOGIN_URL/services/oauth2/token" \
    -d "grant_type=authorization_code" \
    -d "code=$AUTH_CODE" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -d "redirect_uri=$REDIRECT_URI")

ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/.*:"//;s/"$//')
REFRESH_TOKEN=$(echo "$RESPONSE" | grep -o '"refresh_token":"[^"]*"' | sed 's/.*:"//;s/"$//')
INSTANCE_URL=$(echo "$RESPONSE" | grep -o '"instance_url":"[^"]*"' | sed 's/.*:"//;s/"$//')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
    echo "❌ Failed to get access token. Response:"
    echo "$RESPONSE"
    exit 1
fi

# Save refresh token for next run
echo "$RESPONSE" > "$TOKEN_FILE"


# Call the function with the obtained tokens
show_tokens_and_test_api "$ACCESS_TOKEN" "$REFRESH_TOKEN" "$INSTANCE_URL"
