# Deployment Guide

This guide explains how to deploy the Azure Terraform AKS GitOps Secure Platform from an empty Azure environment to a working AKS GitOps application.

The project is intentionally split into two ownership layers:

~~~text
Terraform owns Azure infrastructure.
Flux + Helm own Kubernetes workloads.
~~~

## Deployment Flow

~~~mermaid
flowchart TD
    A[Local workstation] --> B[Terraform bootstrap]
    B --> C[Remote state storage]
    C --> D[Terraform core]
    D --> E[ACR, Key Vault, Log Analytics, identities]
    E --> F[Terraform AKS]
    F --> G[AKS cluster with OIDC + Workload Identity]
    G --> H[GitHub Actions OIDC]
    H --> I[Build image and push to ACR]
    I --> J[Update HelmRelease image tag in Git]
    J --> K[Flux watches clusters/dev]
    K --> L[Flux reconciles HelmRelease]
    L --> M[AKS runs devsecops-api]
    M --> N[App reads Key Vault secret through CSI + Workload Identity]
~~~

## Repository Layout Used During Deployment

~~~text
infra/
├── bootstrap/      Terraform state storage layer
├── core/           Shared Azure resources
└── aks/            AKS cluster layer

charts/
└── devsecops-api/  Helm chart for the FastAPI app

clusters/
└── dev/            Flux GitOps desired state

.github/
└── workflows/      CI, image build, Checkov, Trivy, Helm validation
~~~

## Prerequisites

Required local tools:

- Azure CLI
- Terraform >= 1.5
- Docker
- Python 3.12+
- kubectl
- Helm 3
- Flux CLI
- GitHub CLI
- Git

Azure requirements:

- Azure subscription
- enough quota in the selected region
- permission to create resource groups, managed identities, AKS, ACR, Key Vault and role assignments

Project default region:

~~~text
germanywestcentral
~~~

## Important Safety Rules

Do not commit:

- terraform.tfvars
- backend.hcl
- Terraform state files
- .terraform directories
- kubeconfig files
- Azure credentials
- Key Vault secret values
- GitHub tokens

Only commit example files such as:

~~~text
backend.hcl.example
terraform.tfvars.example
~~~

## Step 1: Check Azure Quota

Before creating AKS, check available quota and supported VM SKUs.

~~~powershell
az vm list-usage --location germanywestcentral -o table
az vm list-skus --location germanywestcentral --resource-type virtualMachines -o table
az aks get-versions --location germanywestcentral -o table
~~~

The project is designed for a small single-node dev cluster. The exact VM size depends on regional quota and SKU availability.

In this implementation, the cluster used a small ARM64 node because the subscription quota did not allow the originally preferred x86 SKU.

## Step 2: Bootstrap Terraform Remote State

The bootstrap layer creates the storage account and blob container used for remote Terraform state.

~~~powershell
cd infra/bootstrap

terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
~~~

Expected outputs include the backend configuration values needed by the other Terraform layers.

The bootstrap layer intentionally uses local state because the remote backend cannot store its own state before it exists.

## Step 3: Configure Backend for Core

Copy the backend example file and fill it with bootstrap outputs.

~~~powershell
cd ../core

Copy-Item .\backend.hcl.example .\backend.hcl
notepad .\backend.hcl
~~~

Then initialize the core layer with remote state:

~~~powershell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
terraform apply
~~~

The core layer creates shared Azure resources such as:

- main resource group
- virtual network
- AKS subnet
- Azure Container Registry
- Azure Key Vault
- Log Analytics workspace
- user-assigned managed identity for the workload
- GitHub Actions managed identity
- role assignments
- federated credentials for GitHub Actions

Useful outputs:

~~~powershell
terraform output
terraform output -raw acr_login_server
terraform output -raw key_vault_name
terraform output -raw workload_identity_client_id
terraform output -raw tenant_id
~~~

## Step 4: Configure Backend for AKS

Copy and edit the backend config for the AKS layer.

~~~powershell
cd ../aks

Copy-Item .\backend.hcl.example .\backend.hcl
notepad .\backend.hcl
~~~

Initialize and apply:

~~~powershell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
terraform apply
~~~

The AKS layer creates:

- AKS cluster
- system node pool
- OIDC issuer
- Workload Identity support
- Key Vault CSI driver addon
- Log Analytics integration
- AcrPull permission for the kubelet identity
- federated identity credential for the application ServiceAccount

## Step 5: Connect kubectl to AKS

After AKS is created, fetch cluster credentials.

~~~powershell
az aks get-credentials `
  --resource-group <aks-resource-group> `
  --name <aks-cluster-name> `
  --overwrite-existing
~~~

Validate access:

~~~powershell
kubectl config current-context
kubectl get nodes -o wide
kubectl get pods -n kube-system
~~~

Expected result:

~~~text
node Ready
system pods Running
~~~

## Step 6: Configure GitHub Repository Variables

The image build workflow uses GitHub Actions OIDC to authenticate to Azure.

Required GitHub repository variables:

~~~text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
ACR_NAME
ACR_LOGIN_SERVER
~~~

These are repository variables, not static client secrets.

Do not create or store AZURE_CLIENT_SECRET.

## Step 7: Build and Push the Application Image

The workflow:

~~~text
.github/workflows/build-image.yml
~~~

builds and pushes the Docker image to ACR.

It publishes two tags:

~~~text
<short-git-sha>
latest
~~~

The GitOps deployment uses the immutable short Git SHA tag.

Check tags in ACR:

~~~powershell
az acr repository show-tags `
  --name <acr-name> `
  --repository devsecops-api `
  -o table
~~~

Check multi-arch support:

