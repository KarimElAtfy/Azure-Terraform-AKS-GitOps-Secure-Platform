# Security Model

> To be completed progressively through Phases 5, 7, and 8.

## Identity Model Overview

This project uses four identity mechanisms, none of which rely on static secrets:

1. **GitHub Actions → Azure:** OIDC federated credentials
2. **AKS → ACR:** Kubelet managed identity with AcrPull role
3. **App Pod → Key Vault:** Workload Identity with a Kubernetes ServiceAccount federated to a user-assigned Managed Identity
4. **Terraform → Azure:** Azure CLI session (local development)

## GitHub OIDC

_To be completed in Phase 5._

## AKS Identity

_To be completed in Phase 4._

## Key Vault Access

_To be completed in Phase 7._

Implementation target:

- Key Vault uses RBAC authorization.
- A user-assigned Managed Identity receives the least-privilege Key Vault role needed to read the demo secret.
- The AKS OIDC issuer is used to create a federated identity credential.
- The Kubernetes ServiceAccount name and namespace must exactly match the federated credential subject.
- The app proves access through `/secret-status` without exposing the secret value.


## Secret Handling Rules

- Secrets are never printed in application logs.
- Secrets are never included in Terraform outputs.
- Secrets are never committed to Git.
- The `/secret-status` endpoint reports whether a secret is loaded, never its value.
- Key Vault uses RBAC authorization (not access policies).

## Network Boundaries

_To be completed in Phase 8._

## Limitations (v1)

- AKS API server is public.
- No private endpoints.
- No Azure Firewall.
- No pod security standards enforcement (beyond securityContext).
- NetworkPolicy is basic (not default-deny in v1).
