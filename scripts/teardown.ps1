# ─────────────────────────────────────────────────────────────────────────────
# teardown.ps1 — Removes all workshop resources
# Usage: .\scripts\teardown.ps1
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "Stop"

function Log    { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Blue }
function Success{ param($msg) Write-Host "[OK]   $msg" -ForegroundColor Green }
function Warn   { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }

Write-Host ""
Write-Host "+===================================================+"
Write-Host "|    * Kubernetes Workshop - Teardown               |"
Write-Host "+===================================================+"
Write-Host ""

# -- 1. Delete KIND cluster ---------------------------------------------------
$existingClusters = kind get clusters 2>$null
if ($existingClusters -match "^workshop$") {
    Log "Deleting KIND cluster 'workshop'..."
    kind delete cluster --name workshop
    Success "Cluster deleted"
} else {
    Warn "Cluster 'workshop' not found - skipping"
}

# -- 2. Remove hosts file entry -----------------------------------------------
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile -ErrorAction SilentlyContinue
if ($hostsContent -match "demo\.local") {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Warn "Not running as Administrator - please remove 'demo.local' from $hostsFile manually"
    } else {
        Log "Removing demo.local from hosts file..."
        $filtered = $hostsContent | Where-Object { $_ -notmatch "demo\.local" }
        Set-Content -Path $hostsFile -Value $filtered
        Success "Removed demo.local from hosts file"
    }
} else {
    Warn "demo.local not in hosts file - skipping"
}

Write-Host ""
Success "Teardown complete! Your system is clean."
Write-Host ""
