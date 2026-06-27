# AKS Layer

This Terraform layer creates the Azure Kubernetes Service cluster and connects it to the shared platform resources from the core layer.

## Responsibilities

- Create the AKS cluster
- Create the system node pool
- Enable OIDC issuer
- Enable AKS Workload Identity
- Enable the Key Vault CSI driver addon
- Connect AKS to Log Analytics
- Grant ACR pull access to the kubelet identity
- Create the federated identity credential for the application ServiceAccount

## Cost-Conscious Design

This is a dev/portfolio AKS cluster.

The cluster is intentionally small and single-node to reduce cost.

Because the cluster is single-node, the application uses a `Recreate` rollout strategy in the AKS GitOps environment to avoid failed rollouts caused by insufficient temporary scheduling capacity.

## Usage

Check regional quota and SKU availability first:

```powershell
az vm list-usage --location germanywestcentral -o table
az vm list-skus --location germanywestcentral --resource-type virtualMachines -o table
az aks get-versions --location germanywestcentral -o table
```

Create a local backend config from the example file:

```powershell
Copy-Item .\backend.hcl.example .\backend.hcl
notepad .\backend.hcl
```

Initialize and apply:

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## Files

```text
infra/aks/
├── backend.hcl.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
└── versions.tf
```

## Notes

This layer creates the cluster only.

Kubernetes workloads are deployed by Flux and Helm from the `clusters/dev` and `charts/devsecops-api` paths.
