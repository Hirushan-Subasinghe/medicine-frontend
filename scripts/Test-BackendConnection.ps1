# Backend connectivity test script
# You can run this script to check if your backend is accessible

# Replace with your Oracle Cloud server IP or domain name
$SERVER_URL = "https://your-oracle-cloud-ip-or-domain.com"

Write-Host "`nBackend Connection Test" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Testing connection to: $SERVER_URL`n"

# Test 1: Simple ping (for HTTP URLs)
if ($SERVER_URL -like "http://*") {
    # Extract host from URL
    $HOST = $SERVER_URL -replace "http://", "" -replace "/.*", ""
    Write-Host "[Test 1] Pinging host: $HOST" -ForegroundColor Yellow
    ping -n 4 $HOST
}
else {
    $HOST = $SERVER_URL -replace "https://", "" -replace "/.*", ""
    Write-Host "[Test 1] Pinging host (note: ping may not work if host doesn't respond to ICMP): $HOST" -ForegroundColor Yellow
    ping -n 4 $HOST
}

# Test 2: Status endpoint
Write-Host "`n[Test 2] Testing backend status endpoint" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$SERVER_URL/api/status" -Method Get -TimeoutSec 10
    Write-Host "Status response:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
}
catch {
    Write-Host "Error accessing status endpoint: $_" -ForegroundColor Red
}

# Test 3: Measure response time
Write-Host "`n[Test 3] Measuring response time (5 requests)" -ForegroundColor Yellow
for ($i = 1; $i -le 5; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $null = Invoke-RestMethod -Uri "$SERVER_URL/api/status" -Method Get -TimeoutSec 5
        $stopwatch.Stop()
        Write-Host "Request $i: $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Green
    }
    catch {
        $stopwatch.Stop()
        Write-Host "Request $i: Failed after $($stopwatch.ElapsedMilliseconds) ms - $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

Write-Host "`nTests complete!" -ForegroundColor Cyan
