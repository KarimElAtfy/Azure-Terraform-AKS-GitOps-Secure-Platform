$ErrorActionPreference = "Stop"

Write-Host "=== GIT STATUS ===" -ForegroundColor Cyan
git status --short
git log --oneline -6

Write-Host ""
Write-Host "=== PROJECT FILES ===" -ForegroundColor Cyan

$RequiredFiles = @(
    ".\app\main.py",
    ".\app\tests\test_main.py",
    ".\app\Dockerfile",
    ".\charts\devsecops-api\Chart.yaml",
    ".\charts\devsecops-api\values.yaml",
    ".\charts\devsecops-api\values-dev.yaml",
    ".\charts\devsecops-api\templates\deployment.yaml",
    ".\charts\devsecops-api\templates\service.yaml",
    ".\charts\devsecops-api\templates\secretproviderclass.yaml",
    ".\scripts\local-kind-load-image.ps1",
    ".\scripts\local-kind-deploy.ps1",
    ".\scripts\local-kind-test.ps1",
    ".\scripts\local-kind-cleanup.ps1",
    ".\docs\local-kubernetes-lab.md"
)

foreach ($File in $RequiredFiles) {
    if (Test-Path $File) {
        Write-Host "[OK] $File" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $File" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== PYTHON TESTS ===" -ForegroundColor Cyan
python -m pytest

Write-Host ""
Write-Host "=== DOCKER BUILD ===" -ForegroundColor Cyan
docker build -t devsecops-api:local .\app

Write-Host ""
Write-Host "=== KUBERNETES CONTEXT ===" -ForegroundColor Cyan
kind get clusters
kubectl config current-context
kubectl get nodes -o wide

Write-Host ""
Write-Host "=== HELM LINT ===" -ForegroundColor Cyan
helm lint .\charts\devsecops-api
helm lint .\charts\devsecops-api -f .\charts\devsecops-api\values-dev.yaml

Write-Host ""
Write-Host "=== HELM TEMPLATE DEFAULT DEV ===" -ForegroundColor Cyan
$DefaultTemplate = helm template devsecops-api .\charts\devsecops-api -f .\charts\devsecops-api\values-dev.yaml
$DefaultTemplate | Select-String "kind: ServiceAccount|kind: ConfigMap|kind: Service|kind: Deployment"

Write-Host ""
Write-Host "=== HELM TEMPLATE OPTIONAL HPA ===" -ForegroundColor Cyan
$HpaTemplate = helm template devsecops-api .\charts\devsecops-api --set autoscaling.enabled=true
$HpaTemplate | Select-String "kind: HorizontalPodAutoscaler"

Write-Host ""
Write-Host "=== HELM TEMPLATE OPTIONAL INGRESS ===" -ForegroundColor Cyan
$IngressTemplate = helm template devsecops-api .\charts\devsecops-api --set ingress.enabled=true
$IngressTemplate | Select-String "kind: Ingress"

Write-Host ""
Write-Host "=== HELM TEMPLATE OPTIONAL KEY VAULT CSI ===" -ForegroundColor Cyan
$KeyVaultTemplate = helm template devsecops-api .\charts\devsecops-api `
    --set keyVault.enabled=true `
    --set keyVault.clientId=dummy-client-id `
    --set keyVault.keyVaultName=dummy-keyvault `
    --set keyVault.tenantId=dummy-tenant-id

$KeyVaultTemplate | Select-String "kind: SecretProviderClass|secretProviderClass"

Write-Host ""
Write-Host "=== LOAD IMAGE INTO KIND ===" -ForegroundColor Cyan
.\scripts\local-kind-load-image.ps1

Write-Host ""
Write-Host "=== DEPLOY WITH HELM ===" -ForegroundColor Cyan
.\scripts\local-kind-deploy.ps1

Write-Host ""
Write-Host "=== ENDPOINT TESTS ===" -ForegroundColor Cyan
.\scripts\local-kind-test.ps1

Write-Host ""
Write-Host "=== FINAL KUBERNETES STATE ===" -ForegroundColor Cyan
helm list -n devsecops-api
kubectl get all -n devsecops-api
kubectl get pods -n devsecops-api -o wide

Write-Host ""
Write-Host "=== FINAL GIT STATUS ===" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "Full local validation completed successfully." -ForegroundColor Green
