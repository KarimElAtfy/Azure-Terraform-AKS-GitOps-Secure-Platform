# Troubleshooting

## Essential Commands

### Pod Status
```bash
kubectl get pods -n devsecops-api
kubectl describe pod <pod-name> -n devsecops-api
kubectl logs <pod-name> -n devsecops-api
kubectl logs <pod-name> -n devsecops-api --previous
kubectl get events -n devsecops-api --sort-by='.lastTimestamp'
```

### Services and Networking
```bash
kubectl get svc -n devsecops-api
kubectl get ingress -n devsecops-api
kubectl get endpoints -n devsecops-api
kubectl get networkpolicy -n devsecops-api
```

### Flux GitOps
```bash
flux get kustomizations
flux get helmreleases -n devsecops-api
flux get sources git
flux logs
flux reconcile kustomization flux-system
flux reconcile helmrelease devsecops-api -n devsecops-api
```

### AKS and Azure
```bash
az aks show --resource-group <rg-name> --name <aks-name> -o table
az acr repository list --name <acr-name> -o table
az acr repository show-tags --name <acr-name> --repository devsecops-api -o table
az role assignment list --scope <resource-id> -o table
az keyvault secret show --vault-name <vault-name> --name app-demo-secret --query "name"
```

### Node and Cluster Health
```bash
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes
kubectl top pods -n devsecops-api
```

## Common Issues

See the incident docs in [incidents/](incidents/) for detailed writeups:

- [001 - ImagePullBackOff](incidents/001-imagepullbackoff.md)
- [002 - Readiness Probe Failed](incidents/002-readiness-probe-failed.md)
- [003 - Secret Mount Failed](incidents/003-secret-mount-failed.md)
