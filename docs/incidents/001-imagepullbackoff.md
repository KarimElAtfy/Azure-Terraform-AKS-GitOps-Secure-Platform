# Incident 001: ImagePullBackOff

> Draft runbook. I will add real AKS command output after the image build and ACR flow are tested.

## Symptoms

- Pod stays in `ImagePullBackOff` or `ErrImagePull` status.
- `kubectl describe pod` shows pull errors.

## Investigation Commands

```bash
kubectl get pods -n devsecops-api
kubectl describe pod <pod-name> -n devsecops-api
kubectl get events -n devsecops-api --sort-by='.lastTimestamp'
az acr repository show-tags --name <acr-name> --repository devsecops-api -o table
az role assignment list --assignee <kubelet-identity-id> -o table
```

## Possible Root Causes

1. **Wrong image tag**: the tag in the HelmRelease doesn't match any tag in ACR.
2. **Missing ACR pull permission**: the AKS kubelet identity doesn't have AcrPull on the registry.
3. **Wrong ACR login server**: typo in the image repository URL.
4. **ACR doesn't exist**: core Terraform wasn't applied, or was destroyed.

## Fix

_Planned: add the exact fix used during the first real ACR/AKS image-pull failure._

## Prevention

- Always verify the image tag exists in ACR before updating the HelmRelease.
- Use the `az acr repository show-tags` command in smoke tests.
- Ensure Terraform assigns AcrPull before deploying workloads.
