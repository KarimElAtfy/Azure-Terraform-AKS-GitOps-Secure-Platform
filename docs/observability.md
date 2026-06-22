# Observability

> To be completed in Phase 9.

## What We Monitor (v1)

This project uses lightweight observability appropriate for a dev environment:

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

_To be completed._
