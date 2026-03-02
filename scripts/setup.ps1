# ─────────────────────────────────────────────────────────────────────────────
# setup.ps1 — One-command workshop environment setup (PowerShell)
# Works on: Windows (native), Windows WSL (via pwsh)
# Usage: .\scripts\setup.ps1
# ─────────────────────────────────────────────────────────────────────────────
$ErrorActionPreference = "Stop"

function Log    { param($msg) Write-Host "[INFO]  $msg" -ForegroundColor Blue }
function Success{ param($msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Warn   { param($msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Abort  { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "+===================================================+"
Write-Host "|     * Kubernetes Beginners Workshop - Setup        |"
Write-Host "+===================================================+"
Write-Host ""

# -- 1. Check prerequisites --------------------------------------------------
Log "Checking prerequisites..."
if (-not (Get-Command docker  -ErrorAction SilentlyContinue)) { Abort "docker not found - install Docker Desktop first" }
if (-not (Get-Command kind    -ErrorAction SilentlyContinue)) { Abort "kind not found - see modules/00-preflight/README.md" }
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { Abort "kubectl not found - see modules/00-preflight/README.md" }
if (-not (Get-Command helm    -ErrorAction SilentlyContinue)) { Abort "helm not found - install from https://helm.sh/docs/intro/install/" }
try { docker info 2>$null | Out-Null } catch { Abort "Docker daemon is not running - start Docker Desktop" }
Success "All prerequisites found"

# -- 2. Pre-pull images ------------------------------------------------------
Log "Pre-pulling images (avoids Wi-Fi issues during the workshop)..."
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0
Success "Images ready"

# -- 3. Create KIND cluster ---------------------------------------------------
Log "Creating KIND cluster 'workshop'..."
$existingClusters = kind get clusters 2>$null
if ($existingClusters -match "^workshop$") {
    Warn "Cluster 'workshop' already exists - skipping creation"
} else {
    kind create cluster --name workshop --config manifests/kind-config.yaml
    Success "KIND cluster created"
}

kubectl config use-context kind-workshop
Success "kubectl context -> kind-workshop"

Log "Waiting for node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s
Success "Node is Ready"

# -- 4. Install Traefik Ingress Controller ------------------------------------
Log "Adding Traefik Helm repo..."
helm repo add traefik https://traefik.github.io/charts
helm repo update

Log "Installing Traefik Ingress Controller..."
helm upgrade --install traefik traefik/traefik `
    --namespace traefik `
    --create-namespace `
    --set ports.web.nodePort=30080 `
    --set service.type=NodePort `
    --wait
Success "Traefik Ingress Controller is running"

# -- 5. Build and load the workshop app --------------------------------------
Log "Building workshop app image..."
docker build -t k8s-workshop-demo:1.0.0 ./app
Log "Loading image into KIND..."
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
Success "Workshop app image loaded"

# -- 6. Apply all manifests ---------------------------------------------------
Log "Applying manifests..."
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml

Log "Waiting for deployment to be ready..."
kubectl rollout status deployment/demo-app -n workshop-app --timeout=120s
Success "Application deployed"

# -- 7. Add hosts file entry --------------------------------------------------
$hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
$hostsContent = Get-Content $hostsFile -ErrorAction SilentlyContinue
if ($hostsContent -match "demo\.local") {
    Warn "demo.local already in hosts file - skipping"
} else {
    Log "Adding demo.local to hosts file (requires admin privileges)..."
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Warn "Not running as Administrator - please add '127.0.0.1 demo.local' to $hostsFile manually"
    } else {
        Add-Content -Path $hostsFile -Value "127.0.0.1 demo.local"
        Success "Added demo.local -> hosts file"
    }
}

# -- 8. Done ------------------------------------------------------------------
Write-Host ""
Write-Host "+===================================================+"
Write-Host "|               All Done!                           |"
Write-Host "+===================================================+"
Write-Host ""
Success "Open http://demo.local in your browser!"
Write-Host ""
Write-Host "  Cluster:    kind-workshop"
Write-Host "  Namespace:  workshop-app"
Write-Host "  URL:        http://demo.local"
Write-Host ""
