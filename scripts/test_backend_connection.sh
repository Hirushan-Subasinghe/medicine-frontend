#!/bin/bash
# Simple connectivity test script for the backend

# Replace with your Oracle Cloud server IP or domain name
SERVER_URL="https://your-oracle-cloud-ip-or-domain.com"

echo "Backend Connection Test"
echo "==============================================\n"
echo "Testing connection to: $SERVER_URL"

# Test 1: Simple ping (if not using HTTPS)
if [[ $SERVER_URL == http://* ]]; then
  # Extract host from URL
  HOST=$(echo $SERVER_URL | sed -e 's|http://||' -e 's|/.*||')
  echo "\n[Test 1] Pinging host: $HOST"
  ping -c 4 $HOST
else
  echo "\n[Test 1] Skipping ping test (HTTPS URL)"
fi

# Test 2: Status endpoint
echo "\n[Test 2] Testing backend status endpoint"
curl -i "${SERVER_URL}/api/status"

# Test 3: Measure response time
echo "\n\n[Test 3] Measuring response time (5 requests)"
for i in {1..5}; do
  time curl -s "${SERVER_URL}/api/status" > /dev/null
  sleep 1
done

echo "\nTests complete!"
