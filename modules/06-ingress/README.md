# Module 6 — Ingress: External Traffic Routing

> ⏱️ **Time:** 25 minutes | 🎯 **Goal:** Install an Ingress Controller and route external HTTP traffic to your app

---

## What is Ingress?

**Ingress** is a Kubernetes resource that manages external HTTP/HTTPS access to Services in a cluster.

Think of it as a **smart router** — one entry point that directs traffic to different Services based on:
- **Hostname:** `api.example.com` → api-service, `app.example.com` → frontend-service
- **Path:** `/api/*` → backend-service, `/` → frontend-service

```
Internet
    │
    ▼
Port 80 (your laptop / cloud load balancer)
    │
    ▼
┌─────────────────────────────────────┐
│         Ingress Controller          │
│       (Traefik running as a Pod)    │
│                                     │
│  Rule: demo.local / → demo-app-svc  │
└─────────────────────────────────────┘
    │
    ▼
Service: demo-app-svc
    │
    ├── Pod 1
    └── Pod 2
```

---

## Ingress vs. Service LoadBalancer

| | Service LoadBalancer | Ingress |
|--|--|--|
| Layer | L4 (TCP/UDP) | L7 (HTTP/HTTPS) |
| Path routing | ❌ No | ✅ Yes |
| TLS termination | ❌ No | ✅ Yes |
| Cost on cloud | 1 LB per service ($$) | 1 LB for all services (cheap ✅) |
| Header manipulation | ❌ No | ✅ Yes |

> 🏭 **Production pattern:** One cloud LoadBalancer → Ingress Controller → many Services

---

## Why Traefik?

This workshop uses **Traefik** as the Ingress Controller instead of NGINX Ingress. Here's why:

| | NGINX Ingress | Traefik |
|--|--|--|
| Multi-arch (Intel/AMD/Apple Silicon/ARM) | ❌ Separate images per arch, prone to pull errors | ✅ Single multi-arch image, works everywhere |
| Install complexity | ❌ 3 pods, admission webhooks, long YAML | ✅ One Helm command, one pod |
| Conference Wi-Fi reliability | ❌ Large image, rate limit issues | ✅ Small image (~50MB), fast pull |
| Production relevance | ⚠️ Being retired March 2026 | ✅ Actively maintained, recommended replacement |

The Ingress concepts you learn here — rules, hostnames, paths, backends — are **identical** regardless of which controller you use. Switching controllers in a real cluster is just a one-line change (`ingressClassName`).

---

## Step 1: Install Helm

Helm is the Kubernetes package manager. We use it to install Traefik.

**macOS:**
```bash
brew install helm
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows:**
```powershell
winget install Helm.Helm
```
Verify:
```bash
helm version
# version.BuildInfo{Version:"v3.x.x"...}
```

**Windows (WSL2):**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

---

## Step 2: Pre-Pull Traefik Image Into KIND

Because KIND nodes run inside Docker containers, they can't always reach the internet directly (especially on corporate networks or conference Wi-Fi). Pre-pull on your host and load it in:

```bash
docker pull traefik:v3.0
kind load docker-image traefik:v3.0 --name workshop
```

Verify it's inside the cluster:
```bash
docker exec workshop-control-plane crictl images | grep traefik
```

---

## Step 3: Install Traefik

We use a values file (`manifests/traefik-values.yaml`) to configure Traefik correctly for KIND. This sets up DaemonSet mode with hostNetwork so traffic flows through KIND's port mappings properly.

```bash
# Add the official Traefik Helm chart repository
helm repo add traefik https://traefik.github.io/charts
helm repo update

# Install Traefik using the pre-configured values file
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --values manifests/traefik-values.yaml \
  --wait
```

> 💡 `--wait` blocks until Traefik is fully running. Should complete in under 60 seconds.

Verify it's running:
```bash
kubectl get pods -n traefik
```

Expected output:
```
NAME                       READY   STATUS    RESTARTS   AGE
traefik-xxxxxxxxxx-xxxxx   1/1     Running   0          30s
```

One pod. Running. Done. ✅

---

## Step 4: Review the Ingress YAML

```bash
cat manifests/ingress.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-app-ingress
  namespace: workshop-app
  annotations:
    traefik.ingress.kubernetes.io/router.entrypoints: web
spec:
  ingressClassName: traefik    # Which Ingress Controller handles this
  rules:
    - host: demo.local          # Match requests with this Host header
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: demo-app-svc
                port:
                  number: 80
```

### Key Fields

| Field | What it does |
|-------|-------------|
| `ingressClassName: traefik` | Tells Kubernetes which controller owns this Ingress |
| `host: demo.local` | Only match requests with `Host: demo.local` header |
| `path: /` | Match all paths |
| `pathType: Prefix` | Match `/` and everything below it |
| `backend.service` | Forward matched traffic to this Service on this port |

---

## Step 5: Apply the Ingress

```bash
kubectl apply -f manifests/ingress.yaml
```

Verify:
```bash
kubectl get ingress -n workshop-app
```

Expected output:
```
NAME               CLASS     HOSTS        ADDRESS     PORTS   AGE
demo-app-ingress   traefik   demo.local   localhost   80      15s
```

---

## Step 6: Configure Local DNS

`demo.local` is a fake hostname — we need to tell your laptop to resolve it to localhost.

**macOS / Linux:**
```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

**Windows (PowerShell as Administrator):**
```powershell
Add-Content -Path C:\Windows\System32\drivers\etc\hosts -Value '127.0.0.1 demo.local'
```

Verify:
```bash
ping -c 1 demo.local
# Should show: 127.0.0.1
```


**Windows (WSL2):**
```bash
# Your browser runs on Windows, not inside WSL2.
# Edit the Windows hosts file using the PowerShell block above,
# then open http://demo.local in your normal Windows browser.
```


---

## Step 7: Test End-to-End!

Open http://demo.local in your browser. You should see the workshop app! 🎉

Refresh several times — watch the **Pod Name** in the hero card change as Traefik load-balances across your two pods.

You can also test from the terminal:
```bash
curl http://demo.local/health
# {"status":"ok","pod":"demo-app-xxx","uptime":"5m"}
```

---

## Understanding the Full Traffic Flow

```
1. You open: http://demo.local
2. Browser → /etc/hosts → resolves demo.local to 127.0.0.1
3. Request hits port 80 on your laptop
4. KIND extraPortMapping → port 80 inside the cluster
5. Traefik pod receives the request
6. Traefik reads the Host: demo.local header
7. Matches Ingress rule: demo.local / → demo-app-svc:80
8. Service load-balances to one of the 2 Pods
9. Pod responds → back through the chain → your browser
```

---

## 🧪 Lab: Multi-Service Routing

This is what makes Ingress powerful — one controller, multiple apps. Imagine you had a second service:

```yaml
# Hypothetical second Ingress rule
- host: api.local
  http:
    paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
```

Both `demo.local` and `api.local` would go through **the same Traefik pod** and get routed to different Services. In a cloud cluster this means one load balancer ($) instead of one per service ($$$$).

---

## 🧪 Lab: Traefik Dashboard

Traefik ships with a built-in dashboard showing all routes, services, and middleware:

```bash
kubectl port-forward -n traefik $(kubectl get pods -n traefik -o name) 9000:9000
```

Open http://localhost:9000/dashboard/ — you'll see your `demo.local` route listed!

Press `Ctrl+C` when done.

---

**➡️ Next:** [Module 7 — ConfigMaps & Secrets](../07-configmaps-secrets/README.md)
