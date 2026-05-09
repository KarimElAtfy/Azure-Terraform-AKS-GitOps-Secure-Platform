# Incident 003: Secret Mount / Access Failed

> To be completed with real debugging experience during Phase 7.

## Symptoms

- Pod fails to start or stays in `ContainerCreating`.
- `kubectl describe pod` shows volume mount errors related to secrets-store-csi.
- `/secret-status` returns `loaded: false`.
- Events mention `FailedMount` or `SecretProviderClass` errors.

## Investigation Commands

```bash
kubectl get pods -n devsecops-api
kubectl describe pod <pod-name> -n devsecops-api
kubectl get events -n devsecops-api --sort-by='.lastTimestamp'
kubectl get secretproviderclass -n devsecops-api
kubectl describe secretproviderclass <name> -n devsecops-api

# Check Workload Identity federation
az identity federated-credential list --identity-name <mi-name> --resource-group <rg-name> -o table

# Check Key Vault role assignment
az role assignment list --scope <keyvault-id> -o table

# Check the secret exists
az keyvault secret show --vault-name <vault-name> --name app-demo-secret --query "name"
```

## Possible Root Causes

1. **Federated credential misconfigured** — the ServiceAccount name/namespace doesn't match the federation.
2. **Missing Key Vault role** — the Managed Identity doesn't have `Key Vault Secrets User` on the vault.
3. **Secret doesn't exist** — the secret hasn't been created in Key Vault.
4. **CSI driver not enabled** — AKS addon `azure-keyvault-secrets-provider` is not installed.
5. **Wrong tenant/client ID** — SecretProviderClass references incorrect identity details.

## Fix

_To be completed with actual resolution steps._

## Prevention

- Verify federated credential matches the exact ServiceAccount name and namespace.
- Verify the Managed Identity has the correct role assignment on Key Vault.
- Test secret existence with `az keyvault secret show` before deploying.
- Include Key Vault access validation in smoke tests.
