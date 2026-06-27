# Azure Terraform AKS GitOps Secure Platform

[![CI](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/ci.yml/badge.svg)](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/ci.yml)
[![Build and Push Image](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/build-image.yml/badge.svg)](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/build-image.yml)
[![Helm AKS GitOps Validation](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/helm-aks-validation.yml/badge.svg)](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/helm-aks-validation.yml)
[![Checkov IaC Scan](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/checkov.yml/badge.svg)](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/checkov.yml)
[![Trivy Security Scan](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/trivy.yml/badge.svg)](https://github.com/KarimElAtfy/Azure-Terraform-AKS-GitOps-Secure-Platform/actions/workflows/trivy.yml)

A complete AKS GitOps platform built with Terraform, Azure Kubernetes Service, Helm, Flux, GitHub Actions OIDC, Azure Container Registry, Azure Key Vault, Workload Identity, NetworkPolicy, Checkov and Trivy.

This project demonstrates how to provision Azure infrastructure with Terraform, build and publish a container image through GitHub Actions, and deploy the workload to AKS using Flux GitOps.

## What This Project Proves

This repository demonstrates a real end-to-end Cloud and DevOps workflow:

- Azure infrastructure provisioned with Terraform
- remote Terraform state bootstrap
- AKS cluster with OIDC issuer and Workload Identity enabled
- Azure Container Registry image publishing
- GitHub Actions authentication to Azure through OIDC, with no static Azure client secret
- multi-architecture Docker image build for amd64 and arm64
- Flux GitOps bootstrap and reconciliation
- Helm chart deployment through Flux HelmRelease
- Key Vault secret mounted into the pod through Secrets Store CSI Driver
- Kubernetes NetworkPolicy applied through GitOps
- CI validation for Python, Docker and Helm
- AKS GitOps Helm rendering validation
- IaC and repository security scanning with Checkov and Trivy
- real troubleshooting of a single-node AKS rollout issue

## Project Context

This is level 6 in my Azure and Terraform portfolio progression.

| Level | Project Focus | Main Milestone |
|---|---|---|
| L1 | Azure Terraform Linux VM | First Azure VM with Terraform |
| L2 | Secure two-tier infrastructure | Multi-tier networking |
| L3 | Secure private platform | Private compute, Bastion, Key Vault, monitoring |
| L4 | Load balanced web platform | Load balancing and availability |
| L5 | DevSecOps container platform | Container Apps, ACR, Key Vault, CI/CD |
| L6 | AKS GitOps secure platform | Kubernetes, Helm, Flux, Workload Identity |

The previous project used Azure Container Apps as a managed container platform. This project moves to AKS to expose the Kubernetes operational layer directly: pods, probes, rollout strategy, Helm packaging, GitOps reconciliation, Workload Identity, NetworkPolicy and cluster troubleshooting.

## Architecture

~~~mermaid
flowchart TB
    Dev[Developer] --> Repo[GitHub Repository]

    subgraph GitHub["GitHub"]
        Repo --> CI[CI Validation]
        Repo --> Build[Build and Push Image]
        Build --> TagUpdate[Update HelmRelease image tag]
    end

    subgraph Azure["Azure - Terraform Managed"]
        RG[Resource Group]
        VNet[Virtual Network]
        Subnet[AKS Subnet]
        ACR[Azure Container Registry]
        KV[Azure Key Vault]
        LA[Log Analytics]
        MI[Managed Identities]
        AKS[AKS Cluster]
    end

    subgraph Cluster["AKS - Flux and Helm Managed"]
        Flux[Flux Controllers]
        HR[HelmRelease]
        Chart[Helm Chart]
        NS[Namespace devsecops-api]
        SA[ServiceAccount]
        Deploy[Deployment]
        SVC[ClusterIP Service]
        SPC[SecretProviderClass]
        NP[NetworkPolicy]
        Pod[FastAPI Pod]
    end

    Build --> ACR
    TagUpdate --> Repo
    Flux --> Repo
    Flux --> HR
    HR --> Chart
    Chart --> NS
    Chart --> SA
    Chart --> Deploy
    Chart --> SVC
    Chart --> SPC
    Chart --> NP
    Deploy --> Pod
    AKS --> Cluster
    Pod --> ACR
    Pod --> KV
    AKS --> LA
    SA --> MI
~~~

## Deployment Flow

~~~mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant ACR as Azure Container Registry
    participant Flux as Flux
    participant Helm as Helm Controller
    participant AKS as AKS

    Dev->>GH: Push app or platform change
    GH->>GHA: Run validation workflows
    GHA->>ACR: Build and push image with git SHA tag
    GHA->>GH: Commit updated HelmRelease image tag with [skip ci]
    Flux->>GH: Detect new Git revision
    Flux->>Helm: Reconcile HelmRelease
    Helm->>AKS: Apply rendered Kubernetes manifests
    AKS->>ACR: Pull image
    AKS->>AKS: Run updated pod
~~~

## Tech Stack

| Area | Tools |
|---|---|
| Cloud | Azure |
| Infrastructure as Code | Terraform |
| Container Orchestration | Azure Kubernetes Service |
| Container Registry | Azure Container Registry |
| Packaging | Helm |
| GitOps | Flux v2 |
| CI/CD | GitHub Actions |
| Cloud Authentication | GitHub Actions OIDC |
| Secrets | Azure Key Vault |
| Pod Identity | AKS Workload Identity |
| Secret Mounting | Secrets Store CSI Driver |
| App | Python FastAPI |
| Container | Docker |
| Kubernetes Security | NetworkPolicy, securityContext |
| IaC Security | Checkov |
| Vulnerability / Secret / Misconfiguration Scan | Trivy |
| Observability | kubectl logs/events, Flux CLI, Helm CLI, Log Analytics basics |

## Repository Structure

~~~text
.
├── .github/
│   └── workflows/
│       ├── build-image.yml
│       ├── checkov.yml
│       ├── ci.yml
│       ├── helm-aks-validation.yml
│       └── trivy.yml
├── app/
│   ├── Dockerfile
│   ├── main.py
│   ├── requirements.txt
│   └── tests/
├── charts/
│   └── devsecops-api/
│       ├── Chart.yaml
│       ├── values.yaml
│       ├── values-dev.yaml
│       ├── values-aks.yaml
│       ├── values-aks-keyvault.yaml
│       └── templates/
├── clusters/
│   └── dev/
│       ├── flux-system/
│       ├── apps/
│       ├── policies/
│       └── kustomization.yaml
├── docs/
│   ├── architecture.md
│   ├── cost-and-cleanup.md
│   ├── decisions.md
│   ├── deployment-guide.md
│   ├── gitops-flow.md
│   ├── incidents/
│   ├── local-kubernetes-lab.md
│   ├── observability.md
│   ├── phase-0-review.md
│   ├── security-model.md
│   └── troubleshooting.md
├── infra/
│   ├── bootstrap/
│   ├── core/
│   └── aks/
├── scripts/
├── LICENSE
├── README.md
└── pytest.ini
~~~

## Terraform Layering

The Terraform code is split into three layers.

~~~text
infra/bootstrap/
infra/core/
infra/aks/
~~~

| Layer | Purpose |
|---|---|
| bootstrap | Creates Terraform remote state storage |
| core | Creates shared Azure resources such as ACR, Key Vault, Log Analytics and identities |
| aks | Creates AKS and connects it to the core resources |

Deployment order:

~~~text
bootstrap → core → aks
~~~

Destroy order:

~~~text
aks → core → bootstrap
~~~

## GitOps Model

Flux watches:

~~~text
clusters/dev/
~~~

The application is deployed through:

~~~text
clusters/dev/apps/helmrelease.yaml
~~~

The Helm chart lives in the same repository:

~~~text
charts/devsecops-api/
~~~

Because the chart is stored in this repository, the project uses:

~~~text
GitRepository + HelmRelease
~~~

It does not use a HelmRepository in v1 because the chart is not published to an external Helm or OCI registry.

## Image Automation

The image build workflow:

1. builds the FastAPI Docker image
2. pushes it to Azure Container Registry
3. tags it with:
   - short git SHA
   - latest
4. updates the GitOps HelmRelease image tag
5. commits the tag update with `[skip ci]`
6. lets Flux reconcile the updated desired state

The deployed image uses an immutable git SHA tag instead of relying only on `latest`.

## Application Endpoints

The FastAPI app exposes diagnostic endpoints used for validation.

| Endpoint | Purpose |
|---|---|
| `/health` | Liveness check |
| `/ready` | Readiness check |
| `/version` | Shows app version, git SHA and environment |
| `/config` | Shows Helm-provided app configuration |
| `/secret-status` | Shows whether the Key Vault secret is loaded without exposing its value |
| `/pod-info` | Shows Kubernetes Downward API metadata |
| `/error-test` | Intentional error endpoint for log validation |

## Security Model

Implemented controls:

- GitHub Actions authenticates to Azure through OIDC
- no Azure client secret stored in GitHub
- Terraform state and backend files are not committed
- app secrets are stored in Azure Key Vault
- pod reads secret through Workload Identity and CSI Driver
- secret value is never exposed by the application
- AKS pulls images from ACR through managed identity permissions
- Kubernetes NetworkPolicy restricts app ingress in the namespace
- Helm chart supports securityContext and resource limits
- Checkov scans IaC and Kubernetes-related configuration
- Trivy scans repository vulnerabilities, secrets and misconfigurations

More detail:

- [Security Model](docs/security-model.md)
- [Architecture Decisions](docs/decisions.md)

## Single-Node AKS Rollout Strategy

The dev AKS cluster is intentionally cost-conscious and runs on a single small node.

During testing, the default RollingUpdate strategy caused a real rollout problem:

~~~text
old pod stayed running
new pod tried to schedule
node did not have enough CPU for both pods
new pod stayed Pending
Helm timed out and rolled back
~~~

The fix was to make the Helm chart support configurable deployment strategies and use this value for AKS dev:

~~~yaml
deploymentStrategy:
  type: Recreate
~~~

This is documented in:

- [Incident 001: Single-node AKS rollout blocked by RollingUpdate surge](docs/incidents/001-rollingupdate-insufficient-cpu.md)

## Validation

Check Flux:

~~~powershell
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
~~~

Check Helm:

~~~powershell
helm list -n devsecops-api
helm history devsecops-api -n devsecops-api
~~~

Check AKS workload:

~~~powershell
kubectl get pods -n devsecops-api -o wide
kubectl rollout status deployment/devsecops-api -n devsecops-api
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.strategy.type}{'\n'}"
~~~

