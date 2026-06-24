# Security Model

This document describes the security model used by the Azure Terraform AKS GitOps Secure Platform.

The project is designed as a dev/portfolio platform, not as a production-ready enterprise platform. The goal is to demonstrate realistic security patterns while keeping cost and complexity under control.

## Security Goals

The main security goals are:

- avoid static Azure credentials in GitHub
- avoid committing secrets to Git
- avoid storing application secrets in Kubernetes manifests
- use Azure Key Vault for secret storage
- use AKS Workload Identity for pod-to-Azure authentication
- keep Terraform and Flux responsibilities separated
- validate infrastructure and Kubernetes configuration through CI security scans

## Identity Flows

The project uses four main identity paths.

~~~text
GitHub Actions
    → Azure via OIDC federated credential

AKS kubelet identity
    → ACR via AcrPull role assignment

Application pod ServiceAccount
    → Azure Managed Identity through Workload Identity
    → Key Vault Secrets User role
    → Key Vault secret mounted through CSI driver

Local Terraform operator
    → Azure through local Azure CLI login
~~~

## GitHub Actions to Azure

GitHub Actions authenticates to Azure through OIDC federation.

This avoids storing a long-lived Azure client secret in GitHub.

The workflow uses repository variables such as:

~~~text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
ACR_NAME
ACR_LOGIN_SERVER
~~~

These values identify Azure resources but are not equivalent to a client secret.

The image build workflow uses this identity to:

- log in to Azure
- log in to Azure Container Registry
- push the Docker image
- update GitOps metadata in Git

## AKS to ACR

AKS pulls images from Azure Container Registry through the cluster kubelet identity.

Terraform assigns the required AcrPull permission on the ACR scope.

The application image is referenced in the HelmRelease as:

~~~text
<acr-login-server>/devsecops-api:<git-sha>
~~~

The project intentionally avoids using only `latest` for the GitOps deployment target. The deployed image tag is tracked in Git.

## Pod to Key Vault

The application pod accesses Key Vault through AKS Workload Identity and the Secrets Store CSI Driver.

The flow is:

~~~text
Pod
  → Kubernetes ServiceAccount
  → federated identity credential
  → Azure Managed Identity
  → Key Vault Secrets User role
  → Key Vault secret mounted as a file
~~~

The application validates secret availability through:

~~~text
/secret-status
~~~

This endpoint only reports whether a secret is loaded and where it was loaded from. It never returns the secret value.

Expected result:

~~~text
loaded = True
source = mounted_file
path = /mnt/secrets-store/app-demo-secret
~~~

## Secret Handling Rules

Rules used in this project:

- do not commit secrets
- do not commit real terraform.tfvars files
- do not commit backend.hcl files
- do not commit Terraform state files
- do not print secret values in Terraform outputs
- do not expose secret values through application endpoints
- do not store Azure client secrets in GitHub Actions
- use Key Vault for demo application secrets

## Terraform and Flux Boundary

Terraform owns Azure infrastructure.

Flux and Helm own Kubernetes workload resources.

Terraform manages:

- resource groups
- virtual network and subnet
- Azure Container Registry
- Key Vault
- Log Analytics
- AKS cluster
- managed identities
- role assignments
- federated identity credentials

Flux and Helm manage:

- Kubernetes namespace
- ServiceAccount
- ConfigMap
- Deployment
- Service
- SecretProviderClass
- NetworkPolicy

The project avoids using Terraform to manage Kubernetes workloads because that would create ownership conflicts with Flux.

## NetworkPolicy

The project includes a basic NetworkPolicy for the application namespace.

Current policy:

~~~text
devsecops-api-allow-same-namespace
~~~

The policy allows inbound traffic to the application pod on TCP port 8000 from pods in the same namespace.

This is intentionally simple for v1. It demonstrates Kubernetes NetworkPolicy without adding ingress controllers, service mesh, private endpoints, Azure Firewall, or NAT Gateway.

## Container Security

The Helm chart configures the application container with a securityContext appropriate for a dev portfolio workload.

Security goals include:

- avoid privileged containers
- avoid privilege escalation
- run with a non-root user where supported
- keep resource requests and limits defined
- expose only the application port

Some hardening options may be limited by the application image or by dev-environment tradeoffs. When a stricter setting is not enabled, it should be documented rather than silently claimed.

## CI Security Scanning

The repository includes security scanning workflows.

Current scanning layers:

- Checkov for Infrastructure as Code and Kubernetes-related configuration
- Trivy for repository vulnerability, secret, and misconfiguration scanning
- Helm lint and Helm template validation
- dedicated AKS GitOps Helm rendering validation

At this stage, security scanners may be configured in observation mode to collect findings without blocking development. Findings should be reviewed, false positives documented, and real issues fixed before making scans blocking.

## Validation Commands

Check Flux and Helm status:

~~~powershell
flux get sources git -A
flux get kustomizations -A
flux get helmreleases -A
helm list -n devsecops-api
~~~

Check application pod and image:

~~~powershell
kubectl get pods -n devsecops-api -o wide
kubectl get deploy devsecops-api -n devsecops-api -o jsonpath="{.spec.template.spec.containers[0].image}{'\n'}"
~~~

Check NetworkPolicy:

~~~powershell
kubectl get networkpolicy -n devsecops-api
kubectl describe networkpolicy devsecops-api-allow-same-namespace -n devsecops-api
~~~

Check Key Vault CSI resources:

~~~powershell
kubectl get secretproviderclass -n devsecops-api
kubectl describe secretproviderclass devsecops-api-keyvault -n devsecops-api
~~~

Check secret status through the app:

~~~powershell
Invoke-RestMethod http://127.0.0.1:8080/secret-status
~~~

## Known Limitations

This is a dev/portfolio environment.

Known limitations:

- single-node AKS cluster
- public AKS API server
- no private cluster
- no private endpoints
- no Azure Firewall
- no NAT Gateway
- no service mesh
- no OPA Gatekeeper or Kyverno in v1
- no managed Prometheus/Grafana in v1
- NetworkPolicy is basic, not a full zero-trust model
- validation is primarily through port-forward instead of public ingress

These limitations are intentional for cost and scope control.
