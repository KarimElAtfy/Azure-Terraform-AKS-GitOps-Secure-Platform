# Architecture Decisions

Short ADR-style notes for the main choices in this project.

---

## ADR-001: AKS after Container Apps

**Status:** Accepted

**Context:** L5 deployed a containerized app to Azure Container Apps, which is a managed serverless container platform. It abstracts away Kubernetes entirely. For Kubernetes practice, I wanted those pieces to be visible and configurable: pod lifecycle, probes, scheduling, scaling, RBAC and network policies.

**Decision:** Use Azure Kubernetes Service (AKS) as the compute platform.

**Consequences:** AKS gives access to the Kubernetes API and forces the project to deal with real operational topics: node pools, upgrades, networking and permissions. The tradeoff is higher complexity and cost compared to Container Apps.

---

## ADR-002: Terraform for Infrastructure

**Status:** Accepted

**Context:** The entire portfolio is built on Terraform. Consistency matters for a portfolio, and Terraform is the most widely requested IaC tool in job postings.

**Decision:** Continue using Terraform with the azurerm provider for all Azure infrastructure.

**Consequences:** Three Terraform layers (bootstrap, core, aks) keep concerns separated. Each layer has its own state file. Modules improve reusability without over-engineering.

---

## ADR-003: Flux for GitOps (not ArgoCD)

**Status:** Accepted

**Context:** Two major GitOps tools exist: Flux and ArgoCD. ArgoCD has a web UI and is more popular for visual cluster management. Flux is lighter, CLI-first, and integrates natively with Helm and Kustomize.

**Decision:** Use Flux v2.

**Reasons:**
- Flux is lighter on cluster resources (important for a single small node).
- Flux is a CNCF graduated project.
- Flux has native HelmRelease and Kustomization CRDs.
- CLI-first approach matches the DevOps workflow style of this portfolio.
- No need for a dashboard UI in a dev/portfolio project.

**Consequences:** No web dashboard for deployments. Debugging is through `flux` CLI and `kubectl`. For this project, CLI-based debugging is enough and keeps the setup lighter.

---

## ADR-004: Helm for Kubernetes Packaging

**Status:** Accepted

**Context:** Kubernetes manifests can be managed as raw YAML, Kustomize overlays, or Helm charts. Helm is the most common packaging format in the industry and supports templating, versioning, and values overrides.

**Decision:** Use Helm charts for the application deployment.

**Consequences:** The chart lives in `charts/devsecops-api/` inside this repo. Flux deploys it via a HelmRelease that references a GitRepository source. This avoids needing a separate Helm registry while still using Helm's templating capabilities.

---

## ADR-005: GitHub Actions OIDC (no static secrets)

**Status:** Accepted

**Context:** L5 already uses OIDC for GitHub-to-Azure authentication. Static client secrets are easy to mishandle: they can leak, expire and need rotation.

**Decision:** Continue using GitHub Actions OIDC with Azure AD federated credentials.

**Consequences:** No `AZURE_CLIENT_SECRET` in GitHub Secrets. Authentication is token-based and short-lived. Requires setting up a federated credential on an Azure AD App Registration or Managed Identity, scoped to this repository.

---

## ADR-006: Workload Identity for Key Vault Access

**Status:** Accepted

**Context:** The app needs to read a secret from Azure Key Vault. Options include: mounting secrets as environment variables via Kubernetes Secrets (insecure at rest), using the Key Vault CSI Driver with pod identity, or using the Key Vault CSI Driver with Workload Identity.

**Decision:** Use AKS Workload Identity with the Key Vault CSI Driver to mount secrets into the pod.

**Reasons:**
- No credentials stored in the cluster.
- The pod's ServiceAccount is federated with an Azure Managed Identity.
- The Managed Identity has a scoped role assignment (Key Vault Secrets User).
- This is the current Microsoft-recommended approach.