Check NetworkPolicy:

~~~powershell
kubectl get networkpolicy -n devsecops-api
~~~

Check Key Vault secret mount through the app:

~~~powershell
kubectl port-forward -n devsecops-api svc/devsecops-api 8080:8000
~~~

In another terminal:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/secret-status
~~~

Expected result:

~~~text
loaded = True
source = mounted_file
~~~

## GitHub Actions Workflows

| Workflow | Purpose |
|---|---|
| CI | Runs Python tests, Docker build and Helm validation |
| Build and Push Image | Builds multi-arch image, pushes to ACR and updates GitOps image tag |
| Helm AKS GitOps Validation | Validates AKS-specific Helm rendering |
| Checkov IaC Scan | Scans IaC and Kubernetes configuration |
| Trivy Security Scan | Scans vulnerabilities, secrets and misconfigurations |

## Documentation

| Document | Purpose |
|---|---|
| [Architecture](docs/architecture.md) | Full platform architecture |
| [Deployment Guide](docs/deployment-guide.md) | End-to-end deployment process |
| [GitOps Flow](docs/gitops-flow.md) | How Flux reconciles the app |
| [Security Model](docs/security-model.md) | Identity, secrets and security controls |
| [Observability](docs/observability.md) | Logs, events, endpoints and runtime checks |
| [Troubleshooting](docs/troubleshooting.md) | Debug commands |
| [Cost and Cleanup](docs/cost-and-cleanup.md) | Cost notes and destroy order |
| [Architecture Decisions](docs/decisions.md) | ADR-style decision records |
| [Local Kubernetes Lab](docs/local-kubernetes-lab.md) | Local kind validation |
| [Incident 001](docs/incidents/001-rollingupdate-insufficient-cpu.md) | Real AKS rollout incident |

