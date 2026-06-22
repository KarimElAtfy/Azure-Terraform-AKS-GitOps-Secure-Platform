# Deployment Guide

> Work-in-progress deployment notes. Local Kubernetes validation is documented separately; Azure steps are filled in as each Terraform/GitOps layer is built.

## Prerequisites

- Azure subscription with sufficient quota in `germanywestcentral`
- Azure CLI installed and logged in (`az login`)
- Terraform >= 1.5
- Docker
- Python 3.12+
- kubectl
- Helm 3
- Flux CLI
- Git + GitHub account with this repository forked/cloned

## Phase 1: Check Azure Quota

Before deploying anything, verify your subscription can support AKS:

```bash
# Check VM usage/quota in target region
az vm list-usage --location germanywestcentral -o table

# Check available VM SKUs
az vm list-skus --location germanywestcentral --resource-type virtualMachines -o table | grep -Ei "Standard_B|Standard_D|Standard_F"

# Check available AKS versions
az aks get-versions --location germanywestcentral -o table
```



Do not choose the final AKS node size before this check. `Standard_B2s` is a target candidate only if it is available, supported for AKS in the region, and within quota.

## Phase 1.5: Backend Configuration Convention

For remote-state layers, keep the real backend config local and ignored:

```bash
cp backend.hcl.example backend.hcl
# edit backend.hcl with the bootstrap outputs
terraform init -backend-config=backend.hcl
```

Do not commit the real `backend.hcl`. Commit only `backend.hcl.example`.

## Phase 2: Bootstrap (Terraform Remote State)

_Planned: add commands and validation output when this layer is implemented._

## Phase 3: Core Resources

_Planned: add commands and validation output when this layer is implemented._

## Phase 4: AKS Cluster

_Planned: add commands and validation output when the AKS layer is implemented._

## Phase 5: Flux Bootstrap

_Planned: add commands and validation output when Flux and the app deployment are wired._

## Phase 6: App Deployment

_Planned: add commands and validation output when Flux and the app deployment are wired._

## Validation

_Planned: keep this as the final checklist for Azure-side validation._

## Cleanup

See [cost-and-cleanup.md](cost-and-cleanup.md).
