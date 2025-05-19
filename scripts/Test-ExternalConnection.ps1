# External Server Connectivity Test Script (PowerShell)
# 
# Script to test external connectivity to a deployed backend server
# Useful for checking if your Oracle Cloud backend is accessible from outside

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerUrl
)

# Display header
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "External Server Connectivity Test" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Testing connection to: $ServerUrl" -ForegroundColor Yellow
Write-Host "Started at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan

# Extract domain from URL
$domain = $ServerUrl -replace "^https?://([^/]+).*$", '$1'
Write-Host "`n[1] Basic connectivity check for domain: $domain" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
try {
    $pingResult = Test-Connection -ComputerName $domain -Count 4 -ErrorAction Stop
    $pingResult | Format-Table Address, IPV4Address, ResponseTime
} catch {
    Write-Host "Ping failed: $_" -ForegroundColor Red
}

# DNS resolution check
Write-Host "`n[2] DNS resolution check" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
try {
    $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
    $dnsResult | Format-Table Name, Type, IPAddress
} catch {
    Write-Host "DNS resolution failed: $_" -ForegroundColor Red
}

# HTTP accessibility check
Write-Host "`n[3] HTTP accessibility check" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
try {
    $webRequest = Invoke-WebRequest -Uri $ServerUrl -Method HEAD -UseBasicParsing -TimeoutSec 10
    Write-Host "Status code: $($webRequest.StatusCode) $($webRequest.StatusDescription)" -ForegroundColor Green
    Write-Host "Content type: $($webRequest.Headers['Content-Type'])"
    Write-Host "Server: $($webRequest.Headers['Server'])"
} catch {
    Write-Host "HTTP request failed: $_" -ForegroundColor Red
}

# Status endpoint check
Write-Host "`n[4] API status endpoint check" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
$statusUrl = "$ServerUrl/api/status"
try {
    $statusRequest = Invoke-RestMethod -Uri $statusUrl -TimeoutSec 10
    Write-Host "Status endpoint response:" -ForegroundColor Green
    $statusRequest | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Status endpoint request failed: $_" -ForegroundColor Red
}

# Trace route check
Write-Host "`n[5] Network route check" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
try {
    $traceRoute = Test-NetConnection -ComputerName $domain -TraceRoute
    $traceRoute | Format-List
} catch {
    Write-Host "Trace route failed: $_" -ForegroundColor Red
}

# Connection latency check
Write-Host "`n[6] Connection latency check (5 requests)" -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor DarkGray
for ($i = 1; $i -le 5; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $null = Invoke-WebRequest -Uri $ServerUrl -Method HEAD -UseBasicParsing -TimeoutSec 5
        $stopwatch.Stop()
        Write-Host "Request $i: Status OK, Time: $($stopwatch.ElapsedMilliseconds) ms" -ForegroundColor Green
    } catch {
        $stopwatch.Stop()
        Write-Host "Request $i: Failed after $($stopwatch.ElapsedMilliseconds) ms - $_" -ForegroundColor Red
    }
    Start-Sleep -Seconds 1
}

# Test SSL certificate if HTTPS
if ($ServerUrl -match "^https://") {
    Write-Host "`n[7] SSL Certificate check" -ForegroundColor Green
    Write-Host "---------------------------------------------" -ForegroundColor DarkGray
    try {
        $certificate = Invoke-Command {
            [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
            $req = [Net.HttpWebRequest]::Create($ServerUrl)
            $req.GetResponse().Dispose()
            $certificate = $req.ServicePoint.Certificate
            [Net.ServicePointManager]::ServerCertificateValidationCallback = $null
            return $certificate
        }

        if ($certificate) {
            Write-Host "Certificate Information:" -ForegroundColor Green
            Write-Host "  Subject: $($certificate.Subject)"
            Write-Host "  Issuer: $($certificate.Issuer)"
            Write-Host "  Valid From: $($certificate.GetEffectiveDateString())"
            Write-Host "  Valid To: $($certificate.GetExpirationDateString())"
            
            $now = Get-Date
            $expiry = [datetime]::Parse($certificate.GetExpirationDateString())
            $daysToExpiry = ($expiry - $now).Days
            
            if ($daysToExpiry -lt 30) {
                Write-Host "  WARNING: Certificate expires in $daysToExpiry days!" -ForegroundColor Yellow
            } else {
                Write-Host "  Certificate expires in $daysToExpiry days" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "SSL Certificate check failed: $_" -ForegroundColor Red
    }
}

Write-Host "`n=============================================" -ForegroundColor Cyan
Write-Host "Test completed at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Cyan
