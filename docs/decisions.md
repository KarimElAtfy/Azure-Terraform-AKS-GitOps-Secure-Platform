# Architecture Decisions

This document records the main technical decisions behind the Azure Terraform AKS GitOps Secure Platform.

## ADR-001: Use AKS after Azure Container Apps

Status: Accepted

### Context

The previous portfolio project deployed a containerized app to Azure Container Apps. That was useful for serverless containers, but it abstracted away Kubernetes concepts.

This project focuses on Kubernetes operations: pods, probes, scheduling, Helm, Flux, NetworkPolicy, Workload Identity and rollout debugging.

### Decision

Use Azure Kubernetes Service as the compute platform.

### Consequences

AKS increases complexity and cost compared to Container Apps, but it exposes real Kubernetes operational topics that are valuable for Cloud and DevOps practice.

## ADR-002: Use Terraform for Azure Infrastructure

Status: Accepted

### Context

The portfolio is Terraform-based, and Terraform is widely used for infrastructure automation.

### Decision

Use Terraform with the AzureRM provider for Azure infrastructure.

Terraform manages:

- resource groups
- networking
- Azure Container Registry
- Key Vault
- Log Analytics
- AKS
- managed identities
- role assignments
- federated credentials

### Consequences

The project has a reproducible infrastructure layer and keeps infrastructure changes reviewable in Git.

## ADR-003: Split Terraform into bootstrap, core and AKS layers

Status: Accepted

### Context

Remote state storage must exist before other layers can use it.

The AKS layer also depends on core resources such as ACR, Key Vault, identities and Log Analytics.

### Decision

Use three Terraform layers:

~~~text
infra/bootstrap/
infra/core/
infra/aks/
~~~

### Consequences

The deployment order is explicit:

~~~text
bootstrap → core → aks
~~~

This keeps each state file smaller and separates concerns.

## ADR-004: Use Flux for GitOps

Status: Accepted

### Context

The project needs a GitOps controller that continuously reconciles Kubernetes desired state from Git.

Options include Flux and Argo CD.

### Decision

Use Flux v2.

### Reasons

- lightweight
- CLI-first
- native Kustomization support
- native HelmRelease support
- good fit for a single-node dev cluster
- no dashboard requirement in v1

### Consequences

There is no web dashboard. Debugging is done with:

~~~powershell
flux
kubectl
helm
~~~

## ADR-005: Use Helm for application packaging

Status: Accepted

### Context

Kubernetes manifests can be managed as raw YAML, Kustomize overlays or Helm charts.

Helm is widely used in real Kubernetes environments and supports templating, values and chart versioning.

### Decision

Use a Helm chart for the FastAPI application.

Chart path:

~~~text
charts/devsecops-api/
~~~

### Consequences

Flux deploys the app through a HelmRelease that references the chart path in this same Git repository.

## ADR-006: Use GitRepository + HelmRelease for the in-repo chart

Status: Accepted

### Context

The Helm chart is stored inside this repository.

A HelmRepository is useful when charts are published to an external Helm or OCI registry.

### Decision

Use Flux GitRepository + HelmRelease.

### Consequences

The project remains single-repository and easy to inspect.

The HelmRelease references:

~~~text
./charts/devsecops-api
~~~

## ADR-007: Use GitHub Actions OIDC instead of static secrets

Status: Accepted

### Context

Long-lived Azure client secrets are risky because they can leak, expire and require rotation.

### Decision

Use GitHub Actions OIDC federation with Azure.

### Consequences

The workflows do not need an AZURE_CLIENT_SECRET.

GitHub Actions receives short-lived tokens through federated identity.

## ADR-008: Use ACR for container images

Status: Accepted

### Context

The app image needs to be available to AKS.

### Decision

Use Azure Container Registry Basic SKU.

### Consequences

The build workflow pushes images to ACR with:

- short Git SHA tag
- latest tag

The GitOps deployment uses the short Git SHA tag.

