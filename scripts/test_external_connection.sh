#!/bin/bash
# External Server Connectivity Test Script

# Usage instructions
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <server_url>"
    echo "Example: $0 https://your-server.com"
    exit 1
fi

SERVER_URL=$1
TIMEOUT=5

echo "=============================================="
echo "External Server Connectivity Test"
echo "=============================================="
echo "Testing connection to: $SERVER_URL"
echo "Timeout: $TIMEOUT seconds"
echo "Started at: $(date)"
echo "=============================================="

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Basic connectivity check with ping (if URL is domain rather than IP)
DOMAIN=$(echo $SERVER_URL | sed -E 's#^https?://([^/]+).*$#\1#')
echo -e "\n[1] Basic connectivity check for domain: $DOMAIN"
echo "--------------------------------------------"
if command_exists ping; then
    ping -c 4 $DOMAIN
else
    echo "Ping command not found. Skipping ping test."
fi

# DNS resolution check
echo -e "\n[2] DNS resolution check"
echo "--------------------------------------------"
if command_exists dig; then
    dig +short $DOMAIN
elif command_exists nslookup; then
    nslookup $DOMAIN
else
    echo "Neither dig nor nslookup found. Skipping DNS check."
fi

# HTTP accessibility check
echo -e "\n[3] HTTP accessibility check"
echo "--------------------------------------------"
if command_exists curl; then
    echo "Using curl:"
    curl -I --connect-timeout $TIMEOUT $SERVER_URL
elif command_exists wget; then
    echo "Using wget:"
    wget --spider --timeout=$TIMEOUT -S "$SERVER_URL" 2>&1
else
    echo "Neither curl nor wget found. Skipping HTTP check."
fi

# Status endpoint check
echo -e "\n[4] API status endpoint check"
echo "--------------------------------------------"
STATUS_URL="$SERVER_URL/api/status"
if command_exists curl; then
    echo "Status endpoint response:"
    curl -s --connect-timeout $TIMEOUT $STATUS_URL | json_pp || echo "Failed to connect to status endpoint"
else
    echo "Curl not found. Skipping status endpoint check."
fi

# Trace route check
echo -e "\n[5] Network route check"
echo "--------------------------------------------"
if command_exists traceroute; then
    traceroute -m 15 $DOMAIN
elif command_exists tracepath; then
    tracepath $DOMAIN
else
    echo "Neither traceroute nor tracepath found. Skipping route check."
fi

# Connection latency check
echo -e "\n[6] Connection latency check (5 requests)"
echo "--------------------------------------------"
if command_exists curl; then
    for i in {1..5}; do
        time curl -s -o /dev/null -w "Request $i: HTTP Status %{http_code}, Time: %{time_total}s\n" --connect-timeout $TIMEOUT $SERVER_URL
        sleep 1
    done
else
    echo "Curl not found. Skipping latency check."
fi

echo -e "\n=============================================="
echo "Test completed at: $(date)"
echo "=============================================="
