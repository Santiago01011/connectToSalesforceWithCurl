#!/usr/bin/env bash

# === CONFIGURATION ===
CLIENT_ID=$CLIENT_ID_EXTERNAL
CLIENT_SECRET=$CLIENT_SECRET_EXTERNAL
TOKEN_URL=$EXTERNAL_CLIENT_TOKEN_URL
TOKEN_FILE=sf_tokens_ext_client.json

# Request Access Token using Client Credentials flow
echo "🔄 Requesting Access Token via Client Credentials Flow..."
RESPONSE=$(curl -s -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=client_credentials" \
    -d "client_id=$CLIENT_ID" \
    -d "client_secret=$CLIENT_SECRET" \
    -w "\nHTTP_STATUS:%{http_code}")

# Extract HTTP status
HTTP_STATUS=$(echo "$RESPONSE" | grep HTTP_STATUS | sed 's/.*HTTP_STATUS://')
BODY=$(echo "$RESPONSE" | sed 's/HTTP_STATUS:.*//')

# Parse token
ACCESS_TOKEN=$(echo "$RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/.*:"//;s/"$//')
INSTANCE_URL=$(echo "$RESPONSE" | grep -o '"instance_url":"[^"]*"' | sed 's/.*:"//;s/"$//')

echo "{\"access_token\": \"$ACCESS_TOKEN\", \"instance_url\": \"$INSTANCE_URL\"}" > "$TOKEN_FILE"

cat "$TOKEN_FILE"
