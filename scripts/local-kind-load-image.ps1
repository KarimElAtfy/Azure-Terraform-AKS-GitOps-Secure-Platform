param(
    [string]$ImageName = "devsecops-api",
    [string]$ImageTag = "local",
    [string]$ClusterName = "aks-gitops-local"
)

$ErrorActionPreference = "Stop"

$FullImageName = "${ImageName}:${ImageTag}"

Write-Host "Building Docker image: $FullImageName" -ForegroundColor Cyan
docker build -t $FullImageName .\app

Write-Host "Checking kind cluster: $ClusterName" -ForegroundColor Cyan
$Clusters = kind get clusters

if ($Clusters -notcontains $ClusterName) {
    Write-Host "kind cluster '$ClusterName' not found." -ForegroundColor Red
    Write-Host "Create it first with:" -ForegroundColor Yellow
    Write-Host "kind create cluster --name $ClusterName" -ForegroundColor Yellow
    exit 1
}

Write-Host "Loading image into kind cluster: $ClusterName" -ForegroundColor Cyan
kind load docker-image $FullImageName --name $ClusterName

Write-Host "Image loaded successfully: $FullImageName" -ForegroundColor Green