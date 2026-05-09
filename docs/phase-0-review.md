# Phase 0 Quality Notes

This file records the Phase 0 guardrails fixed before implementation begins.

## Corrections Applied

- Replaced hardcoded globally unique Azure resource names with suffix-based naming guidance.
- Removed `.terraform.lock.hcl` from `.gitignore` so Terraform provider locks can be committed later.
- Standardized backend configuration around committed `backend.tf` backend blocks, ignored real `backend.hcl` files, and committed `backend.hcl.example` templates.
- Clarified that `Standard_B2s` is only a target candidate after quota/SKU checks.
- Clarified that in-repo Helm charts should use Flux `GitRepository` + `HelmRelease`, not `HelmRepository`.
- Added GitHub Actions loop-protection guidance for automated GitOps tag commits.
- Clarified the Terraform/Flux ownership boundary and identity role-assignment placement.
- Replaced hardcoded cost claims with cost-driver guidance.

## Next Phase

Proceed with Phase 1: FastAPI application, Dockerfile, tests and local validation only. Do not deploy Azure infrastructure yet.
