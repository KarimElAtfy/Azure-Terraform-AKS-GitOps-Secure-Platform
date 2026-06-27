# Core Layer

This Terraform layer creates the shared Azure resources required by AKS and the application platform.

## Responsibilities

- Create the main resource group
- Create the virtual network and AKS subnet
- Create Azure Container Registry
- Create Azure Key Vault
- Create Log Analytics
- Create managed identities
- Create Azure role assignments
- Create GitHub Actions OIDC federated credentials

## Usage

Create a local backend config from the example file:

```powershell
Copy-Item .\backend.hcl.example .\backend.hcl
notepad .\backend.hcl
```

Initialize Terraform with remote state:

```powershell
terraform init -backend-config=backend.hcl
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

## Outputs

The core layer exposes values consumed by the AKS layer and GitHub Actions, including:

- ACR name
- ACR login server
- Key Vault name
- Log Analytics workspace ID
- workload managed identity client ID
- GitHub Actions managed identity client ID
- tenant ID

## Files

```text
infra/core/
├── backend.hcl.example
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
└── versions.tf
```

## Notes

The real `backend.hcl` file is local-only and ignored by Git.

The real `terraform.tfvars` file is local-only and ignored by Git.
