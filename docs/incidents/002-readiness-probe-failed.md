# Incident 002: Readiness Probe Failed

> Draft runbook. Local probe checks are already covered; AKS-specific notes can be added after the cloud deploy.

## Symptoms

- Pod is Running but not Ready (`0/1 Ready`).
- Service has no endpoints.
- `kubectl describe pod` shows readiness probe failures.
- Traffic doesn't reach the app.

## Investigation Commands

```bash
kubectl get pods -n devsecops-api
kubectl describe pod <pod-name> -n devsecops-api
kubectl logs <pod-name> -n devsecops-api
kubectl get endpoints devsecops-api -n devsecops-api
```

## Possible Root Causes

1. **Wrong probe path**: Helm values specify `/ready` but the app uses `/readyz`.
2. **Wrong probe port**: probe targets port 80 but the app listens on 8000.
3. **App crash loop**: the app starts but fails during initialization.
4. **Slow startup**: the app takes longer than `initialDelaySeconds` to become ready.
5. **Missing dependency**: the app's readiness check depends on something unavailable.

## Fix

_Planned: add the exact fix from the first real readiness failure._

## Prevention

- Test probes locally with `curl http://localhost:8000/ready` before deploying.
- Match probe configuration in Helm values to actual app endpoints.
- Set reasonable `initialDelaySeconds` and `periodSeconds`.
