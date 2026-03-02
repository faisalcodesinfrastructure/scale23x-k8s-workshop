# ☸️ Kubernetes for Beginners — SCaLE Workshop

Welcome workshop participants! This repository contains everything you need to follow along with the **Kubernetes for Beginners** workshop at [SCaLE (Southern California Linux Expo)](https://www.socallinuxexpo.org/).

---

## 🎯 What You'll Build

By the end of this workshop, you will have:

- ✅ A local Kubernetes cluster running with KIND
- ✅ A real app deployed with Namespaces, Deployments, and Pods
- ✅ A Service exposing your app inside the cluster
- ✅ Traefik Ingress routing external HTTP traffic (installed via Helm)
- ✅ ConfigMaps and Secrets injected into your app as env vars and mounted files
- ✅ Horizontal scaling and zero-downtime rolling updates
- ✅ A rollback strategy for bad deploys

---

## 🗂️ Workshop Modules

| # | Module | Time |
|---|--------|------|
| 0 | [Pre-Flight Checklist](modules/00-preflight/README.md) | 15 min |
| 1 | [Containers & Kubernetes Concepts](modules/01-concepts/README.md) | 20 min |
| 2 | [Creating Your KIND Cluster](modules/02-kind-cluster/README.md) | 20 min |
| 3 | [Namespaces — Organizing Your Cluster](modules/03-namespaces/README.md) | 10 min |
| 4 | [Deployments — Running Your App](modules/04-deployments/README.md) | 25 min |
| 5 | [Services — Internal Networking](modules/05-services/README.md) | 20 min |
| 6 | [Ingress — External Traffic Routing with Traefik](modules/06-ingress/README.md) | 25 min |
| 7 | [ConfigMaps & Secrets](modules/07-configmaps-secrets/README.md) | 20 min |
| 8 | [Scaling & Rolling Updates](modules/08-scaling-updates/README.md) | 20 min |
| 9 | [Bonus: Troubleshooting & Tips](modules/09-bonus/README.md) | open |

---



## ⚙️ Prerequisites

| Tool | Min Version | Install |
|------|-------------|---------|
| Docker Desktop | v24+ | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| kind | v0.23+ | [kind.sigs.k8s.io](https://kind.sigs.k8s.io/) |
| kubectl | v1.29+ | [kubernetes.io/docs/tasks/tools](https://kubernetes.io/docs/tasks/tools/) |
| helm | v3.14+ | [helm.sh/docs/intro/install](https://helm.sh/docs/intro/install/) |

> 💡 **New to the command line?** Check the [scripts/](scripts/) folder for helper shell scripts.

---

## 🚀 Quick Start

### 1. Clone this repo

```bash
git clone https://github.com/faisalcodesinfrastructure/scale23x-k8s-workshop.git
cd scale23x-k8s-workshop
```

### 2. Pre-pull images

```bash
docker pull kindest/node:v1.29.0
docker pull traefik:v3.0
```

### 3. Create the KIND cluster

```bash
kind create cluster --name workshop --config manifests/kind-config.yaml
kubectl config use-context kind-workshop
kubectl wait --for=condition=Ready node --all --timeout=120s
```

### 4. Install Traefik Ingress Controller

```bash
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  -f manifests/traefik-values.yaml \
  --wait
```

**PowerShell:**
```powershell
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm upgrade --install traefik traefik/traefik `
  --namespace traefik `
  --create-namespace `
  -f manifests/traefik-values.yaml `
  --wait
```

### 5. Build and load the workshop app

```bash
docker build -t k8s-workshop-demo:1.0.0 ./app
kind load docker-image k8s-workshop-demo:1.0.0 --name workshop
```

### 6. Apply all manifests

```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/configmap.yaml
kubectl apply -f manifests/secret.yaml
kubectl apply -f manifests/deployment.yaml
kubectl apply -f manifests/service.yaml
kubectl apply -f manifests/ingress.yaml
kubectl rollout status deployment/demo-app -n workshop-app --timeout=120s
```

### 7. Add hosts file entry

**macOS / Linux / WSL:**
```bash
echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
```

**Windows (PowerShell as Administrator):**
```powershell
Add-Content -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Value "127.0.0.1 demo.local"
```

### 8. Verify

Open **http://demo.local** in your browser.

### 9. Follow the modules in order

---

## 🧱 Repo Structure

```
k8s-workshop/
├── README.md                    ← You are here
├── manifests/                   ← All YAML files (apply these!)
│   ├── kind-config.yaml
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   └── secret.yaml
├── app/                         ← Demo app source (optional)
│   ├── Dockerfile
│   └── index.html
├── modules/                     ← Step-by-step module guides
│   ├── 00-preflight/
│   ├── 01-concepts/
│   └── ...
├── scripts/                     ← Helper scripts
│   ├── setup.sh / setup.ps1
│   ├── teardown.sh / teardown.ps1
│   └── verify.sh / verify.ps1
└── docs/                        ← Extra reference material
    └── kubectl-cheatsheet.md
```

---

## 🙌 About

Workshop presented at **SCaLE Linux Expo** by Faisal, a Principal Technical Consultant Lead at **AHEAD**, specializing in cloud-native transformations, platform engineering, and enterprise architecture.

A [CNCF Ambassador](https://www.cncf.io/people/ambassadors/) and [Platform Engineering Ambassador](https://platformengineering.org/ambassador-program) and organizer of [Cloud Native LA](https://community.cncf.io/cloud-native-los-angeles/).

- 🐦 Questions? Open an [Issue](../../issues)
- 💬 Join [CNCF Slack](https://slack.cncf.io/) — #kubernetes channel
- 📚 [Official Kubernetes Docs](https://kubernetes.io/docs/)


### 🔗 Connect

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/faisalafzal/)

- 💼 **Company:** [AHEAD](https://www.ahead.com)
- 🌐 **Community:** [Cloud Native LA](https://community.cncf.io/cloud-native-los-angeles/)
- 🐦 **Questions?** Open an [Issue](../../issues) or reach out on LinkedIn

---

*If you found this workshop helpful, consider giving the repo a ⭐ — it helps others find it!*
