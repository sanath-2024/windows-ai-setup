$ErrorActionPreference = "Stop"

docker build -t pi-sbx:local (Join-Path $PSScriptRoot "..")

if ($LASTEXITCODE -ne 0) {
    throw "Docker image build failed."
}

Write-Host "Built pi-sbx:local"
