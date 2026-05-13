param(
    [string]$Namespace = "devsecops-api",
    [string]$ServiceName = "devsecops-api",
    [int]$LocalPort = 8000,
    [int]$ServicePort = 8000
)

$ErrorActionPreference = "Stop"

$BaseUrl = "http://127.0.0.1:$LocalPort"

Write-Host "Starting port-forward for service/$ServiceName..." -ForegroundColor Cyan

$PortForward = Start-Process `
    -FilePath "kubectl" `
    -ArgumentList @(
        "port-forward",
        "service/$ServiceName",
        "${LocalPort}:${ServicePort}",
        "-n",
        $Namespace
    ) `
    -NoNewWindow `
    -PassThru

Start-Sleep -Seconds 3

try {
    Write-Host ""
    Write-Host "Testing endpoints..." -ForegroundColor Cyan

    $Endpoints = @(
        "/health",
        "/ready",
        "/version",
        "/config",
        "/secret-status",
        "/pod-info"
    )

    foreach ($Endpoint in $Endpoints) {
        $Url = "$BaseUrl$Endpoint"
        Write-Host "GET $Url" -ForegroundColor Yellow
        curl.exe -s $Url
        Write-Host ""
    }

    Write-Host "GET $BaseUrl/error-test" -ForegroundColor Yellow
    curl.exe -s $BaseUrl/error-test
    Write-Host ""
    Write-Host "The /error-test endpoint is expected to return an intentional error payload." -ForegroundColor DarkYellow

    Write-Host ""
    Write-Host "Recent application logs:" -ForegroundColor Cyan
    kubectl logs deployment/$ServiceName -n $Namespace --tail=30

    Write-Host ""
    Write-Host "Local Kubernetes endpoint validation completed." -ForegroundColor Green
}
finally {
    if ($PortForward -and -not $PortForward.HasExited) {
        Write-Host ""
        Write-Host "Stopping port-forward process..." -ForegroundColor Cyan
        Stop-Process -Id $PortForward.Id -Force
    }
}
