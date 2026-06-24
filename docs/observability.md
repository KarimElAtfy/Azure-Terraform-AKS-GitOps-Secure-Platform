# Observability

This document describes the lightweight observability model used by the AKS GitOps Secure Platform.

The project intentionally keeps observability simple in v1 to avoid unnecessary cost and complexity.

## Observability Goals

The goal is to answer these questions quickly:

- is Flux syncing the repository?
- did Helm apply the desired release?
- is the pod running and ready?
- which image tag is deployed?
- is the app exposing the expected configuration?
- is the Key Vault secret mounted?
- are there recent Kubernetes warnings?
- did the application log expected requests/errors?

## Signals Used in v1

The project uses these signals:

- Flux source status
- Flux Kustomization status
- Flux HelmRelease status
- Helm release status
- Kubernetes pod status
- Kubernetes events
- application logs
- FastAPI diagnostic endpoints
- Log Analytics / Azure Monitor basics

Prometheus and Grafana are not included in v1.

## Flux Health

Check all Flux-managed resources:

~~~powershell
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
~~~

Expected result:

~~~text
READY=True
~~~

Force reconciliation:

~~~powershell
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system
flux reconcile helmrelease devsecops-api -n devsecops-api --with-source
~~~

## Helm Health

Check the Helm release managed by Flux:

~~~powershell
helm list -n devsecops-api
helm history devsecops-api -n devsecops-api
helm get values devsecops-api -n devsecops-api -o yaml
~~~

Expected release state:

~~~text
STATUS = deployed
CHART = devsecops-api-0.1.1
~~~

## Kubernetes Workload Health

Check pods:

~~~powershell
kubectl get pods -n devsecops-api -o wide
~~~

Expected result:

~~~text
READY = 1/1
STATUS = Running
RESTARTS = 0
~~~

Check rollout:

~~~powershell
kubectl rollout status deployment/devsecops-api -n devsecops-api
~~~

Check deployed image:

~~~powershell
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
~~~

Check deployment strategy:

~~~powershell
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.strategy.type}{'\n'}"
~~~

Expected result for the single-node AKS dev cluster:

~~~text
Recreate
~~~

## Kubernetes Events

Events are important when a rollout fails even though Flux and Helm are configured correctly.

~~~powershell
kubectl get events -n devsecops-api --sort-by=.lastTimestamp
~~~

Useful symptoms to look for:

- FailedScheduling
- Insufficient cpu
- FailedMount
- ImagePullBackOff
- ErrImagePull
- readiness probe failures
- liveness probe failures

## Application Logs

Check current logs:

~~~powershell
kubectl logs deployment/devsecops-api -n devsecops-api
~~~

Check previous container logs after a restart:

~~~powershell
kubectl logs deployment/devsecops-api -n devsecops-api --previous
~~~

Tail recent logs:

~~~powershell
kubectl logs deployment/devsecops-api -n devsecops-api --tail=50
~~~

## Application Diagnostic Endpoints

The FastAPI app exposes diagnostic endpoints useful for validation.

Start port-forward:

~~~powershell
kubectl port-forward -n devsecops-api svc/devsecops-api 8080:8000
~~~

In another terminal:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/health
Invoke-RestMethod http://127.0.0.1:8080/ready
Invoke-RestMethod http://127.0.0.1:8080/version
Invoke-RestMethod http://127.0.0.1:8080/config
Invoke-RestMethod http://127.0.0.1:8080/secret-status
Invoke-RestMethod http://127.0.0.1:8080/pod-info
~~~

Expected checks:

- `/health` returns healthy
- `/ready` returns ready
- `/version` returns app version, git SHA and environment
- `/config` returns app config values injected by Helm
- `/secret-status` returns secret loaded status without exposing the secret value
- `/pod-info` returns Kubernetes Downward API metadata

## Intentional Error Endpoint

The app includes:

~~~text
/error-test
~~~

This endpoint intentionally returns an HTTP 500 response.

It exists only to test logging and troubleshooting.

Example:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/error-test
~~~

Then check logs:

~~~powershell
kubectl logs deployment/devsecops-api -n devsecops-api --tail=20
~~~

## Azure Monitor and Log Analytics

The AKS cluster is connected to Log Analytics for basic Azure-side observability.

In v1, this is used only at a basic level to demonstrate that the cluster is integrated with Azure monitoring.

The primary day-to-day debugging path remains:

~~~text
flux CLI
helm CLI
kubectl
application endpoints
~~~

## Post-Deploy Validation Checklist

After a deployment, check:

~~~powershell
flux get helmreleases -A
kubectl get pods -n devsecops-api -o wide
kubectl rollout status deployment/devsecops-api -n devsecops-api
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
kubectl get networkpolicy -n devsecops-api
~~~

Then run endpoint smoke tests:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/version
Invoke-RestMethod http://127.0.0.1:8080/config
Invoke-RestMethod http://127.0.0.1:8080/secret-status
~~~

## Limitations

Observability is intentionally basic in v1.

Not included:

- Prometheus
- Grafana
- distributed tracing
- OpenTelemetry
- alert routing
- SLO dashboards
- synthetic monitoring

These are listed as future improvements because the current project scope is focused on AKS, Terraform, Helm, Flux, Workload Identity and secure GitOps deployment.
