# Core Layer

Creates the shared Azure resources that AKS and the application depend on.

## Resources

- Resource Group
- Virtual Network + AKS Subnet
- Azure Container Registry (Basic, globally unique name)
- Azure Key Vault (globally unique name, RBAC authorization)
- Log Analytics Workspace
- User-Assigned Managed Identity
- Key Vault role assignment for the workload managed identity, where possible before AKS federation

## Usage

```bash
cp backend.hcl.example backend.hcl
# edit backend.hcl with bootstrap outputs
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Files

_To be created in Phase 3._
