# === Cloudflare IP Access Rules Export ===

# Config
$headers = @{
    "X-Auth-Email" = "your-email@example.com"
    "X-Auth-Key"   = "your-global-api-key"
    "Content-Type" = "application/json"
}
$zoneId = "a5f64eed527f2e0ad092b5fe67f9b99c"

$outputJsonFile   = "$env:USERPROFILE\Desktop\zone_ip_access_rules.json"
$successListFile  = "$env:USERPROFILE\Desktop\export_success_summary.txt"
$failedListFile   = "$env:USERPROFILE\Desktop\export_failed_summary.txt"

# Data containers
$allRules = @()
$successIPs = @()
$failedPages = @()

$page = 1
$perPage = 100
$totalPages = 1
$retryCount = 0

Write-Host "`n=== Starting Cloudflare IP Access Rule Export ===" -ForegroundColor Cyan

do {
    $url = "https://api.cloudflare.com/client/v4/zones/$zoneId/firewall/access_rules/rules?page=$page&per_page=$perPage"
    Write-Host "`nRequesting Page $page..." -ForegroundColor Yellow
    Write-Progress -Activity "Exporting Access Rules" -Status "Page $page" -PercentComplete (($page / $totalPages) * 100)

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET

        if ($response -and $response.success -eq $true) {
            if ($response.result.Count -eq 0) {
                Write-Host "No rules found on page $page." -ForegroundColor Gray
            } else {
                Write-Host "Success: Fetched $($response.result.Count) rules from page $page." -ForegroundColor Green
            }

            $allRules += $response.result
            $successIPs += ($response.result | ForEach-Object { $_.configuration.value })
            
            # Only update totalPages if present
            if ($response.result_info -and $response.result_info.total_pages) {
                $totalPages = $response.result_info.total_pages
            } else {
                Write-Host "Warning: No total_pages info found, assuming single page." -ForegroundColor DarkYellow
                $totalPages = 1
            }

            $page++
            $retryCount = 0
        } else {
            Write-Host "API returned unsuccessful response on page $page." -ForegroundColor Red
            $failedPages += "Page $page - API response failure"
            $page++
        }

    } catch {
        $status = $_.Exception.Response.StatusCode.Value__
        Write-Host ("Error on page $page`: " + $_.Exception.Message) -ForegroundColor Red



        if ($status -eq 429) {
            Write-Host "Rate limit hit. Waiting 60 seconds..." -ForegroundColor DarkYellow
            Start-Sleep -Seconds 60
            $retryCount++
        } else {
            $failedPages += "Page $page - Exception: $($_.Exception.Message)"
            $page++
        }
    }

} while ($page -le $totalPages -and $retryCount -lt 10)

# Save results
if ($allRules.Count -gt 0) {
    Write-Host "`nExporting rules to JSON..." -ForegroundColor Cyan
    $allRules | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $outputJsonFile
    Write-Host "Saved $($allRules.Count) rules to: $outputJsonFile" -ForegroundColor Green
} else {
    Write-Host "No rules exported. Skipping JSON file." -ForegroundColor Yellow
}

# Write success summary
$successSummary = @()
$successSummary += "Total exported rules: $($allRules.Count)"
$successSummary += ""
$successSummary += ($successIPs | Sort-Object)
$successSummary | Out-File -Encoding utf8 $successListFile
Write-Host "Success list saved to: $successListFile"

# Write failure summary
$failSummary = @()
$failSummary += "Failed pages: $($failedPages.Count)"
$failSummary += ""
$failSummary += $failedPages
$failSummary | Out-File -Encoding utf8 $failedListFile
Write-Host "Failure list saved to: $failedListFile"

Write-Host "`n=== Export Completed ===" -ForegroundColor Cyan
