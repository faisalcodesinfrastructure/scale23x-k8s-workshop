# verify.ps1 — Checks that the workshop environment is healthy
# Usage: .\scripts\verify.ps1

$PASS = 0; $FAIL = 0

function Check {
    param($desc, $cmd)
    try {
        $result = Invoke-Expression $cmd 2>$null
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "non-zero exit" }
        Write-Host "  + $desc" -ForegroundColor Green
        $script:PASS++
    } catch {
        Write-Host "  x $desc" -ForegroundColor Red
        $script:FAIL++
    }
}

Write-Host ""
Write-Host "======================================="
Write-Host "   * Workshop Environment Check"
Write-Host "======================================="

Write-Host ""
Write-Host "-- Tools ---------------------------------"
Check "docker installed"              "Get-Command docker -ErrorAction Stop"
Check "docker running"                "docker info"
Check "kind installed"                "Get-Command kind -ErrorAction Stop"
Check "kubectl installed"             "Get-Command kubectl -ErrorAction Stop"
Check "helm installed"                "Get-Command helm -ErrorAction Stop"

Write-Host ""
Write-Host "-- Cluster -------------------------------"
Check "KIND cluster 'workshop' exists"   "if (-not ((kind get clusters) -match 'workshop')) { throw 'not found' }"
Check "kubectl context is kind-workshop" "if (-not ((kubectl config current-context) -match 'kind-workshop')) { throw 'wrong context' }"
Check "Node is Ready"                    "if (-not ((kubectl get nodes) -match 'Ready')) { throw 'not ready' }"

Write-Host ""
Write-Host "-- Traefik Ingress Controller ------------"
Check "traefik namespace exists"         "kubectl get ns traefik"
Check "Traefik pod running"              "if (-not ((kubectl get pods -n traefik) -match 'Running')) { throw 'not running' }"

Write-Host ""
Write-Host "-- Application ---------------------------"
Check "workshop-app namespace exists"    "kubectl get ns workshop-app"
Check "ConfigMap exists"                 "kubectl get configmap demo-app-config -n workshop-app"
Check "Secret exists"                    "kubectl get secret demo-app-secret -n workshop-app"
Check "Deployment exists"                "kubectl get deployment demo-app -n workshop-app"
Check "Pods are Running"                 "if (-not ((kubectl get pods -n workshop-app) -match 'Running')) { throw 'not running' }"
Check "Service exists"                   "kubectl get svc demo-app-svc -n workshop-app"
Check "Ingress exists"                   "kubectl get ingress demo-app-ingress -n workshop-app"

Write-Host ""
Write-Host "-- Network -------------------------------"
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
Check "demo.local in hosts file"         "if (-not ((Get-Content '$hostsFile') -match 'demo\.local')) { throw 'not found' }"
Check "App responds at demo.local"       "Invoke-WebRequest -Uri http://demo.local/health -UseBasicParsing -ErrorAction Stop"

Write-Host ""
Write-Host "======================================="
if ($FAIL -eq 0) {
    Write-Host "All $PASS checks passed!" -ForegroundColor Green
    Write-Host "Open http://demo.local in your browser"
} else {
    Write-Host "$FAIL check(s) failed | $PASS passed" -ForegroundColor Red
    Write-Host "Run '.\scripts\setup.ps1' to fix the environment" -ForegroundColor Yellow
}
Write-Host "======================================="
Write-Host ""
