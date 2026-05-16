# Cost and Cleanup

## Expected Cost Sources

This project is intentionally dev/test and cost-conscious. Exact prices change by Azure region, SKU, currency and pricing updates, so treat any number as an estimate and verify with the Azure Pricing Calculator before deployment.

| Resource | Cost Role | Notes |
|----------|-----------|-------|
| AKS node VM | Main cost | Depends on selected VM size. Destroy when not validating. |
| Public IP / LoadBalancer | Optional cost | Created by LoadBalancer Services such as ingress-nginx. Avoid for cheapest v1 validation. |
| ACR Basic | Small recurring cost | Can be kept if desired, but still review monthly costs. |
| Key Vault | Usually tiny in dev | Operation-based pricing; do not store real secrets. |
| Log Analytics | Can grow with ingestion | Keep logs minimal and review workspace usage. |
| Storage Account for Terraform state | Usually tiny | Safe to keep between sessions if desired. |

The important rule: **AKS nodes cost money while they exist, even if the app is idle.**

## Workflow: Apply → Validate → Document → Destroy

The intended workflow is simple:

1. `terraform apply` the needed layer.
2. Deploy or reconcile the app.
3. Validate with `kubectl`, Flux commands and smoke tests.
4. Capture screenshots/outputs for documentation.
5. Destroy expensive resources when finished.

Do not leave the AKS cluster running overnight unless you intentionally accept the cost.

## How to Destroy

Destroy in reverse order of creation:

```bash
# 1. Remove Flux while the cluster still exists
flux uninstall --silent

# 2. Destroy AKS
cd infra/aks
terraform destroy -auto-approve

# 3. Destroy core resources
cd ../core
terraform destroy -auto-approve

# 4. Destroy bootstrap only if you no longer need remote state storage
cd ../bootstrap
terraform destroy -auto-approve
```

## How to Verify Everything Is Gone

```bash
# List resource groups: the project RG should be gone
az group list -o table | grep aks-gitops

# Check for orphaned resources tagged by the project
az resource list --query "[?tags.project=='aks-gitops']" -o table
```

Also check the Azure Portal manually. Look for:

- lingering public IPs
- orphaned managed disks
- orphaned load balancers
- Log Analytics workspaces
- Network Watcher resource groups created automatically by Azure

## Reminders

- AKS nodes cost money even when idle.
- A LoadBalancer service creates Azure networking resources that may cost money.
- Use `kubectl port-forward` instead of LoadBalancer for cheapest validation.
- Keep Log Analytics ingestion low in v1.
- ACR Basic and the Terraform state Storage Account are small recurring costs, but still not literally free.
