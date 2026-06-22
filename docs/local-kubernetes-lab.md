# Local Kubernetes Lab

This document records the local Kubernetes validation for the AKS GitOps Secure Platform project.

The goal of this lab is to prove that the FastAPI application can run as a Kubernetes workload before moving to Azure AKS.

## Environment

- Local Kubernetes: kind
- Cluster name: `aks-gitops-local`
- Namespace: `devsecops-api`
- Image: `devsecops-api:local`
- Deployment method: Helm
- Chart path: `charts/devsecops-api`
- Values file: `charts/devsecops-api/values-dev.yaml`

## Why This Lab Exists

Before deploying to AKS, the application and Helm chart are tested locally.

This validates:

- the Docker image can run in Kubernetes
- the Helm chart renders valid manifests
- the Deployment creates a healthy pod
- liveness and readiness probes pass
- ConfigMap values reach the application
- Kubernetes Downward API values reach the application
- the Service can be reached with `kubectl port-forward`
- application logs are visible through `kubectl logs`

## Preflight

```powershell
kubectl config use-context kind-aks-gitops-local
kubectl cluster-info
kubectl get nodes -o wide
```

Expected result:

```text
Kubernetes control plane is running
aks-gitops-local-control-plane   Ready
```

## Load Local Docker Image Into kind

kind nodes do not automatically see every Docker image from the host.

The local image must be loaded into the cluster:

```powershell
docker images devsecops-api
kind load docker-image devsecops-api:local --name aks-gitops-local
```

Expected result:

```text
Image: "devsecops-api:local" ... loading...
```

## Deploy With Helm

```powershell
helm upgrade --install devsecops-api .\charts\devsecops-api `
  -f .\charts\devsecops-api\values-dev.yaml `
  -n devsecops-api `
  --create-namespace
```

Expected result:

```text
STATUS: deployed
DESCRIPTION: Upgrade complete
```

## Validate Helm Release

```powershell
helm list -n devsecops-api
```

Expected result:

```text
devsecops-api   devsecops-api   deployed   devsecops-api-0.1.0
```

## Validate Kubernetes Resources

```powershell
kubectl get all -n devsecops-api
kubectl get pods -n devsecops-api -o wide
```

Expected result:

```text
pod/devsecops-api-...   1/1   Running   0
deployment.apps/devsecops-api   1/1
service/devsecops-api   ClusterIP   8000/TCP
```

## Port Forward

```powershell
kubectl port-forward service/devsecops-api 8000:8000 -n devsecops-api
```

Expected result:

```text
Forwarding from 127.0.0.1:8000 -> 8000
```

## Endpoint Validation

Run these from a second terminal:

```powershell
curl.exe http://127.0.0.1:8000/health
curl.exe http://127.0.0.1:8000/ready
curl.exe http://127.0.0.1:8000/version
curl.exe http://127.0.0.1:8000/config
curl.exe http://127.0.0.1:8000/secret-status
curl.exe http://127.0.0.1:8000/pod-info
curl.exe http://127.0.0.1:8000/error-test
```

Observed successful responses:

```json
{"status":"healthy"}
```

```json
{"status":"ready"}
```

```json
{"app_name":"devsecops-api","app_version":"0.1.0","git_sha":"local-helm-test","environment":"local-helm"}
```

```json
{"app_name":"devsecops-api","environment":"local-helm","config_message":"Running through Helm local values","log_level":"debug"}
```

```json
{"loaded":false,"source":"none"}
```

```json
{"pod_name":"devsecops-api-5b7fcbf66-v7m5j","pod_namespace":"devsecops-api","node_name":"aks-gitops-local-control-plane"}
```

The `/error-test` endpoint intentionally returns HTTP 500:

```json
{"detail":"Intentional test error for observability validation."}
```

This is expected and is used to validate application logs and troubleshooting workflows.

## Logs

```powershell
kubectl logs deployment/devsecops-api -n devsecops-api
```

Observed logs include:

```text
Application startup complete.
GET /health HTTP/1.1" 200 OK
GET /ready HTTP/1.1" 200 OK
GET /version HTTP/1.1" 200 OK
GET /config HTTP/1.1" 200 OK
GET /pod-info HTTP/1.1" 200 OK
GET /error-test HTTP/1.1" 500 Internal Server Error
```

## Current Limitations

- This is a local kind cluster, not AKS.
- The image is loaded manually into kind.
- No ACR is used yet.
- No Flux is used yet.
- No Key Vault secret is mounted yet.
- Ingress, HPA and SecretProviderClass are available in the chart but disabled by default.

## Result

The local Kubernetes validation is successful.

The application runs correctly as a Kubernetes workload using Helm, with health probes, readiness probes, ConfigMap configuration, pod metadata and basic logging working as expected.

## Helper Scripts

The local Kubernetes workflow can be repeated with PowerShell helper scripts.

### Build and Load Image

```powershell
.\scripts\local-kind-load-image.ps1
```

This script:

- builds the local Docker image `devsecops-api:local`
- checks that the kind cluster `aks-gitops-local` exists
- loads the image into the kind cluster

### Deploy With Helm

```powershell
.\scripts\local-kind-deploy.ps1
```

This script:

- runs `helm upgrade --install`
- uses `charts/devsecops-api/values-dev.yaml`
- deploys to the `devsecops-api` namespace
- prints Helm release status
- prints Kubernetes resources and pod status

### Test Endpoints

```powershell
.\scripts\local-kind-test.ps1
```

This script:

- starts a temporary `kubectl port-forward`
- tests `/health`, `/ready`, `/version`, `/config`, `/secret-status`, `/pod-info` and `/error-test`
- prints recent application logs
- stops the port-forward process automatically

### Cleanup

```powershell
.\scripts\local-kind-cleanup.ps1
```

This script:

- uninstalls the Helm release if it exists
- deletes the `devsecops-api` namespace if it exists
- keeps the kind cluster by default

To also delete the kind cluster:

```powershell
.\scripts\local-kind-cleanup.ps1 -DeleteCluster
```

The cluster deletion flag is intentionally explicit to avoid accidentally destroying the local Kubernetes environment.
