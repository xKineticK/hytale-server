#!/bin/bash
set -e

# Configuration
AUTH_URL="https://oauth.accounts.hytale.com/oauth2/device/auth"
TOKEN_URL="https://oauth.accounts.hytale.com/oauth2/token"
PROFILE_URL="https://account-data.hytale.com/my-account/get-profiles"
SESSION_URL="https://sessions.hytale.com/game-session/new"
CLIENT_ID="hytale-server"
SCOPE="openid offline auth:server"
ENV_FILE=".env"

# Function to load tokens from .env
load_tokens() {
    if [ -f "$ENV_FILE" ]; then
        source "$ENV_FILE"
    fi
}

# Function to save tokens to .env
# Usage: save_token KEY VALUE
save_token() {
    local key=$1
    local value=$2
    # Create or update .env file
    if grep -q "^$key=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^$key=.*|$key=$value|" "$ENV_FILE"
    else
        echo "$key=$value" >> "$ENV_FILE"
    fi
}

# Function to create game session using Access Token
# Returns 0 on success, 1 on failure
create_game_session() {
    local access_token=$1
    local refresh_token=$2
    
    echo "Fetching user profile..." >&2
    local profile_response
    profile_response=$(curl -s -X GET "$PROFILE_URL" \
        -H "Authorization: Bearer $access_token")

    local player_uuid=$(echo "$profile_response" | jq -r '.profiles[0].uuid // empty')

    if [ -z "$player_uuid" ] || [ "$player_uuid" == "null" ]; then
        echo "Error: Could not retrieve player UUID. Response: $profile_response" >&2
        return 1
    fi
    echo "Found user profile: $player_uuid" >&2

    echo "Creating game session..." >&2
    local session_response
    session_response=$(curl -s -X POST "$SESSION_URL" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d "{\"uuid\": \"$player_uuid\"}")
        
    local session_token=$(echo "$session_response" | jq -r '.sessionToken // empty')
    local identity_token=$(echo "$session_response" | jq -r '.identityToken // empty')
    
    if [ -z "$session_token" ] || [ "$session_token" == "null" ]; then
         echo "Error: Could not create game session. Response: $session_response" >&2
         return 1
    fi

    # SUCCESS: Save the actual server tokens + Refresh Token (if changed)
    save_token "HYTALE_SERVER_SESSION_TOKEN" "$session_token"
    save_token "HYTALE_SERVER_IDENTITY_TOKEN" "$identity_token"
    
    if [ -n "$refresh_token" ] && [ "$refresh_token" != "null" ]; then
        save_token "REFRESH_TOKEN" "$refresh_token"
    fi
    
    echo "Game Session Created Successfully!" >&2
    return 0
}

# Function to refresh access token
refresh_access_token() {
    local refresh_token_input=$1
    local response
    
    response=$(curl -s -X POST "$TOKEN_URL" \
        -d "grant_type=refresh_token" \
        -d "client_id=$CLIENT_ID" \
        -d "refresh_token=$refresh_token_input")

    if echo "$response" | grep -q '"error"'; then
        echo "Refresh failed or token expired." >&2
        return 1
    fi

    local access_token=$(echo "$response" | jq -r '.access_token')
    local new_refresh_token=$(echo "$response" | jq -r '.refresh_token')
    
    # Check if we got a new refresh token, otherwise use the old one
    if [ -z "$new_refresh_token" ] || [ "$new_refresh_token" == "null" ]; then
        new_refresh_token="$refresh_token_input"
    fi

    echo "Token Refreshed. Creating Game Session..." >&2
    
    # Now create the game session with the fresh access token
    create_game_session "$access_token" "$new_refresh_token"
}

# START
load_tokens

# 1. Try to reuse existing refresh token to get a new Access Token
if [ -n "$REFRESH_TOKEN" ]; then
    echo "Found existing Refresh Token. Attempting to restore session..." >&2
    if refresh_access_token "$REFRESH_TOKEN"; then
        exit 0
    fi
    echo "Refresh token invalid. Starting new authentication flow." >&2
fi

# 2. Init Device Flow
echo "Initiating Device Code Flow..." >&2
init_response=$(curl -s -X POST "$AUTH_URL" \
    -d "client_id=$CLIENT_ID" \
    -d "scope=$SCOPE")

device_code=$(echo "$init_response" | jq -r '.device_code')
user_code=$(echo "$init_response" | jq -r '.user_code')
verification_uri=$(echo "$init_response" | jq -r '.verification_uri')
verification_uri_complete=$(echo "$init_response" | jq -r '.verification_uri_complete')
interval=$(echo "$init_response" | jq -r '.interval')

echo "" >&2
echo "===================================================================" >&2
echo "   HYTALE SERVER AUTHENTICATION REQUIRED" >&2
echo "===================================================================" >&2
echo "1. Visit: $verification_uri" >&2
echo "2. Alert Code: $user_code" >&2
echo "" >&2
echo " Direct Link: $verification_uri_complete" >&2
echo "===================================================================" >&2
echo "Waiting for authorization..." >&2

# 3. Poll for token
while true; do
    sleep ${interval:-5}
    token_response=$(curl -s -X POST "$TOKEN_URL" \
        -d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
        -d "client_id=$CLIENT_ID" \
        -d "device_code=$device_code")

    error=$(echo "$token_response" | jq -r '.error // empty')
    
    if [ -z "$error" ]; then
        # Success getting OAuth Tokens
        access_token=$(echo "$token_response" | jq -r '.access_token')
        refresh_token=$(echo "$token_response" | jq -r '.refresh_token')
        
        # Create the game session using the access token
        echo "Authorized! Creating Game Session..." >&2
        if create_game_session "$access_token" "$refresh_token"; then
             exit 0
        else
             echo "Failed to create game session after login." >&2
             exit 1
        fi

    elif [ "$error" == "authorization_pending" ]; then
        continue
    elif [ "$error" == "slow_down" ]; then
        interval=$((interval + 5))
    else
        echo "Authentication failed: $error" >&2
        echo "$token_response" >&2
        exit 1
    fi
done
