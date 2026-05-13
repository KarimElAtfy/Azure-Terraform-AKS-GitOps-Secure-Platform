param(
    [string]$ReleaseName = "devsecops-api",
    [string]$Namespace = "devsecops-api",
    [string]$ChartPath = ".\charts\devsecops-api",
    [string]$ValuesFile = ".\charts\devsecops-api\values-dev.yaml"
)

$ErrorActionPreference = "Stop"

Write-Host "Deploying Helm release: $ReleaseName" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan
Write-Host "Chart path: $ChartPath" -ForegroundColor Cyan
Write-Host "Values file: $ValuesFile" -ForegroundColor Cyan

helm upgrade --install $ReleaseName $ChartPath `
    -f $ValuesFile `
    -n $Namespace `
    --create-namespace

Write-Host ""
Write-Host "Helm release status:" -ForegroundColor Cyan
helm list -n $Namespace

Write-Host ""
Write-Host "Kubernetes resources:" -ForegroundColor Cyan
kubectl get all -n $Namespace

Write-Host ""
Write-Host "Pods:" -ForegroundColor Cyan
kubectl get pods -n $Namespace -o wide

Write-Host ""
Write-Host "Deployment completed." -ForegroundColor Green
