# AKS Layer

Creates the AKS cluster and connects it to core resources.

## Resources

- AKS Cluster (Free tier, public API)
- System node pool (1 node, smallest available AKS-supported dev SKU; Standard_B2s is only a target candidate)
- OIDC Issuer
- Workload Identity
- Key Vault CSI Driver addon
- Log Analytics integration
- ACR pull role for kubelet identity
- Federated identity credential for workload identity

## Usage

```bash
# Check quota first!
az vm list-usage --location germanywestcentral -o table
az vm list-skus --location germanywestcentral --resource-type virtualMachines -o table | grep -Ei "Standard_B|Standard_D|Standard_F"

cp backend.hcl.example backend.hcl
# edit backend.hcl with bootstrap outputs
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

## Files

_To be created in Phase 4._
