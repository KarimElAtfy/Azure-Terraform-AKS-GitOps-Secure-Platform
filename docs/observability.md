# Observability

> Living notes. Local logs and test-error checks work now; Azure Monitor notes will be added after the AKS deployment.

## What We Monitor (v1)

Observability is intentionally lightweight for v1:

- **Pod logs** via `kubectl logs`
- **Cluster events** via `kubectl get events`
- **Container Insights** via Log Analytics (AKS integration)
- **Application diagnostics** via the `/error-test` endpoint
- **Azure Monitor** basics for resource-level metrics

Prometheus and Grafana are not included in v1 to keep costs down.

## How to View Pod Logs

```bash
kubectl logs -n devsecops-api deployment/devsecops-api
kubectl logs -n devsecops-api deployment/devsecops-api --previous  # crashed pod
```

## How to Check Events

```bash
kubectl get events -n devsecops-api --sort-by='.lastTimestamp'
```

## How to Trigger a Test Error

```bash
curl http://localhost:8000/error-test
```

Then check logs:
```bash
kubectl logs -n devsecops-api deployment/devsecops-api --tail=20
```

## What Signals Matter

_Planned: define the small set of signals to check after every deploy: pod readiness, restart count, recent warning events, app logs and smoke-test result._
