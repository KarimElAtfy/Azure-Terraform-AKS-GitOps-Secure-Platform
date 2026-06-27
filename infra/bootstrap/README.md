# Bootstrap Layer

This Terraform layer creates the Azure Storage Account and Blob Container used for remote Terraform state.

The bootstrap layer intentionally uses local state because the remote backend does not exist yet.

## Responsibilities

- Create the Terraform state resource group
- Create the Terraform state Storage Account
- Create the Blob container used by the `core` and `aks` layers

## Resources

- Resource Group: `rg-aks-gitops-tfstate-dev-gwc`
- Storage Account: generated with a globally unique suffix
- Blob Container: `tfstate`

## Usage

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

After apply, use the outputs to fill the `backend.hcl` files for the other Terraform layers.

## Outputs

- `storage_account_name`
- `container_name`
- `resource_group_name`

## Files

```text
infra/bootstrap/
├── main.tf
├── outputs.tf
├── terraform.tfvars.example
├── variables.tf
└── versions.tf
```

## Notes

Real Terraform state files and real backend configuration files must never be committed.

Commit only example files such as:

```text
terraform.tfvars.example
backend.hcl.example
```
