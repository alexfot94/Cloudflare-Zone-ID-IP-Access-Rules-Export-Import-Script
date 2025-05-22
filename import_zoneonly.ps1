# === Config: Import ===
$headers = @{
  "X-Auth-Email" = "your-email@example.com"
    "X-Auth-Key"   = "your-global-api-key"
    "Content-Type" = "application/json"
}
$targetZoneId      = "89fa72e0fd503e242065f9c5ed4955bb"
$jsonFile          = "$env:USERPROFILE\Desktop\zone_ip_access_rules.json"
$logFile           = "$env:USERPROFILE\Desktop\imported_ips.log"
$successListFile   = "$env:USERPROFILE\Desktop\import_success_summary.txt"
$failListFile      = "$env:USERPROFILE\Desktop\import_failed_summary.txt"

# === Load previous success log ===
$importedIPs = @()
if (Test-Path $logFile) {
    $importedIPs = Get-Content $logFile
}

# === Load rules to import ===
if (-Not (Test-Path $jsonFile)) {
    Write-Host "File not found: $jsonFile" -ForegroundColor Red
    exit 1
}

$rules = Get-Content -Raw -Path $jsonFile | ConvertFrom-Json
$total = $rules.Count
$successfullyImported = @()
$failedImports = @()

Write-Host "`nStarting import of $total IP access rule(s)..." -ForegroundColor Cyan

# === Import loop ===
$counter = 0
foreach ($rule in $rules) {
    $counter++
    $ip = $rule.configuration.value

    Write-Progress -Activity "Importing Rules" -Status "Processing $counter of $total" -PercentComplete (($counter / $total) * 100)

    if ($importedIPs -contains $ip) {
        Write-Host "[$counter/$total] Skipped (already imported): $ip" -ForegroundColor Yellow
        continue
    }

    $payload = @{
        mode = $rule.mode
        configuration = @{
            target = $rule.configuration.target
            value  = $ip
        }
        notes = $rule.notes
    }

    $body = $payload | ConvertTo-Json -Depth 10 -Compress
    $url  = "https://api.cloudflare.com/client/v4/zones/$targetZoneId/firewall/access_rules/rules"

    $success = $false
    $retryCount = 0

    while (-not $success -and $retryCount -lt 10) {
        try {
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body
            Start-Sleep -Milliseconds 300

            if ($response.success -eq $true) {
                $ip | Out-File -FilePath $logFile -Append
                $successfullyImported += $ip
                Write-Host "[$counter/$total] Imported: $ip [$($rule.mode)]" -ForegroundColor Green
                $success = $true
            } else {
                $failedImports += "$ip - API Error"
                Write-Host "[$counter/$total] Failed: $ip - API response not successful" -ForegroundColor Red
                break
            }
        } catch {
            if ($_.Exception.Response.StatusCode.Value__ -eq 429) {
                Write-Host "Rate limit hit. Waiting 60 seconds..." -ForegroundColor DarkYellow
                Start-Sleep -Seconds 60
                $retryCount++
            } else {
                Write-Host ("[$counter/$total] Error importing ${ip}: " + $_.Exception.Message) -ForegroundColor Red

                $failedImports += "$ip - $($_.Exception.Message)"
                break
            }
        }
    }
}

# === Write Success Summary ===
$summary = @()
$summary += "Total successfully imported IPs: $($successfullyImported.Count)"
$summary += ""
$summary += $successfullyImported
$summary | Out-File -Encoding utf8 $successListFile
Write-Host "`nSuccess list saved to: $successListFile" -ForegroundColor Green

# === Write Failed Summary ===
$fails = @()
$fails += "Total failed IPs: $($failedImports.Count)"
$fails += ""
$fails += $failedImports
$fails | Out-File -Encoding utf8 $failListFile
Write-Host "Failed list saved to: $failListFile" -ForegroundColor Yellow
