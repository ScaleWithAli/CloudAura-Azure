# CloudAura-Azure 🚀

> **AWS EKS → Azure AKS Infrastructure Migration**
> Production-grade microservices platform migrated from AWS to Azure using Terraform, GitOps, and cloud-native tooling.

---

## 🏗️ Architecture Overview

5 microservices e-commerce platform (auth, product, order, notif, frontend) fully migrated from AWS EKS to Azure AKS with zero application code changes.

```
Internet → Azure DNS → NGINX Ingress → Istio Service Mesh → Microservices
                                                           ↓
                                          Azure PostgreSQL + Azure Redis
                                                           ↓
                                              Azure Key Vault (Secrets)
```

---

## ☁️ AWS → Azure Migration Map

| AWS | Azure |
|-----|-------|
| EKS (v1.35) | AKS (v1.31) |
| Karpenter | NAP (Node Auto Provisioning) |
| RDS PostgreSQL | Azure PostgreSQL Flexible Server |
| ElastiCache Redis | Azure Cache for Redis (Standard) |
| AWS Secrets Manager | Azure Key Vault |
| ECR (5 repos) | ACR (1 registry, auto-creates repos) |
| IAM + Pod Identity | Azure AD Workload Identity |
| Route53 | Azure DNS Zone |
| AWS Load Balancer Controller | Azure Standard Load Balancer (built-in) |
| EBS CSI Driver | Azure Disk CSI (built-in AKS) |

---

## 🛠️ Tech Stack

### Infrastructure
- **Terraform** — IaC for all Azure resources
- **AKS** — Managed Kubernetes (v1.31, Sweden Central)
- **NAP** — Node Auto Provisioning (Karpenter-based, Microsoft managed)
- **Azure VNet** — Custom networking with NAT Gateway

### GitOps & CI/CD
- **ArgoCD** — GitOps continuous delivery
- **Argo Rollouts** — Progressive delivery (canary/blue-green)
- **ArgoCD Image Updater** — Automatic image tag updates from ACR

### Observability
- **Prometheus + Grafana** — Metrics and dashboards
- **Istio** — Service mesh, mTLS, traffic management

### Security
- **Azure AD Workload Identity** — Pod-level identity (no static credentials)
- **External Secrets Operator** — Syncs secrets from Azure Key Vault to Kubernetes
- **cert-manager** — Automatic TLS via Let's Encrypt

---

## 📁 Repository Structure

```
├── providers.tf        # Azure providers + Terraform backend config
├── variables.tf        # Input variables
├── locals.tf           # Scheduling locals + Helm values
├── network.tf          # VNet + Subnet + NAT Gateway
├── aks.tf              # AKS cluster + NAP
├── acr.tf              # Azure Container Registry
├── database.tf         # PostgreSQL + Redis + Key Vault + Secrets
├── identity.tf         # Azure AD Workload Identity + Federated Credentials
├── aks-addons.tf       # NGINX Ingress + External Secrets
├── addons.tf           # ArgoCD + Prometheus + Istio + cert-manager
└── dns.tf              # Azure DNS Zone + A Records
```

---

## 🚀 Deployment

### Prerequisites
- Azure CLI (`az login`)
- Terraform >= 1.7.0
- kubectl + kubelogin

### Bootstrap Remote State
```bash
az storage account create \
  --name cloudauratfstate \
  --resource-group cloudaura-rg \
  --location swedencentral \
  --sku Standard_LRS

az storage container create \
  --name cloudaura \
  --account-name cloudauratfstate \
  --auth-mode login
```

### Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

---

## 🔑 Key Design Decisions

**NAP over Karpenter** — Azure's Node Auto Provisioning is Microsoft-managed Karpenter. No self-hosted maintenance, production-ready out of the box.

**Single ACR Registry** — Unlike AWS ECR (5 separate repos), ACR auto-creates repositories on first push. One registry for all services.

**Workload Identity over Service Principals** — Pod-level Azure AD identity with federated credentials. No static secrets, no rotation needed.

**External Secrets over CSI Driver** — Kubernetes-native secret sync from Key Vault. Works with ArgoCD GitOps flow without manual secret management.

---

## 🔗 Related

- [CloudAura AWS (Original)](https://github.com/ScaleWithAli/Platform_repo) — Original AWS EKS deployment
- Live at: [cloudaura.online](https://cloudaura.online)

---

**Built by [Muhammad Ali Hassan](https://github.com/ScaleWithAli) — Self-taught DevOps Engineer**
