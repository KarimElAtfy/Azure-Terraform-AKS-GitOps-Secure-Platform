# Architecture

This document describes the architecture of the Azure Terraform AKS GitOps Secure Platform.

The platform is a dev-focused, cost-conscious AKS GitOps environment built to demonstrate practical Cloud, DevOps and DevSecOps patterns.

## Core Idea

The project is split into two clear ownership layers:

~~~text
Terraform owns Azure infrastructure.
Flux + Helm own Kubernetes workloads.
~~~

This boundary is intentional. It prevents Terraform and Flux from fighting over the same Kubernetes resources.

## High-Level Architecture

~~~mermaid
flowchart TB
    Dev[Developer] --> GH[GitHub Repository]

    GH --> GHA[GitHub Actions]
    GHA --> ACR[Azure Container Registry]
    GHA --> GitOps[Update HelmRelease image tag]

    GitOps --> Flux[Flux Controllers]

    subgraph Azure["Azure - Terraform managed"]
        RG[Resource Group]
        VNet[Virtual Network]
        Subnet[AKS Subnet]
        KV[Azure Key Vault]
        LA[Log Analytics]
        MI[Managed Identities]
        AKS[AKS Cluster]
    end

    subgraph AKSCluster["AKS - Flux and Helm managed"]
        Flux --> HR[HelmRelease]
        HR --> Helm[Helm chart rendering]
        Helm --> NS[Namespace devsecops-api]
        Helm --> SA[ServiceAccount]
        Helm --> Deploy[Deployment devsecops-api]
        Helm --> SVC[ClusterIP Service]
        Helm --> SPC[SecretProviderClass]
        Helm --> NP[NetworkPolicy]
        Deploy --> Pod[FastAPI Pod]
    end

    AKS --> AKSCluster
    ACR --> Pod
    Pod --> KV
    AKS --> LA
    SA --> MI
~~~

## Azure Infrastructure Layer

Terraform is divided into three layers.

~~~text
infra/bootstrap/
infra/core/
infra/aks/
~~~

### Bootstrap Layer

Path:

~~~text
infra/bootstrap/
~~~

Purpose:

- creates Terraform remote state resource group
- creates Storage Account
- creates Blob container for state files

This layer uses local state because the remote backend does not exist yet.

### Core Layer

Path:

~~~text
infra/core/
~~~

Purpose:

- main resource group
- virtual network
- AKS subnet
- Azure Container Registry
- Azure Key Vault
- Log Analytics workspace
- workload managed identity
- GitHub Actions managed identity
- role assignments
- federated credentials for GitHub Actions

### AKS Layer

Path:

~~~text
infra/aks/
~~~

Purpose:

- AKS cluster
- single-node system node pool
- OIDC issuer
- Workload Identity
- Key Vault CSI driver addon
- Log Analytics integration
- AcrPull assignment for AKS image pulls
- federated identity credential for the application ServiceAccount

## Kubernetes Workload Layer

Flux and Helm manage Kubernetes resources.

Main paths:

~~~text
clusters/dev/
charts/devsecops-api/
~~~

### Flux Desired State

Path:

~~~text
clusters/dev/
~~~

Contains:

- Flux bootstrap manifests
- application namespace
- HelmRelease
- NetworkPolicy

### Helm Chart

Path:

~~~text
charts/devsecops-api/
~~~

The Helm chart renders:

- ServiceAccount
- ConfigMap
- Deployment
- Service
- optional HPA
- optional Ingress
- SecretProviderClass
- NetworkPolicy through GitOps policy manifests

## Application Deployment Flow

~~~mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant ACR as Azure Container Registry
    participant Flux as Flux
    participant Helm as Helm Controller
    participant AKS as AKS

    Dev->>GH: Push app change
    GH->>GHA: Trigger image build workflow
    GHA->>ACR: Push image with git SHA tag
    GHA->>GH: Update HelmRelease image tag with [skip ci]
    Flux->>GH: Detect new Git revision
    Flux->>Helm: Reconcile HelmRelease
    Helm->>AKS: Apply rendered manifests
    AKS->>ACR: Pull image
    AKS->>AKS: Run updated pod
