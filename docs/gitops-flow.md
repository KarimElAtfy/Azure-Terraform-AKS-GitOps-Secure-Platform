# GitOps Flow

This project uses Flux to deploy the application to AKS from Git.

Terraform manages the Azure infrastructure layer. Flux and Helm manage the Kubernetes workload layer.

## High-Level Flow

~~~text
developer changes code
        ↓
push / merge to main
        ↓
GitHub Actions builds container image
        ↓
image is pushed to Azure Container Registry
        ↓
GitHub Actions updates image tag in clusters/dev/apps/helmrelease.yaml
        ↓
GitHub Actions commits the GitOps metadata update with [skip ci]
        ↓
Flux detects the new Git revision
        ↓
Flux reconciles the HelmRelease
        ↓
Helm renders charts/devsecops-api
        ↓
AKS runs the updated pod
~~~

## Source of Truth

The source of truth for the app running in AKS is:

~~~text
clusters/dev/apps/helmrelease.yaml
~~~

The source of truth for the chart is:

~~~text
charts/devsecops-api/
~~~

The live cluster should converge toward these files.

## Flux Components

Flux runs in the `flux-system` namespace.

Main controllers used by this project:

- source-controller
- kustomize-controller
- helm-controller
- notification-controller

Check controller health:

~~~powershell
kubectl get pods -n flux-system
~~~

## Git Source

Flux watches this repository through a GitRepository resource generated during bootstrap.

Check source status:

~~~powershell
flux get sources git -A
~~~

Expected result:

~~~text
READY=True
stored artifact for revision main@sha1:<commit>
~~~

## Kustomization

Flux reconciles the `clusters/dev/` path through a Kustomization.

Check status:

~~~powershell
flux get kustomizations -A
~~~

Expected result:

~~~text
READY=True
Applied revision: main@sha1:<commit>
~~~

## HelmRelease

The application is deployed by a Flux HelmRelease.

Check status:

~~~powershell
flux get helmreleases -A
~~~

Expected result:

~~~text
devsecops-api   0.1.1   False   True   Helm upgrade succeeded
~~~

## Image Automation Model

This project uses GitHub Actions, not Flux Image Automation, for image tag updates in v1.

The image build workflow:

1. Builds the Docker image.
2. Pushes it to ACR with:
   - short Git SHA tag
   - latest tag
3. Updates `clusters/dev/apps/helmrelease.yaml`.
4. Commits the updated tag with `[skip ci]`.

This keeps the GitOps flow explicit and easy to inspect.

## Loop Protection

The build workflow avoids infinite loops by limiting triggers and using `[skip ci]` in automated GitOps tag update commits.

The important idea is:

~~~text
app code changes can trigger image builds
GitOps metadata-only commits should not trigger endless rebuilds
~~~

## Single-Node AKS Rollout Note

The dev AKS cluster is intentionally cost-conscious and runs on a single small node.

For this reason, the AKS GitOps values use:

~~~yaml
deploymentStrategy:
  type: Recreate
~~~

This avoids failed rollouts caused by RollingUpdate temporarily requiring both the old and new pod to fit on the same small node.

The incident is documented in:

~~~text
docs/incidents/001-rollingupdate-insufficient-cpu.md
~~~

## Useful Reconcile Commands

~~~powershell
flux reconcile source git flux-system -n flux-system
flux reconcile kustomization flux-system -n flux-system
flux reconcile helmrelease devsecops-api -n devsecops-api --with-source
~~~

## Runtime Validation

~~~powershell
kubectl get pods -n devsecops-api -o wide
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.strategy.type}{'\n'}"
kubectl get networkpolicy -n devsecops-api
~~~

Application smoke test through port-forward:

~~~powershell
kubectl port-forward -n devsecops-api svc/devsecops-api 8080:8000
~~~

In another terminal:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/version
Invoke-RestMethod http://127.0.0.1:8080/config
Invoke-RestMethod http://127.0.0.1:8080/secret-status
~~~
