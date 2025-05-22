Cloudflare Zone-Level IP Access Rules Export & Import Scripts
Overview

This repository contains two PowerShell scripts designed to export and import zone-level IP Access Rules (firewall rules) for a specific Cloudflare Zone ID using the Cloudflare API.

    Export Script: Retrieves and saves IP Access Rules for a specific zone to a JSON file.

    Import Script: Reads a JSON file of IP Access Rules and applies them to another (or the same) Cloudflare zone.

These tools are ideal for backups, audits, rule replication, or migrations across different Cloudflare zones.
Technologies Used

    PowerShell: Compatible with Windows PowerShell 5.1+ and PowerShell Core on macOS/Linux.

    Cloudflare API v4: Used to interact with zone-level firewall rules.

    JSON: PowerShell’s ConvertTo-Json and ConvertFrom-Json cmdlets handle rule data.

Scripts Included
Export-Zone-IP-Rules.ps1

This script exports all IP Access Rules from a specific Cloudflare zone.

Key Features:

    Paginates through all rules automatically.

    Retries on API rate limiting (HTTP 429).

    Logs successful IPs and failed pages.

Outputs:

    zone_ip_access_rules.json: JSON export of all rules.

    export_success_summary.txt: List of successfully exported IPs.

    export_failed_summary.txt: Summary of failed pages or errors.

Import-Zone-IP-Rules.ps1

This script imports IP Access Rules from a JSON file into a target Cloudflare zone.

Key Features:

    Avoids duplicate rule imports using a local import log.

    Retries on rate limits and logs failed imports.

    Tracks imported IPs for future idempotent runs.

Outputs:

    imported_ips.log: Records all IPs that were successfully imported.

    import_success_summary.txt: Summary of imported rules.

    import_failed_summary.txt: Details of failed imports.

Setup Instructions
Prerequisites

    PowerShell 5.1+ (Windows) or PowerShell Core (macOS/Linux).

    Active Cloudflare account with Zone access.

    Your Zone ID, Global API Key, and account email.

Configuration

In both scripts, configure your credentials and target zone:

$headers = @{
  "X-Auth-Email" = "your-email@example.com"
  "X-Auth-Key"   = "your-global-api-key"
  "Content-Type" = "application/json"
}
$zoneId = "your-zone-id-here"

Replace placeholders with your actual Cloudflare credentials and zone ID.
Usage
Exporting Rules

    Open PowerShell.

    Run Export-Zone-IP-Rules.ps1.

    Files will be generated on your Desktop:

        zone_ip_access_rules.json

        export_success_summary.txt

        export_failed_summary.txt

Importing Rules

    Ensure zone_ip_access_rules.json is present on your Desktop.

    Run Import-Zone-IP-Rules.ps1.

    Output files:

        imported_ips.log

        import_success_summary.txt

        import_failed_summary.txt

Security Notice

    Do not hardcode sensitive API credentials in version-controlled files.

    Consider using environment variables or a secure secrets manager for production use.

    Your Global API Key has full account access — treat it like a password.

License

This project is licensed under the MIT License. You may use, modify, and distribute it with appropriate attribution.