~~~

## Identity Architecture

~~~mermaid
flowchart LR
    GHA[GitHub Actions] -->|OIDC federation| AzureAD[Microsoft Entra ID]
    AzureAD -->|short-lived token| Azure[Azure APIs]

    Kubelet[AKS kubelet identity] -->|AcrPull| ACR[Azure Container Registry]

    Pod[Application Pod] --> SA[Kubernetes ServiceAccount]
    SA -->|federated subject| WI[Workload Managed Identity]
    WI -->|Key Vault Secrets User| KV[Azure Key Vault]
    KV --> CSI[Secrets Store CSI Driver]
    CSI --> Pod
~~~

## Secret Flow

The application does not receive secrets from Git or plain Kubernetes Secrets.

The secret flow is:

~~~text
Key Vault
  → Secrets Store CSI Driver
  → mounted file inside the pod
  → application reads the mounted file
  → /secret-status reports loaded=True without exposing the value
~~~

## Networking Model

The v1 networking model is intentionally simple.

Included:

- Azure VNet
- AKS subnet
- AKS public API server
- ClusterIP Service for the app
- port-forward for validation
- basic Kubernetes NetworkPolicy

Not included in v1:

- private AKS cluster
- private endpoints
- Azure Firewall
- NAT Gateway
- Application Gateway
- ingress-nginx as a default requirement
- service mesh

## Rollout Strategy

The dev AKS environment is single-node and cost-conscious.

For this reason, the AKS GitOps values use:

~~~yaml
deploymentStrategy:
  type: Recreate
~~~

This avoids rollout failures caused by a RollingUpdate surge requiring both old and new pods to fit on the same small node.

The default chart value remains RollingUpdate, but the AKS dev environment overrides it to Recreate.

## Security Controls

Implemented controls:

- GitHub Actions OIDC authentication to Azure
- no Azure client secret in GitHub
- no application secret committed to Git
- ACR image pulls through managed identity
- Key Vault access through Workload Identity
- Key Vault CSI secret mount
- Kubernetes NetworkPolicy
- Checkov IaC scanning
- Trivy repository scanning
- Helm lint and render validation
- dedicated AKS GitOps Helm validation workflow

## Observability Model

v1 observability is intentionally lightweight.

Used signals:

- Flux status
- HelmRelease status
- Kubernetes pod status
- Kubernetes events
- application logs
- diagnostic endpoints
- Log Analytics / Azure Monitor basics

Not included in v1:

- Prometheus
- Grafana
- distributed tracing
- full alerting stack

## Main Runtime Validation

A healthy deployment should show:

~~~text
Flux GitRepository Ready=True
Flux Kustomization Ready=True
HelmRelease Ready=True
Pod Running 1/1
Deployment strategy Recreate
NetworkPolicy present
Key Vault secret mounted
/version reports the deployed git SHA
/secret-status reports loaded=True
~~~

## Known Limitations

This is a dev/portfolio platform, not production.

Limitations:

- single-node AKS cluster
- public AKS API server
- no high availability
- no private endpoints
- no Azure Firewall
- no NAT Gateway
- no service mesh
- no multi-environment promotion flow
- no Prometheus/Grafana in v1
- validation primarily through port-forward
- security scans may initially run in observation mode before becoming blocking

## Future Improvements

Potential future improvements:

- staging and production environments
- private AKS cluster
- private endpoints for ACR and Key Vault
- managed Prometheus and Grafana
- policy enforcement with Kyverno or OPA Gatekeeper
- Flux Image Automation instead of GitHub Actions tag commits
- progressive delivery or canary releases
- stricter NetworkPolicy model
- branch protection and required checks
