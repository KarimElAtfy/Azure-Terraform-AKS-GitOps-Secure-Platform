# GitOps Flow

> To be completed in Phase 6 when Flux is bootstrapped.

## What is GitOps?

GitOps is an operational model where the desired state of your infrastructure and applications is stored in Git. A GitOps agent (Flux, in our case) watches the repository and continuously reconciles the live cluster state to match what Git declares.

The key principle: **if it's not in Git, it shouldn't be in the cluster.**

## How It Works in This Project

```
Developer pushes code
    → GitHub Actions builds image, pushes to ACR with git SHA tag
    → GitHub Actions updates image tag in clusters/dev/apps/helmrelease.yaml
    → GitHub Actions commits and pushes the change with loop protection
    → Flux detects the new commit
    → Flux renders the Helm chart with the updated tag
    → Flux applies the rendered manifests to AKS
    → Kubernetes rolls out the new deployment
    → New pod pulls the updated image from ACR
```

## What Flux Watches

Flux watches the `clusters/dev/` path in this repository. For v1, because the Helm chart lives in this same repository, the Flux source model should be:

- `GitRepository` pointing to this repo.
- `HelmRelease` referencing the chart path `./charts/devsecops-api`.

Do not use `HelmRepository` unless the chart is later published to a separate Helm/OCI registry.

## CI Loop Protection

If GitHub Actions commits an updated image tag back into `clusters/dev/`, protect the workflow from retriggering itself by using one or more of:

- `paths-ignore` for `clusters/dev/**` in image-build workflows.
- `[skip ci]` in automated tag-update commit messages.
- Separate workflows for app builds and GitOps metadata updates.


## How to Debug Flux

_To be completed._