## Cost Warning

AKS nodes cost money while they exist, even if the app is idle.

Main cost sources:

- AKS node VM
- ACR Basic
- Log Analytics ingestion
- Key Vault operations
- Terraform state Storage Account
- optional public IP or LoadBalancer if added later

For cheapest validation, this project uses port-forward instead of a public LoadBalancer.

Always destroy expensive resources when finished validating.

See:

- [Cost and Cleanup](docs/cost-and-cleanup.md)

## Cleanup

Recommended cleanup order:

~~~powershell
flux uninstall --silent
~~~

Then destroy Terraform layers in reverse order:

~~~powershell
cd infra/aks
terraform destroy

cd ../core
terraform destroy

cd ../bootstrap
terraform destroy
~~~

The bootstrap state storage can optionally be kept if you plan to redeploy later.

## Known Limitations

This is a dev/portfolio project, not a production-grade platform.

Current limitations:

- single-node AKS cluster
- public AKS API server
- no private cluster
- no private endpoints
- no Azure Firewall
- no NAT Gateway
- no service mesh
- no multi-environment promotion
- no managed Prometheus or Grafana in v1
- no canary/progressive deployment in v1
- validation primarily through port-forward
- security scans may initially run in observation mode while findings are reviewed

## Future Improvements

Possible future improvements:

- staging and production environments
- private AKS cluster
- private endpoints for ACR and Key Vault
- managed Prometheus and Grafana
- Kyverno or OPA Gatekeeper policy enforcement
- Flux Image Automation
- canary or progressive delivery
- stricter default-deny NetworkPolicies
- branch protection with required checks
- make Checkov and Trivy fully blocking after findings are reviewed

## Author

Karim El Atfy

- Portfolio: [kaystack.dev](https://kaystack.dev)
- GitHub: [github.com/KarimElAtfy](https://github.com/KarimElAtfy)

## License

MIT