~~~powershell
docker buildx imagetools inspect <acr-login-server>/devsecops-api:<tag>
~~~

Expected platforms:

~~~text
linux/amd64
linux/arm64
~~~

## Step 8: Bootstrap Flux

Flux is bootstrapped to the `clusters/dev` path.

Authenticate GitHub CLI first:

~~~powershell
gh auth status
~~~

Set the token for Flux bootstrap:

~~~powershell
Remove-Item Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue
$env:GITHUB_TOKEN = (gh auth token).Trim()
~~~

Bootstrap Flux:

~~~powershell
flux bootstrap github `
  --owner=KarimElAtfy `
  --repository=Azure-Terraform-AKS-GitOps-Secure-Platform `
  --branch=main `
  --path=clusters/dev `
  --personal `
  --private=false
~~~

Validate Flux:

~~~powershell
kubectl get pods -n flux-system
flux get sources git -A
flux get kustomizations -A
~~~

Expected result:

~~~text
Flux controllers Running
GitRepository Ready=True
Kustomization Ready=True
~~~

## Step 9: Deploy the Application through GitOps

The app is declared in:

~~~text
clusters/dev/apps/helmrelease.yaml
~~~

Flux reconciles that HelmRelease and renders:

~~~text
charts/devsecops-api/
~~~

Force reconciliation:

~~~powershell
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system
flux reconcile helmrelease devsecops-api -n devsecops-api --with-source
~~~

Validate:

~~~powershell
flux get helmreleases -A
helm list -n devsecops-api
kubectl get pods -n devsecops-api -o wide
~~~

Expected result:

~~~text
HelmRelease Ready=True
Helm release deployed
Pod Running 1/1
~~~

## Step 10: Create the Demo Key Vault Secret

Create the demo secret in Key Vault.

Do not commit the secret value to Git.

~~~powershell
az keyvault secret set `
  --vault-name <key-vault-name> `
  --name app-demo-secret `
  --value "<demo-secret-value>"
~~~

Validate that the secret exists without printing its value:

~~~powershell
az keyvault secret show `
  --vault-name <key-vault-name> `
  --name app-demo-secret `
  --query "name" `
  -o tsv
~~~

Expected result:

~~~text
app-demo-secret
~~~

## Step 11: Validate Key Vault CSI and Workload Identity

Check Kubernetes resources:

~~~powershell
kubectl get serviceaccount -n devsecops-api
kubectl get secretproviderclass -n devsecops-api
kubectl describe secretproviderclass devsecops-api-keyvault -n devsecops-api
~~~

Check app endpoint through port-forward:

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
path = /mnt/secrets-store/app-demo-secret
~~~

The endpoint must never return the secret value.

## Step 12: Validate NetworkPolicy

Check the deployed policy:

~~~powershell
kubectl get networkpolicy -n devsecops-api
kubectl describe networkpolicy devsecops-api-allow-same-namespace -n devsecops-api
~~~

Expected policy:

~~~text
devsecops-api-allow-same-namespace
~~~

The policy allows inbound traffic to the app pods from the same namespace on TCP port 8000.

## Step 13: Final Runtime Smoke Test

Start port-forward:

~~~powershell
kubectl port-forward -n devsecops-api svc/devsecops-api 8080:8000
~~~

In another terminal:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/health
Invoke-RestMethod http://127.0.0.1:8080/ready
Invoke-RestMethod http://127.0.0.1:8080/version
Invoke-RestMethod http://127.0.0.1:8080/config
Invoke-RestMethod http://127.0.0.1:8080/secret-status
Invoke-RestMethod http://127.0.0.1:8080/pod-info
~~~

Expected validation:

~~~text
/health returns healthy
/ready returns ready
/version returns the deployed git SHA and aks-gitops environment
/config returns Helm-provided configuration
/secret-status returns loaded=True
/pod-info returns pod name, namespace and node name
~~~

## Step 14: Validate Rollout Strategy

Because this is a single-node dev AKS cluster, the app uses Recreate instead of RollingUpdate.

~~~powershell
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.strategy.type}{'\n'}"
~~~

Expected result:

~~~text
Recreate
~~~

This prevents a failed rollout caused by Kubernetes trying to temporarily schedule both the old and new pod on the same small node.

## Step 15: Validate CI and Security Scans

Check workflow runs:

~~~powershell
gh run list --limit 15
gh run list --workflow "CI" --limit 3
gh run list --workflow "Helm AKS GitOps Validation" --limit 3
gh run list --workflow "Checkov IaC Scan" --limit 3
gh run list --workflow "Trivy Security Scan" --limit 3
~~~

Expected result:

~~~text
completed success
~~~

## Troubleshooting Pointers

Useful docs:

~~~text
docs/troubleshooting.md
docs/incidents/001-rollingupdate-insufficient-cpu.md
docs/gitops-flow.md
docs/security-model.md
docs/observability.md
~~~

Common debugging flow:

~~~text
GitHub Actions
→ ACR image tag
→ Flux source
→ Flux kustomization
→ HelmRelease
→ Deployment
→ ReplicaSet
→ Pod events
→ Application endpoint
~~~

## Cleanup

Destroy expensive resources when validation is complete.

Recommended order:

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

The bootstrap layer can optionally be kept if you want to preserve remote state storage between sessions.

## Final Expected State

A successful deployment should have:

~~~text
GitHub Actions workflows green
ACR image pushed with immutable git SHA tag
Flux GitRepository Ready=True
Flux Kustomization Ready=True
HelmRelease Ready=True
Helm release deployed
AKS pod Running 1/1
Deployment strategy Recreate
NetworkPolicy present
Key Vault secret mounted through CSI
/secret-status loaded=True
/version reports the deployed git SHA
~~~