## ADR-009: Use Workload Identity and Key Vault CSI for secrets

Status: Accepted

### Context

The app needs to read a secret without storing it in Git or plain Kubernetes manifests.

### Decision

Use AKS Workload Identity with the Secrets Store CSI Driver and Azure Key Vault.

### Consequences

The pod authenticates through a federated Kubernetes ServiceAccount and reads a Key Vault secret mounted as a file.

The app proves access through `/secret-status` without exposing the secret value.

## ADR-010: Keep Terraform and Flux ownership separate

Status: Accepted

### Context

Terraform and Flux can both manage Kubernetes resources. If both manage the same objects, they can conflict.

### Decision

Terraform manages Azure infrastructure only.

Flux and Helm manage Kubernetes workload resources only.

### Consequences

Terraform does not deploy the app.

GitHub Actions does not run kubectl apply.

Flux owns the cluster workload desired state.

## ADR-011: Use a public dev AKS cluster in v1

Status: Accepted

### Context

Private AKS clusters, private endpoints, Azure Firewall and NAT Gateway add significant cost and complexity.

### Decision

Use a public AKS API server for v1.

### Consequences

This is not a production architecture. It is acceptable for a dev/portfolio project with no real workloads or sensitive business data.

Private networking is listed as a future improvement.

## ADR-012: Optimize for cost

Status: Accepted

### Context

The project runs in a personal/student Azure subscription with limited budget and quota.

### Decision

Use cost-conscious choices:

- single-node AKS
- smallest available supported node SKU
- ACR Basic
- no Azure Firewall
- no NAT Gateway
- no Application Gateway
- no managed Prometheus/Grafana in v1
- port-forward validation instead of public LoadBalancer

### Consequences

The cluster is not highly available, but it is cheaper and appropriate for learning and portfolio validation.

## ADR-013: Use Recreate rollout strategy for single-node AKS dev

Status: Accepted

### Context

During GitOps image automation testing, RollingUpdate caused rollout failures on the single-node AKS cluster.

Kubernetes tried to keep the old pod running while scheduling the new pod, but the node had insufficient CPU for both pods.

### Decision

Keep the chart default as RollingUpdate, but override AKS dev values with:

~~~yaml
deploymentStrategy:
  type: Recreate
~~~

### Consequences

The dev environment may have a short downtime during app updates, but rollouts are reliable on the small single-node cluster.

The incident is documented in:

~~~text
docs/incidents/001-rollingupdate-insufficient-cpu.md
~~~

## ADR-014: Use GitHub Actions for image tag updates in v1

Status: Accepted

### Context

Flux Image Automation could update image tags automatically, but it adds another Flux-specific layer.

### Decision

Use GitHub Actions to update the image tag in the HelmRelease after pushing the image to ACR.

### Consequences

The flow is explicit:

~~~text
image build → ACR push → HelmRelease tag update → commit with [skip ci] → Flux deploys
~~~

Flux Image Automation remains a future improvement.

## ADR-015: Add non-blocking security scans first

Status: Accepted

### Context

Security scanners can produce false positives or findings that need triage.

### Decision

Add Checkov and Trivy scanning first, then review findings before making scans blocking.

### Consequences

The repository demonstrates DevSecOps scanning while avoiding noisy pipeline failures during early development.

Future work can make selected checks blocking after findings are reviewed and documented.

## ADR-016: Keep v1 intentionally simple

Status: Accepted

### Context

A portfolio project needs to be understandable, reproducible and cost-controlled.

### Decision

Do not include every possible production feature in v1.

Excluded from v1:

- service mesh
- private cluster
- Azure Firewall
- NAT Gateway
- managed Prometheus/Grafana
- multi-environment promotion
- progressive delivery

### Consequences

The project remains focused on:

- Terraform
- AKS
- Helm
- Flux GitOps
- GitHub Actions
- ACR
- Key Vault
- Workload Identity
- CI security scanning
- practical troubleshooting
