# Troubleshooting

This page collects the commands used to debug the AKS GitOps platform.

## Pod Status

~~~powershell
kubectl get pods -n devsecops-api -o wide
kubectl describe pod <pod-name> -n devsecops-api
kubectl logs <pod-name> -n devsecops-api
kubectl logs <pod-name> -n devsecops-api --previous
kubectl get events -n devsecops-api --sort-by=.lastTimestamp
~~~

## Deployment and ReplicaSets

~~~powershell
kubectl describe deployment devsecops-api -n devsecops-api
kubectl get rs -n devsecops-api -o wide
kubectl rollout status deployment/devsecops-api -n devsecops-api
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.strategy.type}{'\n'}"
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
~~~

## Flux GitOps

~~~powershell
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A

flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system
flux reconcile helmrelease devsecops-api -n devsecops-api --with-source
~~~

## Helm

~~~powershell
helm list -n devsecops-api
helm history devsecops-api -n devsecops-api
helm get values devsecops-api -n devsecops-api -o yaml
helm get manifest devsecops-api -n devsecops-api
~~~

## Networking

~~~powershell
kubectl get svc -n devsecops-api
kubectl get endpoints -n devsecops-api
kubectl get networkpolicy -n devsecops-api
kubectl describe networkpolicy devsecops-api-allow-same-namespace -n devsecops-api
~~~

## Key Vault CSI and Workload Identity

~~~powershell
kubectl get secretproviderclass -n devsecops-api
kubectl describe secretproviderclass devsecops-api-keyvault -n devsecops-api
kubectl describe serviceaccount devsecops-api -n devsecops-api
~~~

Application validation:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/secret-status
~~~

Expected result:

~~~text
loaded = True
source = mounted_file
~~~

## ACR Image Checks

~~~powershell
az acr repository list --name <acr-name> -o table
az acr repository show-tags --name <acr-name> --repository devsecops-api -o table
docker buildx imagetools inspect <acr-login-server>/devsecops-api:<tag>
~~~

## Known Incident Writeups

- [001 - Single-node AKS rollout blocked by RollingUpdate surge](incidents/001-rollingupdate-insufficient-cpu.md)
