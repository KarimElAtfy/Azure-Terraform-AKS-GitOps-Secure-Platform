# Incident 001: Single-node AKS rollout blocked by RollingUpdate surge

## Summary

During the GitOps image tag automation test, Flux successfully reconciled the updated HelmRelease, but the application rollout did not complete.

The new pod stayed in Pending because the AKS cluster was running on a single small node and the Deployment used the default RollingUpdate strategy.

Kubernetes tried to keep the old pod running while creating the new one, but the node did not have enough allocatable CPU for both pods at the same time.

## Impact

- Flux detected the Git change correctly.
- The HelmRelease attempted an upgrade.
- The new ReplicaSet was created.
- The new pod could not be scheduled.
- Helm timed out and rolled back.
- The old pod kept serving traffic.

The application remained available, but the GitOps rollout did not converge to the desired image tag.

## Symptoms

Relevant symptoms observed during troubleshooting:

~~~text
HelmRelease Ready=False
Helm rollback to previous release succeeded
kubectl rollout status waiting for old replicas to terminate
new pod Pending
0/1 nodes are available: 1 Insufficient cpu
~~~

The Deployment showed:

~~~text
StrategyType: RollingUpdate
Replicas: 1 desired | 2 total | 1 available | 1 unavailable
~~~

## Root Cause

The cluster was intentionally cost-conscious and used a single small AKS node.

With the default Kubernetes RollingUpdate strategy, a one-replica Deployment may temporarily require two pods during an upgrade:

~~~text
old pod stays running
new pod is created
new pod must become Ready
old pod is terminated
~~~

On this dev cluster, there was not enough CPU capacity to schedule the new pod while the old pod was still running.

## Fix

The Helm chart was updated to support configurable deployment strategies.

Default chart behavior remains RollingUpdate:

~~~yaml
deploymentStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
~~~

The AKS dev values use Recreate:

~~~yaml
deploymentStrategy:
  type: Recreate
~~~

For a single-node dev cluster, Recreate is acceptable because it avoids the temporary two-pod surge:

~~~text
old pod is terminated
new pod is created
new pod starts with the updated image
~~~

The chart version was bumped from 0.1.0 to 0.1.1 so Flux and Helm would fetch and apply the updated chart artifact.

## Validation

After cleanup and reconciliation:

~~~text
HelmRelease Ready=True
Chart revision: devsecops-api-0.1.1
Deployment strategy: Recreate
Pod status: Running 1/1
Image: acraksgitopssecurequqnak.azurecr.io/devsecops-api:<git-sha>
~~~

Application smoke tests confirmed:

~~~text
/version reports the deployed git SHA
/config reports the AKS GitOps environment
/secret-status reports the Key Vault-mounted secret as loaded
~~~

## Lessons Learned

- GitOps reconciliation can be correct while Kubernetes scheduling still blocks rollout.
- Small single-node clusters need rollout strategy decisions that match their capacity.
- Helm chart version bumps matter when changing chart behavior.
- Debugging should move layer by layer: GitHub Actions, ACR, Flux, Helm, Deployment, ReplicaSet, Pod events.

## Prevention

- Validate rendered AKS Helm manifests in CI.
- Keep deploymentStrategy: Recreate for single-node dev AKS.
- Use immutable image tags instead of latest.
- Check pod events when Flux reports Helm rollback or timeout.
