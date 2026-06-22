# Bootstrap Layer

Creates the Azure Storage Account and Blob Container used for Terraform remote state.

## Resources

- Resource Group: `rg-tfstate-aks-gitops-dev`
- Storage Account: generated globally unique name, for example `staksgitops<suffix>`
- Blob Container: `tfstate`

## Usage

```bash
terraform init
terraform plan
terraform apply
```

This layer uses **local state** intentionally — the state backend cannot store its own state.

## Outputs

- `storage_account_name`
- `container_name`
- `resource_group_name`

Use these values to create local `backend.hcl` files in the core and aks layers. Commit only `backend.hcl.example`; keep the real `backend.hcl` ignored.

## Files

_To be created in Phase 3._