**Consequences:** Requires enabling OIDC Issuer and Workload Identity on AKS, creating a federated identity credential, and configuring a SecretProviderClass. More setup than a Kubernetes Secret, but significantly more secure and representative of production patterns.

**Fallback:** If Workload Identity setup proves too complex for the first iteration, a temporary Kubernetes Secret can be used for local testing only, clearly marked as non-production.

---

## ADR-007: Public Dev AKS (not private cluster)

**Status:** Accepted

**Context:** Production AKS clusters typically use private API server endpoints, private link, Azure Firewall, and jump boxes. These add significant cost (Azure Firewall alone is ~$800/month) and complexity.

**Decision:** Use a public AKS cluster for this dev/portfolio project.

**Consequences:** The API server is publicly accessible (protected by Azure AD authentication). This is acceptable for a dev environment with no real workloads. The architecture document acknowledges this as a limitation and lists private cluster as a future improvement.

---

## ADR-008: Cost-Conscious Design

**Status:** Accepted

**Context:** This project runs on a personal Azure subscription with limited budget and possible quota constraints.

**Decision:** Optimize for minimum viable cost at every layer.

**Specific choices:**
- AKS Free tier (no SLA or uptime guarantee, acceptable for dev).
- Single node pool, 1 node, smallest available AKS-supported VM after checking quota/SKU availability. `Standard_B2s` is only a target candidate.
- ACR Basic SKU (~$5/month).
- No Azure Firewall, NAT Gateway, Application Gateway, or WAF.
- No managed Prometheus/Grafana in v1.
- No private endpoints or private DNS zones.
- Apply → validate → document → destroy workflow.

**Consequences:** This is not a production-ready platform. The goal is to practice the same patterns on a small, affordable setup, with limitations documented clearly.

---

## ADR-009: Terraform and Flux Boundary

**Status:** Accepted

**Context:** Both Terraform (via the kubernetes/helm providers) and Flux can manage Kubernetes resources. If both try to manage the same resource, they will fight over the same desired state.

**Decision:** Draw a clear boundary:
- **Terraform** creates and manages Azure resources only (resource groups, VNet, ACR, Key Vault, AKS cluster, identities, role assignments).
- **Flux/Helm** create and manage Kubernetes resources only (namespaces, deployments, services, configmaps, network policies, SecretProviderClass).

**Consequences:** Terraform outputs provide the non-secret values that Flux/Helm need (ACR login server, Key Vault name, identity client ID). These are passed into Helm values or Flux configuration. Neither tool touches the other's domain.

---

## ADR-010: Globally Unique Azure Names

**Status:** Accepted

**Context:** Azure Storage Account, Azure Container Registry and Key Vault names are globally unique. Fixed demo names can fail immediately if someone else already owns them.

**Decision:** Use either a generated random suffix or a documented `name_suffix` variable for globally unique resources. README examples may show readable names, but Terraform code must not rely on fixed global names.

**Consequences:** Resource names are slightly less pretty, but deployments become reproducible across subscriptions.

---

## ADR-011: Flux Source for In-Repo Helm Chart

**Status:** Accepted

**Context:** The Helm chart is stored in this same repository under `charts/devsecops-api/`. Flux supports deploying Helm charts from a Git source or from a Helm repository.

**Decision:** Use a Flux `GitRepository` source plus `HelmRelease` for v1. Do not use `HelmRepository` unless the chart is later published to an external Helm/OCI registry.

**Consequences:** The project stays single-repository and simple. The GitOps source of truth is easier to understand.

---

## ADR-012: GitHub Actions Loop Protection

**Status:** Accepted

**Context:** The image build workflow may commit updated image tags under `clusters/dev/`. That commit can retrigger CI and accidentally create a loop.

**Decision:** Use path filters, workflow separation, or `[skip ci]` commit messages for automated GitOps tag commits.

**Consequences:** The pipeline remains predictable and avoids unnecessary builds.
