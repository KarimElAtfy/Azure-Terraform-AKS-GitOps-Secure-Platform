param(
    [string]$ReleaseName = "devsecops-api",
    [string]$Namespace = "devsecops-api",
    [string]$ClusterName = "aks-gitops-local",
    [switch]$DeleteCluster
)

$ErrorActionPreference = "Stop"

Write-Host "Starting local cleanup..." -ForegroundColor Cyan
Write-Host "Release: $ReleaseName" -ForegroundColor Cyan
Write-Host "Namespace: $Namespace" -ForegroundColor Cyan
Write-Host "Cluster: $ClusterName" -ForegroundColor Cyan

Write-Host ""
Write-Host "Checking Helm release..." -ForegroundColor Cyan

$ReleaseExists = helm list -n $Namespace -q | Where-Object { $_ -eq $ReleaseName }

if ($ReleaseExists) {
    Write-Host "Uninstalling Helm release: $ReleaseName" -ForegroundColor Yellow
    helm uninstall $ReleaseName -n $Namespace
}
else {
    Write-Host "Helm release '$ReleaseName' not found. Skipping uninstall." -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Checking namespace..." -ForegroundColor Cyan

$NamespaceExists = kubectl get namespace $Namespace --ignore-not-found -o name

if ($NamespaceExists) {
    Write-Host "Deleting namespace: $Namespace" -ForegroundColor Yellow
    kubectl delete namespace $Namespace
}
else {
    Write-Host "Namespace '$Namespace' not found. Skipping namespace deletion." -ForegroundColor DarkYellow
}

if ($DeleteCluster) {
    Write-Host ""
    Write-Host "DeleteCluster flag detected." -ForegroundColor Yellow

    $Clusters = kind get clusters

    if ($Clusters -contains $ClusterName) {
        Write-Host "Deleting kind cluster: $ClusterName" -ForegroundColor Red
        kind delete cluster --name $ClusterName
    }
    else {
        Write-Host "kind cluster '$ClusterName' not found. Skipping cluster deletion." -ForegroundColor DarkYellow
    }
}
else {
    Write-Host ""
    Write-Host "Kind cluster was NOT deleted." -ForegroundColor Green
    Write-Host "To delete it too, run:" -ForegroundColor Yellow
    Write-Host ".\scripts\local-kind-cleanup.ps1 -DeleteCluster" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Local cleanup completed." -ForegroundColor Green
